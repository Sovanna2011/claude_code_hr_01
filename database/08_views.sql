SET DEFINE OFF
/* ============================================================================
   HR Module - Reporting Views
   Platform : Oracle Database
   Reference: SAP ECC 6.0 EHP8 - emulates common HR logical database / query
   views (PNP style master-data reporting).

   Oracle notes: OUTER APPLY + FETCH FIRST n ROWS ONLY (12c+) replace SQL
   Server's OUTER APPLY (SELECT TOP 1 ...); string concatenation uses || and
   the "record valid today" predicate uses TRUNC(SYSDATE).
   ============================================================================ */

/* ----------------------------------------------------------------------------
   vw_EmployeeCurrent - one row per employee with the record valid TODAY across
   the key infotypes. Mirrors a typical PA20/PA30 header display.
   ---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW HR.vw_EmployeeCurrent AS
    SELECT
        em.PERNR,
        p2.VORNA                              AS FirstName,
        p2.NACHN                              AS LastName,
        p2.VORNA || ' ' || p2.NACHN           AS FullName,
        p2.GBDAT                              AS BirthDate,
        p2.GESCH                              AS GenderKey,
        gsx.ValueTxt                          AS Gender,
        em.HireDate,
        st.ValueTxt                           AS EmploymentStatus,
        p1.BUKRS                              AS CompanyCode,
        t1.BUTXT                              AS CompanyName,
        p1.WERKS                              AS PersonnelArea,
        t5p.NAME1                             AS PersonnelAreaName,
        p1.ORGEH                              AS OrgUnitId,
        org.STEXT                             AS OrgUnitName,
        p1.PLANS                              AS PositionId,
        pos.STEXT                             AS PositionName,
        p1.KOSTL                              AS CostCenter,
        mail.USRID_LONG                       AS Email
    FROM HR.EmployeeMaster em
    OUTER APPLY (SELECT * FROM HR.PA0002 x
                 WHERE x.PERNR = em.PERNR AND TRUNC(SYSDATE) BETWEEN x.BEGDA AND x.ENDDA
                 ORDER BY x.BEGDA DESC FETCH FIRST 1 ROW ONLY) p2
    OUTER APPLY (SELECT * FROM HR.PA0001 x
                 WHERE x.PERNR = em.PERNR AND TRUNC(SYSDATE) BETWEEN x.BEGDA AND x.ENDDA
                 ORDER BY x.BEGDA DESC FETCH FIRST 1 ROW ONLY) p1
    OUTER APPLY (SELECT * FROM HR.PA0000 x
                 WHERE x.PERNR = em.PERNR AND TRUNC(SYSDATE) BETWEEN x.BEGDA AND x.ENDDA
                 ORDER BY x.BEGDA DESC FETCH FIRST 1 ROW ONLY) p0
    OUTER APPLY (SELECT * FROM HR.PA0105 x
                 WHERE x.PERNR = em.PERNR AND x.SUBTY = '0010'
                   AND TRUNC(SYSDATE) BETWEEN x.BEGDA AND x.ENDDA
                 ORDER BY x.BEGDA DESC FETCH FIRST 1 ROW ONLY) mail
    LEFT JOIN HR.T001  t1  ON t1.BUKRS = p1.BUKRS
    LEFT JOIN HR.T500P t5p ON t5p.WERKS = p1.WERKS
    LEFT JOIN HR.HRP1000 org ON org.OTYPE = 'O' AND org.OBJID = p1.ORGEH AND org.PLVAR = '01'
              AND TRUNC(SYSDATE) BETWEEN org.BEGDA AND org.ENDDA
    LEFT JOIN HR.HRP1000 pos ON pos.OTYPE = 'S' AND pos.OBJID = p1.PLANS AND pos.PLVAR = '01'
              AND TRUNC(SYSDATE) BETWEEN pos.BEGDA AND pos.ENDDA
    LEFT JOIN HR.DomainValue gsx ON gsx.Domain = 'GESCH' AND gsx.ValueKey = p2.GESCH
    LEFT JOIN HR.DomainValue st  ON st.Domain = 'STAT2'  AND st.ValueKey = p0.STAT2;

/* ----------------------------------------------------------------------------
   vw_LeaveBalance - remaining absence quota per employee & quota type.
   ---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW HR.vw_LeaveBalance AS
    SELECT q.PERNR, q.KTART AS QuotaType,
           tq.ATEXT AS QuotaText,
           q.BEGDA, q.ENDDA,
           q.ANZHL AS Entitlement,
           q.KVERB AS Deducted,
           (q.ANZHL - q.KVERB) AS Remaining
    FROM HR.PA2006 q
    LEFT JOIN HR.T554S tq ON tq.MOABW = '01' AND tq.AWART = q.KTART;
