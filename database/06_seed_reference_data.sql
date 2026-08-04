SET DEFINE OFF
/* ============================================================================
   HR Module - Seed Reference & Demo Data
   Platform : Oracle Database
   Reference: SAP ECC 6.0 EHP8 conventions

   Populates customizing tables, number ranges, a small organizational
   structure and two demo employees so the module is runnable end to end.
   Idempotent: uses MERGE / existence checks. (Oracle MERGE sources are built
   from SELECT ... FROM DUAL and multi-row inserts are issued row by row inside
   PL/SQL blocks, since Oracle has no multi-row VALUES clause.)
   ============================================================================ */

/* --- Number ranges -------------------------------------------------------- */
MERGE INTO HR.NumberRange t
USING (
    SELECT 'PERNR' RangeObject, 1        FromNumber, 99999999 ToNumber, 1000     CurrentNumber FROM DUAL UNION ALL
    SELECT 'OBJID',             50000000,           59999999,          50000000                FROM DUAL
) s ON (t.RangeObject = s.RangeObject)
WHEN NOT MATCHED THEN
    INSERT (RangeObject, FromNumber, ToNumber, CurrentNumber)
    VALUES (s.RangeObject, s.FromNumber, s.ToNumber, s.CurrentNumber);

/* --- Countries ------------------------------------------------------------ */
MERGE INTO HR.T005 t
USING (
    SELECT 'DE' LAND1, 'Germany'        LANDX, 'EUR' WAERS FROM DUAL UNION ALL
    SELECT 'US',       'United States',        'USD'       FROM DUAL UNION ALL
    SELECT 'FR',       'France',               'EUR'       FROM DUAL UNION ALL
    SELECT 'GB',       'United Kingdom',       'GBP'       FROM DUAL UNION ALL
    SELECT 'KH',       'Cambodia',             'KHR'       FROM DUAL UNION ALL
    SELECT 'SG',       'Singapore',            'SGD'       FROM DUAL
) s ON (t.LAND1 = s.LAND1)
WHEN NOT MATCHED THEN INSERT (LAND1, LANDX, WAERS) VALUES (s.LAND1, s.LANDX, s.WAERS);

/* --- Company code / personnel structure ----------------------------------- */
MERGE INTO HR.T001 t
USING (SELECT '1000' BUKRS, 'Global Corp AG' BUTXT, 'DE' LAND1, 'EUR' WAERS FROM DUAL) s
ON (t.BUKRS = s.BUKRS)
WHEN NOT MATCHED THEN INSERT (BUKRS, BUTXT, LAND1, WAERS) VALUES (s.BUKRS, s.BUTXT, s.LAND1, s.WAERS);

MERGE INTO HR.T500P t
USING (
    SELECT '1000' WERKS, 'Head Office'   NAME1, '1000' BUKRS, '01' MOLGA FROM DUAL UNION ALL
    SELECT '2000',       'Branch Office',        '1000',       '01'       FROM DUAL
) s ON (t.WERKS = s.WERKS)
WHEN NOT MATCHED THEN INSERT (WERKS, NAME1, BUKRS, MOLGA) VALUES (s.WERKS, s.NAME1, s.BUKRS, s.MOLGA);

MERGE INTO HR.T001P t
USING (
    SELECT '1000' WERKS, '0001' BTRTL, 'Administration' BTEXT FROM DUAL UNION ALL
    SELECT '1000',       '0002',       'Production'            FROM DUAL UNION ALL
    SELECT '2000',       '0001',       'Sales'                 FROM DUAL
) s ON (t.WERKS = s.WERKS AND t.BTRTL = s.BTRTL)
WHEN NOT MATCHED THEN INSERT (WERKS, BTRTL, BTEXT) VALUES (s.WERKS, s.BTRTL, s.BTEXT);

MERGE INTO HR.T501 t
USING (
    SELECT '1' PERSG, 'Active employees' PTEXT FROM DUAL UNION ALL
    SELECT '2',       'Pensioners'              FROM DUAL UNION ALL
    SELECT '9',       'External staff'          FROM DUAL
) s ON (t.PERSG = s.PERSG)
WHEN NOT MATCHED THEN INSERT (PERSG, PTEXT) VALUES (s.PERSG, s.PTEXT);

MERGE INTO HR.T503K t
USING (
    SELECT 'DU' PERSK, 'Salaried staff'     PTEXT FROM DUAL UNION ALL
    SELECT 'DW',       'Industrial workers'       FROM DUAL UNION ALL
    SELECT 'DT',       'Trainees'                 FROM DUAL
) s ON (t.PERSK = s.PERSK)
WHEN NOT MATCHED THEN INSERT (PERSK, PTEXT) VALUES (s.PERSK, s.PTEXT);

/* --- Action types & reasons ----------------------------------------------- */
MERGE INTO HR.T529A t
USING (
    SELECT '01' MASSN, 'Hiring'                       MNTXT FROM DUAL UNION ALL
    SELECT '02',       'Organizational reassignment'        FROM DUAL UNION ALL
    SELECT '03',       'Pay increase'                       FROM DUAL UNION ALL
    SELECT '10',       'Leaving'                            FROM DUAL UNION ALL
    SELECT '11',       'Retirement'                         FROM DUAL
) s ON (t.MASSN = s.MASSN)
WHEN NOT MATCHED THEN INSERT (MASSN, MNTXT) VALUES (s.MASSN, s.MNTXT);

MERGE INTO HR.T530 t
USING (
    SELECT '01' MASSN, '01' MASSG, 'New hire'     MGTXT FROM DUAL UNION ALL
    SELECT '10',       '01',       'Resignation'        FROM DUAL UNION ALL
    SELECT '10',       '02',       'Dismissal'          FROM DUAL UNION ALL
    SELECT '03',       '01',       'Annual review'      FROM DUAL
) s ON (t.MASSN = s.MASSN AND t.MASSG = s.MASSG)
WHEN NOT MATCHED THEN INSERT (MASSN, MASSG, MGTXT) VALUES (s.MASSN, s.MASSG, s.MGTXT);

/* --- Absence / attendance types ------------------------------------------- */
MERGE INTO HR.T554S t
USING (
    SELECT '01' MOABW, '0100' AWART, 'Annual leave' ATEXT, 'A' KENNZ FROM DUAL UNION ALL
    SELECT '01',       '0200',       'Sick leave',          'A'       FROM DUAL UNION ALL
    SELECT '01',       '0300',       'Unpaid leave',        'A'       FROM DUAL UNION ALL
    SELECT '01',       '1000',       'Overtime',            'P'       FROM DUAL UNION ALL
    SELECT '01',       '0400',       'Business trip',       'P'       FROM DUAL
) s ON (t.MOABW = s.MOABW AND t.AWART = s.AWART)
WHEN NOT MATCHED THEN INSERT (MOABW, AWART, ATEXT, KENNZ) VALUES (s.MOABW, s.AWART, s.ATEXT, s.KENNZ);

/* --- Wage type texts ------------------------------------------------------ */
MERGE INTO HR.T512T t
USING (
    SELECT '1000' LGART, 'Standard salary' LGTXT FROM DUAL UNION ALL
    SELECT '1010',       'Base pay'               FROM DUAL UNION ALL
    SELECT '2000',       'Overtime pay'           FROM DUAL UNION ALL
    SELECT '3000',       'Bonus'                  FROM DUAL UNION ALL
    SELECT '5000',       'Allowance'              FROM DUAL
) s ON (t.LGART = s.LGART)
WHEN NOT MATCHED THEN INSERT (LGART, LGTXT) VALUES (s.LGART, s.LGTXT);

/* --- Domain fixed values -------------------------------------------------- */
MERGE INTO HR.DomainValue t
USING (
    SELECT 'GESCH' Domain, '1'    ValueKey, 'Male'         ValueTxt FROM DUAL UNION ALL
    SELECT 'GESCH',        '2',             'Female'                FROM DUAL UNION ALL
    SELECT 'GESCH',        '3',             'Undefined'             FROM DUAL UNION ALL
    SELECT 'FAMST',        '0',             'Single'                FROM DUAL UNION ALL
    SELECT 'FAMST',        '1',             'Married'               FROM DUAL UNION ALL
    SELECT 'FAMST',        '2',             'Widowed'               FROM DUAL UNION ALL
    SELECT 'FAMST',        '3',             'Divorced'              FROM DUAL UNION ALL
    SELECT 'FAMST',        '4',             'Separated'             FROM DUAL UNION ALL
    SELECT 'ANRED',        '1',             'Mrs.'                  FROM DUAL UNION ALL
    SELECT 'ANRED',        '2',             'Mr.'                   FROM DUAL UNION ALL
    SELECT 'ANRED',        '3',             'Company'               FROM DUAL UNION ALL
    SELECT 'STAT2',        '0',             'Withdrawn'             FROM DUAL UNION ALL
    SELECT 'STAT2',        '1',             'Inactive'              FROM DUAL UNION ALL
    SELECT 'STAT2',        '2',             'Retiree'               FROM DUAL UNION ALL
    SELECT 'STAT2',        '3',             'Active'                FROM DUAL UNION ALL
    SELECT 'USRTY',        '0010',          'E-Mail'                FROM DUAL UNION ALL
    SELECT 'USRTY',        '0020',          'Telephone'             FROM DUAL UNION ALL
    SELECT 'USRTY',        'CELL',          'Mobile phone'          FROM DUAL UNION ALL
    SELECT 'USRTY',        'FAX',           'Fax'                   FROM DUAL UNION ALL
    SELECT 'USRTY',        'MAIL',          'System user'           FROM DUAL
) s ON (t.Domain = s.Domain AND t.ValueKey = s.ValueKey)
WHEN NOT MATCHED THEN INSERT (Domain, ValueKey, ValueTxt) VALUES (s.Domain, s.ValueKey, s.ValueTxt);

COMMIT;

/* ============================================================================
   Organizational structure (OM)
   Org units: 50000001 Executive Board -> 50000010 Human Resources,
                                          50000020 Finance
   Job:       50000900 HR Specialist
   Positions: 50000100 Head of HR (chief), 50000101 HR Specialist
   ============================================================================ */
MERGE INTO HR.HRP1000 t
USING (
    SELECT 'O' OTYPE, 50000001 OBJID, 'EXEC'    SHORT, 'Executive Board'          STEXT FROM DUAL UNION ALL
    SELECT 'O',       50000010,       'HR',             'Human Resources'               FROM DUAL UNION ALL
    SELECT 'O',       50000020,       'FIN',            'Finance'                       FROM DUAL UNION ALL
    SELECT 'C',       50000900,       'HRSPEC',         'HR Specialist (Job)'           FROM DUAL UNION ALL
    SELECT 'S',       50000100,       'HEADHR',         'Head of Human Resources'       FROM DUAL UNION ALL
    SELECT 'S',       50000101,       'HRSPEC1',        'HR Specialist'                 FROM DUAL
) s
ON (t.PLVAR = '01' AND t.OTYPE = s.OTYPE AND t.OBJID = s.OBJID AND t.ENDDA = DATE '9999-12-31')
WHEN NOT MATCHED THEN
    INSERT (OTYPE, OBJID, BEGDA, ENDDA, SHORT, STEXT)
    VALUES (s.OTYPE, s.OBJID, DATE '2020-01-01', DATE '9999-12-31', s.SHORT, s.STEXT);

/* Relationships:
   HR (O) belongs to Executive Board (A 002 org->org "reports to")
   Head of HR position belongs to HR org unit (A 003 S->O)
   HR org unit is managed by Head of HR (B 012 O->S)
   HR Specialist position belongs to HR (A 003), described by job (A 007),
   and reports to Head of HR (A 002 S->S). */
MERGE INTO HR.HRP1001 t
USING (
    SELECT 'O' OTYPE, 50000010 OBJID, 'A' RSIGN, '002' RELAT, 'O' SCLAS, '50000001' SOBID FROM DUAL UNION ALL
    SELECT 'O',       50000020,       'A',       '002',       'O',       '50000001'        FROM DUAL UNION ALL
    SELECT 'S',       50000100,       'A',       '003',       'O',       '50000010'        FROM DUAL UNION ALL
    SELECT 'O',       50000010,       'B',       '012',       'S',       '50000100'        FROM DUAL UNION ALL
    SELECT 'S',       50000101,       'A',       '003',       'O',       '50000010'        FROM DUAL UNION ALL
    SELECT 'S',       50000101,       'A',       '007',       'C',       '50000900'        FROM DUAL UNION ALL
    SELECT 'S',       50000101,       'A',       '002',       'S',       '50000100'        FROM DUAL
) s
ON (t.PLVAR = '01' AND t.OTYPE = s.OTYPE AND t.OBJID = s.OBJID
    AND t.RSIGN = s.RSIGN AND t.RELAT = s.RELAT AND t.SCLAS = s.SCLAS
    AND t.SOBID = s.SOBID AND t.ENDDA = DATE '9999-12-31')
WHEN NOT MATCHED THEN
    INSERT (OTYPE, OBJID, BEGDA, ENDDA, RSIGN, RELAT, SCLAS, SOBID)
    VALUES (s.OTYPE, s.OBJID, DATE '2020-01-01', DATE '9999-12-31',
            s.RSIGN, s.RELAT, s.SCLAS, s.SOBID);

MERGE INTO HR.T528T t
USING (
    SELECT 50000100 PLANS, 'Head of Human Resources' PLSTX FROM DUAL UNION ALL
    SELECT 50000101,       'HR Specialist'                 FROM DUAL
) s ON (t.PLANS = s.PLANS)
WHEN NOT MATCHED THEN INSERT (PLANS, PLSTX) VALUES (s.PLANS, s.PLSTX);

COMMIT;

/* ============================================================================
   Demo employees 1000 (Head of HR) and 1001 (HR Specialist)
   ============================================================================ */
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM HR.EmployeeMaster WHERE PERNR IN (1000, 1001);
    IF v_count = 0 THEN
        INSERT INTO HR.EmployeeMaster (PERNR, HireDate, IsActive) VALUES (1000, DATE '2020-03-01', 1);
        INSERT INTO HR.EmployeeMaster (PERNR, HireDate, IsActive) VALUES (1001, DATE '2021-06-15', 1);

        /* PA0000 Actions */
        INSERT INTO HR.PA0000 (PERNR, BEGDA, ENDDA, MASSN, MASSG, STAT2, AEDTM, UNAME)
        VALUES (1000, DATE '2020-03-01', DATE '9999-12-31', '01', '01', '3', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0000 (PERNR, BEGDA, ENDDA, MASSN, MASSG, STAT2, AEDTM, UNAME)
        VALUES (1001, DATE '2021-06-15', DATE '9999-12-31', '01', '01', '3', DATE '2021-06-15', 'ADMIN');

        /* PA0001 Organizational Assignment */
        INSERT INTO HR.PA0001 (PERNR, BEGDA, ENDDA, BUKRS, WERKS, BTRTL, PERSG, PERSK, ORGEH, PLANS, STELL, KOSTL, AEDTM, UNAME)
        VALUES (1000, DATE '2020-03-01', DATE '9999-12-31', '1000', '1000', '0001', '1', 'DU', 50000010, 50000100, 50000900, 'HR-1000', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0001 (PERNR, BEGDA, ENDDA, BUKRS, WERKS, BTRTL, PERSG, PERSK, ORGEH, PLANS, STELL, KOSTL, AEDTM, UNAME)
        VALUES (1001, DATE '2021-06-15', DATE '9999-12-31', '1000', '1000', '0001', '1', 'DU', 50000010, 50000101, 50000900, 'HR-1000', DATE '2021-06-15', 'ADMIN');

        /* PA0002 Personal Data */
        INSERT INTO HR.PA0002 (PERNR, BEGDA, ENDDA, ANRED, NACHN, VORNA, GBDAT, GESCH, NATIO, FAMST, SPRSL, AEDTM, UNAME)
        VALUES (1000, DATE '2020-03-01', DATE '9999-12-31', '2', 'Schmidt', 'Andreas', DATE '1982-07-12', '1', 'DE', '1', 'E', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0002 (PERNR, BEGDA, ENDDA, ANRED, NACHN, VORNA, GBDAT, GESCH, NATIO, FAMST, SPRSL, AEDTM, UNAME)
        VALUES (1001, DATE '2021-06-15', DATE '9999-12-31', '1', 'Nguyen', 'Linda', DATE '1990-11-03', '2', 'US', '0', 'E', DATE '2021-06-15', 'ADMIN');

        /* PA0006 Addresses */
        INSERT INTO HR.PA0006 (PERNR, SUBTY, BEGDA, ENDDA, STRAS, ORT01, PSTLZ, LAND1, AEDTM, UNAME)
        VALUES (1000, '1', DATE '2020-03-01', DATE '9999-12-31', 'Hauptstrasse 12', 'Berlin', '10115', 'DE', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0006 (PERNR, SUBTY, BEGDA, ENDDA, STRAS, ORT01, PSTLZ, LAND1, AEDTM, UNAME)
        VALUES (1001, '1', DATE '2021-06-15', DATE '9999-12-31', '5th Avenue 200', 'New York', '10001', 'US', DATE '2021-06-15', 'ADMIN');

        /* PA0007 Planned Working Time */
        INSERT INTO HR.PA0007 (PERNR, BEGDA, ENDDA, SCHKZ, EMPCT, WOSTD, AEDTM, UNAME)
        VALUES (1000, DATE '2020-03-01', DATE '9999-12-31', 'FLEX', 100.00, 40.00, DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0007 (PERNR, BEGDA, ENDDA, SCHKZ, EMPCT, WOSTD, AEDTM, UNAME)
        VALUES (1001, DATE '2021-06-15', DATE '9999-12-31', 'FLEX', 100.00, 40.00, DATE '2021-06-15', 'ADMIN');

        /* PA0008 Basic Pay + wage types */
        INSERT INTO HR.PA0008 (PERNR, BEGDA, ENDDA, TRFAR, TRFGB, TRFGR, BSGRD, WAERS, ANSAL, AEDTM, UNAME)
        VALUES (1000, DATE '2020-03-01', DATE '9999-12-31', '01', '01', 'E4', 100.00, 'EUR', 96000.00, DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0008 (PERNR, BEGDA, ENDDA, TRFAR, TRFGB, TRFGR, BSGRD, WAERS, ANSAL, AEDTM, UNAME)
        VALUES (1001, DATE '2021-06-15', DATE '9999-12-31', '01', '01', 'E2', 100.00, 'EUR', 60000.00, DATE '2021-06-15', 'ADMIN');

        INSERT INTO HR.PA0008_WageType (PERNR, ENDDA, SEQNR, LineNo, LGART, BETRG, WAERS)
        VALUES (1000, DATE '9999-12-31', 1, 1, '1010', 8000.00, 'EUR');
        INSERT INTO HR.PA0008_WageType (PERNR, ENDDA, SEQNR, LineNo, LGART, BETRG, WAERS)
        VALUES (1001, DATE '9999-12-31', 1, 1, '1010', 5000.00, 'EUR');

        /* PA0009 Bank Details */
        INSERT INTO HR.PA0009 (PERNR, SUBTY, BEGDA, ENDDA, BANKS, BANKL, BANKN, ZLSCH, WAERS, AEDTM, UNAME)
        VALUES (1000, '0', DATE '2020-03-01', DATE '9999-12-31', 'DE', '10070000', 'DE89370400440532013000', 'U', 'EUR', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0009 (PERNR, SUBTY, BEGDA, ENDDA, BANKS, BANKL, BANKN, ZLSCH, WAERS, AEDTM, UNAME)
        VALUES (1001, '0', DATE '2021-06-15', DATE '9999-12-31', 'US', '021000021', 'US64SVBKUS6S3300958879', 'U', 'EUR', DATE '2021-06-15', 'ADMIN');

        /* PA0105 Communication (email) */
        INSERT INTO HR.PA0105 (PERNR, SUBTY, BEGDA, ENDDA, USRID, USRID_LONG, AEDTM, UNAME)
        VALUES (1000, '0010', DATE '2020-03-01', DATE '9999-12-31', 'a.schmidt', 'a.schmidt@globalcorp.com', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0105 (PERNR, SUBTY, BEGDA, ENDDA, USRID, USRID_LONG, AEDTM, UNAME)
        VALUES (1001, '0010', DATE '2021-06-15', DATE '9999-12-31', 'l.nguyen', 'l.nguyen@globalcorp.com', DATE '2021-06-15', 'ADMIN');

        /* PA2006 Absence quota - 30 days annual leave 2026 */
        INSERT INTO HR.PA2006 (PERNR, SUBTY, BEGDA, ENDDA, KTART, ANZHL, KVERB, AEDTM, UNAME)
        VALUES (1000, '0100', DATE '2026-01-01', DATE '2026-12-31', '0100', 30.00, 5.00, DATE '2026-01-01', 'ADMIN');
        INSERT INTO HR.PA2006 (PERNR, SUBTY, BEGDA, ENDDA, KTART, ANZHL, KVERB, AEDTM, UNAME)
        VALUES (1001, '0100', DATE '2026-01-01', DATE '2026-12-31', '0100', 25.00, 0.00, DATE '2026-01-01', 'ADMIN');

        /* PA2001 Absence - annual leave */
        INSERT INTO HR.PA2001 (PERNR, SUBTY, BEGDA, ENDDA, AWART, ABWTG, APPROVED, AEDTM, UNAME)
        VALUES (1000, '0100', DATE '2026-07-01', DATE '2026-07-05', '0100', 5.00, 1, DATE '2026-06-01', 'ADMIN');

        COMMIT;
    END IF;
END;
/
