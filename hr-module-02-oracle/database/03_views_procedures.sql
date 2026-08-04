-- ============================================================================
--  HR Module - Reporting views & stored procedures (Oracle edition)
--  The C# backend performs the infotype delimit/hire logic itself; these
--  objects mirror the SQL Server edition for parity and direct DB reporting.
-- ============================================================================
ALTER SESSION SET CURRENT_SCHEMA = HR;

-- ---- vw_EmployeeCurrent: one row per employee, records valid today ---------
CREATE OR REPLACE VIEW HR.vw_EmployeeCurrent AS
SELECT em.PERNR,
       p2.VORNA                      AS FirstName,
       p2.NACHN                      AS LastName,
       p2.VORNA || ' ' || p2.NACHN   AS FullName,
       p2.GBDAT                      AS BirthDate,
       p2.GESCH                      AS GenderKey,
       gsx.ValueTxt                  AS Gender,
       em.HireDate,
       st.ValueTxt                   AS EmploymentStatus,
       p1.BUKRS                      AS CompanyCode,
       t1.BUTXT                      AS CompanyName,
       p1.WERKS                      AS PersonnelArea,
       t5p.NAME1                     AS PersonnelAreaName,
       p1.ORGEH                      AS OrgUnitId,
       org.STEXT                     AS OrgUnitName,
       p1.PLANS                      AS PositionId,
       pos.STEXT                     AS PositionName,
       p1.KOSTL                      AS CostCenter,
       mail.USRID_LONG               AS Email
FROM HR.EmployeeMaster em
OUTER APPLY (SELECT * FROM HR.PA0002 x WHERE x.PERNR=em.PERNR
             AND TRUNC(SYSDATE) BETWEEN x.BEGDA AND x.ENDDA
             ORDER BY x.BEGDA DESC FETCH FIRST 1 ROWS ONLY) p2
OUTER APPLY (SELECT * FROM HR.PA0001 x WHERE x.PERNR=em.PERNR
             AND TRUNC(SYSDATE) BETWEEN x.BEGDA AND x.ENDDA
             ORDER BY x.BEGDA DESC FETCH FIRST 1 ROWS ONLY) p1
OUTER APPLY (SELECT * FROM HR.PA0000 x WHERE x.PERNR=em.PERNR
             AND TRUNC(SYSDATE) BETWEEN x.BEGDA AND x.ENDDA
             ORDER BY x.BEGDA DESC FETCH FIRST 1 ROWS ONLY) p0
OUTER APPLY (SELECT * FROM HR.PA0105 x WHERE x.PERNR=em.PERNR AND x.SUBTY='0010'
             AND TRUNC(SYSDATE) BETWEEN x.BEGDA AND x.ENDDA
             ORDER BY x.BEGDA DESC FETCH FIRST 1 ROWS ONLY) mail
LEFT JOIN HR.T001  t1  ON t1.BUKRS  = p1.BUKRS
LEFT JOIN HR.T500P t5p ON t5p.WERKS = p1.WERKS
LEFT JOIN HR.HRP1000 org ON org.OTYPE='O' AND org.OBJID=p1.ORGEH AND org.PLVAR='01'
          AND TRUNC(SYSDATE) BETWEEN org.BEGDA AND org.ENDDA
LEFT JOIN HR.HRP1000 pos ON pos.OTYPE='S' AND pos.OBJID=p1.PLANS AND pos.PLVAR='01'
          AND TRUNC(SYSDATE) BETWEEN pos.BEGDA AND pos.ENDDA
LEFT JOIN HR.DomainValue gsx ON gsx.Domain='GESCH' AND gsx.ValueKey=p2.GESCH
LEFT JOIN HR.DomainValue st  ON st.Domain='STAT2'  AND st.ValueKey=p0.STAT2;
/

-- ---- vw_LeaveBalance: remaining absence quota per employee & quota type -----
CREATE OR REPLACE VIEW HR.vw_LeaveBalance AS
SELECT q.PERNR, q.KTART AS QuotaType, tq.ATEXT AS QuotaText,
       q.BEGDA, q.ENDDA, q.ANZHL AS Entitlement, q.KVERB AS Deducted,
       (q.ANZHL - q.KVERB) AS Remaining
FROM HR.PA2006 q
LEFT JOIN HR.T554S tq ON tq.MOABW='01' AND tq.AWART=q.KTART;
/

-- ---- usp_GetNextNumber: atomically draw the next number for a range object -
CREATE OR REPLACE PROCEDURE HR.usp_GetNextNumber(
    p_RangeObject IN  VARCHAR2,
    p_NextNumber  OUT NUMBER
) AS
BEGIN
    UPDATE HR.NumberRange
       SET CurrentNumber = CurrentNumber + 1
     WHERE RangeObject = p_RangeObject
     RETURNING CurrentNumber INTO p_NextNumber;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Unknown number range object.');
    END IF;
    COMMIT;
END;
/

-- ---- usp_HireEmployee: SAP hiring action -> IT0000/0001/0002 ---------------
CREATE OR REPLACE PROCEDURE HR.usp_HireEmployee(
    p_HireDate         IN  DATE,
    p_LastName         IN  NVARCHAR2,
    p_FirstName        IN  NVARCHAR2,
    p_Gender           IN  CHAR     DEFAULT NULL,
    p_BirthDate        IN  DATE     DEFAULT NULL,
    p_CompanyCode      IN  VARCHAR2 DEFAULT '1000',
    p_PersonnelArea    IN  VARCHAR2 DEFAULT '1000',
    p_EmployeeGroup    IN  VARCHAR2 DEFAULT '1',
    p_EmployeeSubgroup IN  VARCHAR2 DEFAULT 'DU',
    p_OrgUnit          IN  NUMBER   DEFAULT NULL,
    p_Position         IN  NUMBER   DEFAULT NULL,
    p_ChangedBy        IN  VARCHAR2 DEFAULT 'SYSTEM',
    p_NewPernr         OUT NUMBER
) AS
    v_n NUMBER;
BEGIN
    HR.usp_GetNextNumber('PERNR', v_n);
    p_NewPernr := v_n;

    INSERT INTO HR.EmployeeMaster (PERNR, HireDate, IsActive)
    VALUES (p_NewPernr, p_HireDate, 1);

    INSERT INTO HR.PA0000 (PERNR,BEGDA,ENDDA,MASSN,MASSG,STAT2,AEDTM,UNAME)
    VALUES (p_NewPernr,p_HireDate,DATE '9999-12-31','01','01','3',TRUNC(SYSDATE),p_ChangedBy);

    INSERT INTO HR.PA0001 (PERNR,BEGDA,ENDDA,BUKRS,WERKS,PERSG,PERSK,ORGEH,PLANS,AEDTM,UNAME)
    VALUES (p_NewPernr,p_HireDate,DATE '9999-12-31',p_CompanyCode,p_PersonnelArea,
            p_EmployeeGroup,p_EmployeeSubgroup,p_OrgUnit,p_Position,TRUNC(SYSDATE),p_ChangedBy);

    INSERT INTO HR.PA0002 (PERNR,BEGDA,ENDDA,NACHN,VORNA,GBDAT,GESCH,AEDTM,UNAME)
    VALUES (p_NewPernr,p_HireDate,DATE '9999-12-31',p_LastName,p_FirstName,p_BirthDate,p_Gender,
            TRUNC(SYSDATE),p_ChangedBy);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/

-- ---- usp_DelimitPA0001: time-constraint 1 update of Org Assignment ---------
CREATE OR REPLACE PROCEDURE HR.usp_DelimitPA0001(
    p_Pernr      IN NUMBER,
    p_NewBegin   IN DATE,
    p_OrgUnit    IN NUMBER   DEFAULT NULL,
    p_Position   IN NUMBER   DEFAULT NULL,
    p_CostCenter IN VARCHAR2 DEFAULT NULL,
    p_ChangedBy  IN VARCHAR2 DEFAULT 'SYSTEM'
) AS
    v_Bukrs   VARCHAR2(4);  v_Werks VARCHAR2(4);
    v_Persg   VARCHAR2(1);  v_Persk VARCHAR2(2);
    v_OldOrg  NUMBER;       v_OldPlans NUMBER;  v_OldKostl VARCHAR2(10);
BEGIN
    BEGIN
        SELECT BUKRS,WERKS,PERSG,PERSK,ORGEH,PLANS,KOSTL
          INTO v_Bukrs,v_Werks,v_Persg,v_Persk,v_OldOrg,v_OldPlans,v_OldKostl
          FROM (SELECT * FROM HR.PA0001
                 WHERE PERNR=p_Pernr AND p_NewBegin BETWEEN BEGDA AND ENDDA
                 ORDER BY BEGDA DESC)
         WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;   -- no current record; carry NULLs
    END;

    UPDATE HR.PA0001
       SET ENDDA = p_NewBegin - 1, AEDTM = TRUNC(SYSDATE), UNAME = p_ChangedBy
     WHERE PERNR = p_Pernr AND ENDDA >= p_NewBegin AND BEGDA < p_NewBegin;

    INSERT INTO HR.PA0001 (PERNR,BEGDA,ENDDA,BUKRS,WERKS,PERSG,PERSK,ORGEH,PLANS,KOSTL,AEDTM,UNAME)
    VALUES (p_Pernr,p_NewBegin,DATE '9999-12-31',v_Bukrs,v_Werks,v_Persg,v_Persk,
            NVL(p_OrgUnit,v_OldOrg), NVL(p_Position,v_OldPlans),
            NVL(p_CostCenter,v_OldKostl), TRUNC(SYSDATE), p_ChangedBy);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/

-- ---- usp_GetOrgStructure: org units below a root (evaluation path O-O) ------
CREATE OR REPLACE PROCEDURE HR.usp_GetOrgStructure(
    p_RootOrgId IN  NUMBER,
    p_KeyDate   IN  DATE DEFAULT NULL,
    p_Result    OUT SYS_REFCURSOR
) AS
    v_Key DATE := NVL(p_KeyDate, TRUNC(SYSDATE));
BEGIN
    OPEN p_Result FOR
    WITH OrgTree(OBJID, STEXT, SHORT, Depth, ParentOrgId) AS (
        SELECT o.OBJID, o.STEXT, o.SHORT, 0, CAST(NULL AS NUMBER)
          FROM HR.HRP1000 o
         WHERE o.OTYPE='O' AND o.OBJID=p_RootOrgId AND o.PLVAR='01'
           AND v_Key BETWEEN o.BEGDA AND o.ENDDA
        UNION ALL
        SELECT c.OBJID, c.STEXT, c.SHORT, p.Depth+1, p.OBJID
          FROM OrgTree p
          JOIN HR.HRP1001 r ON r.SCLAS='O' AND r.SOBID=TO_CHAR(p.OBJID)
               AND r.OTYPE='O' AND r.RSIGN='A' AND r.RELAT='002' AND r.PLVAR='01'
               AND v_Key BETWEEN r.BEGDA AND r.ENDDA
          JOIN HR.HRP1000 c ON c.OTYPE='O' AND c.OBJID=r.OBJID AND c.PLVAR='01'
               AND v_Key BETWEEN c.BEGDA AND c.ENDDA
    )
    SELECT OBJID AS OrgUnitId, STEXT AS OrgUnitName, SHORT AS ShortText, Depth, ParentOrgId
      FROM OrgTree
     ORDER BY Depth, OrgUnitId;
END;
/

PROMPT Views and stored procedures created.
