SET DEFINE OFF
/* ============================================================================
   HR Module - Stored Procedures
   Platform : Oracle Database (PL/SQL)
   Reference: SAP ECC 6.0 EHP8 - emulates HR_INFOTYPE_OPERATION style logic

   Key SAP behaviour reproduced:
     - Personnel numbers drawn from a number range (like RP_PERNR).
     - Infotype "delimiting": inserting a new time slice closes the previous
       open-ended record on the day before the new BEGDA (no overlaps), the
       classic SAP time-constraint 1 behaviour.

   Note: the C# backend performs these operations through EF Core; these
   procedures reproduce the same logic in the database for SAP fidelity and for
   use from SQL*Plus / SQLcl.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   usp_GetNextNumber - atomically draw the next number for a range object.
   Participates in the caller's transaction (the caller commits).
   ---------------------------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE HR.usp_GetNextNumber (
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
END;
/

/* ----------------------------------------------------------------------------
   usp_HireEmployee - creates a new employee (SAP action "Hiring", MASSN 01)
   and the mandatory infotypes 0000/0001/0002. Returns the new PERNR.
   ---------------------------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE HR.usp_HireEmployee (
    p_HireDate         IN  DATE,
    p_LastName         IN  NVARCHAR2,
    p_FirstName        IN  NVARCHAR2,
    p_Gender           IN  CHAR      DEFAULT NULL,
    p_BirthDate        IN  DATE      DEFAULT NULL,
    p_CompanyCode      IN  VARCHAR2  DEFAULT '1000',
    p_PersonnelArea    IN  VARCHAR2  DEFAULT '1000',
    p_EmployeeGroup    IN  VARCHAR2  DEFAULT '1',
    p_EmployeeSubgroup IN  VARCHAR2  DEFAULT 'DU',
    p_OrgUnit          IN  NUMBER    DEFAULT NULL,
    p_Position         IN  NUMBER    DEFAULT NULL,
    p_ChangedBy        IN  VARCHAR2  DEFAULT 'SYSTEM',
    p_NewPernr         OUT NUMBER
) AS
    v_n NUMBER;
BEGIN
    HR.usp_GetNextNumber('PERNR', v_n);
    p_NewPernr := v_n;

    INSERT INTO HR.EmployeeMaster (PERNR, HireDate, IsActive)
    VALUES (p_NewPernr, p_HireDate, 1);

    INSERT INTO HR.PA0000 (PERNR, BEGDA, ENDDA, MASSN, MASSG, STAT2, AEDTM, UNAME)
    VALUES (p_NewPernr, p_HireDate, DATE '9999-12-31', '01', '01', '3', TRUNC(SYSDATE), p_ChangedBy);

    INSERT INTO HR.PA0001 (PERNR, BEGDA, ENDDA, BUKRS, WERKS, PERSG, PERSK, ORGEH, PLANS, AEDTM, UNAME)
    VALUES (p_NewPernr, p_HireDate, DATE '9999-12-31', p_CompanyCode, p_PersonnelArea,
            p_EmployeeGroup, p_EmployeeSubgroup, p_OrgUnit, p_Position,
            TRUNC(SYSDATE), p_ChangedBy);

    INSERT INTO HR.PA0002 (PERNR, BEGDA, ENDDA, NACHN, VORNA, GBDAT, GESCH, AEDTM, UNAME)
    VALUES (p_NewPernr, p_HireDate, DATE '9999-12-31', p_LastName, p_FirstName, p_BirthDate, p_Gender,
            TRUNC(SYSDATE), p_ChangedBy);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

/* ----------------------------------------------------------------------------
   usp_DelimitPA0001 - time-constraint 1 update of Organizational Assignment.
   Closes the current open record at @NewBegin-1 and inserts a new slice.
   Demonstrates the SAP infotype "copy/delimit" pattern for one infotype.
   ---------------------------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE HR.usp_DelimitPA0001 (
    p_Pernr      IN NUMBER,
    p_NewBegin   IN DATE,
    p_OrgUnit    IN NUMBER   DEFAULT NULL,
    p_Position   IN NUMBER   DEFAULT NULL,
    p_CostCenter IN VARCHAR2 DEFAULT NULL,
    p_ChangedBy  IN VARCHAR2 DEFAULT 'SYSTEM'
) AS
    v_Bukrs    VARCHAR2(4);
    v_Werks    VARCHAR2(4);
    v_Persg    VARCHAR2(1);
    v_Persk    VARCHAR2(2);
    v_OldOrg   NUMBER;
    v_OldPlans NUMBER;
    v_OldKostl VARCHAR2(10);
BEGIN
    /* carry forward unspecified fields from the currently valid record */
    BEGIN
        SELECT BUKRS, WERKS, PERSG, PERSK, ORGEH, PLANS, KOSTL
          INTO v_Bukrs, v_Werks, v_Persg, v_Persk, v_OldOrg, v_OldPlans, v_OldKostl
          FROM (SELECT BUKRS, WERKS, PERSG, PERSK, ORGEH, PLANS, KOSTL
                  FROM HR.PA0001
                 WHERE PERNR = p_Pernr AND p_NewBegin BETWEEN BEGDA AND ENDDA
                 ORDER BY BEGDA DESC)
         WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;   -- no current record; carry-forward stays NULL
    END;

    /* delimit the record that is open on/after the new begin date */
    UPDATE HR.PA0001
       SET ENDDA = p_NewBegin - 1,
           AEDTM = TRUNC(SYSDATE), UNAME = p_ChangedBy
     WHERE PERNR = p_Pernr AND ENDDA >= p_NewBegin AND BEGDA < p_NewBegin;

    INSERT INTO HR.PA0001 (PERNR, BEGDA, ENDDA, BUKRS, WERKS, PERSG, PERSK, ORGEH, PLANS, KOSTL, AEDTM, UNAME)
    VALUES (p_Pernr, p_NewBegin, DATE '9999-12-31', v_Bukrs, v_Werks, v_Persg, v_Persk,
            NVL(p_OrgUnit, v_OldOrg), NVL(p_Position, v_OldPlans),
            NVL(p_CostCenter, v_OldKostl), TRUNC(SYSDATE), p_ChangedBy);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

/* ----------------------------------------------------------------------------
   usp_GetOrgStructure - returns the org units below a root org unit by walking
   HRP1001 A/002 relationships (org unit reports to org unit). Emulates SAP
   evaluation path O-O-S. Results are returned through a REF CURSOR.

   Example (SQL*Plus):
     VAR rc REFCURSOR
     EXEC HR.usp_GetOrgStructure(50000001, NULL, :rc)
     PRINT rc
   ---------------------------------------------------------------------------- */
CREATE OR REPLACE PROCEDURE HR.usp_GetOrgStructure (
    p_RootOrgId IN  NUMBER,
    p_KeyDate   IN  DATE DEFAULT NULL,
    p_Result    OUT SYS_REFCURSOR
) AS
    v_KeyDate DATE := NVL(p_KeyDate, TRUNC(SYSDATE));
BEGIN
    OPEN p_Result FOR
        WITH OrgTree (OBJID, STEXT, SHORT, Depth, ParentOrgId) AS (
            SELECT o.OBJID, o.STEXT, o.SHORT, 0 AS Depth,
                   CAST(NULL AS NUMBER) AS ParentOrgId
            FROM HR.HRP1000 o
            WHERE o.OTYPE = 'O' AND o.OBJID = p_RootOrgId AND o.PLVAR = '01'
              AND v_KeyDate BETWEEN o.BEGDA AND o.ENDDA
            UNION ALL
            SELECT c.OBJID, c.STEXT, c.SHORT, p.Depth + 1, p.OBJID
            FROM OrgTree p
            JOIN HR.HRP1001 r ON r.SCLAS = 'O' AND r.SOBID = TO_CHAR(p.OBJID)
                 AND r.OTYPE = 'O' AND r.RSIGN = 'A' AND r.RELAT = '002' AND r.PLVAR = '01'
                 AND v_KeyDate BETWEEN r.BEGDA AND r.ENDDA
            JOIN HR.HRP1000 c ON c.OTYPE = 'O' AND c.OBJID = r.OBJID AND c.PLVAR = '01'
                 AND v_KeyDate BETWEEN c.BEGDA AND c.ENDDA
        )
        SELECT OBJID AS OrgUnitId, STEXT AS OrgUnitName, SHORT AS ShortText,
               Depth, ParentOrgId
        FROM OrgTree
        ORDER BY Depth, OrgUnitId;
END;
/
