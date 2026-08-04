SET DEFINE OFF
/* ============================================================================
   HR Module - Seed data for extended infotypes
   Platform : Oracle Database
   Adds customizing (domain values, contract types, attendance types) and demo
   records for employees 1000 (Andreas Schmidt) and 1001 (Linda Nguyen).
   Idempotent.
   ============================================================================ */

/* --- Domain fixed values for the new infotypes --------------------------- */
MERGE INTO HR.DomainValue t
USING (
    /* Family / related person type (IT0021 SUBTY) */
    SELECT 'FAMSA' Domain, '1'  ValueKey, 'Spouse'              ValueTxt FROM DUAL UNION ALL
    SELECT 'FAMSA',        '2',           'Child'                        FROM DUAL UNION ALL
    SELECT 'FAMSA',        '6',           'Emergency contact'            FROM DUAL UNION ALL
    SELECT 'FAMSA',        '11',          'Father'                       FROM DUAL UNION ALL
    SELECT 'FAMSA',        '12',          'Mother'                       FROM DUAL UNION ALL
    /* Education establishment type (IT0022 SUBTY) */
    SELECT 'SLART',        '10',          'University'                   FROM DUAL UNION ALL
    SELECT 'SLART',        '20',          'Secondary school'             FROM DUAL UNION ALL
    SELECT 'SLART',        '30',          'Vocational training'          FROM DUAL UNION ALL
    SELECT 'SLART',        '40',          'Doctorate'                    FROM DUAL UNION ALL
    /* Task type for monitoring of dates (IT0019 SUBTY) */
    SELECT 'TMART',        '01',          'Expiry of probation'          FROM DUAL UNION ALL
    SELECT 'TMART',        '02',          'Work permit expiry'           FROM DUAL UNION ALL
    SELECT 'TMART',        '03',          'Contract end'                 FROM DUAL UNION ALL
    SELECT 'TMART',        '04',          'Next appraisal'               FROM DUAL UNION ALL
    /* Qualification group (IT0024 SUBTY) */
    SELECT 'QUALG',        '01',          'Technical'                    FROM DUAL UNION ALL
    SELECT 'QUALG',        '02',          'Language'                     FROM DUAL UNION ALL
    SELECT 'QUALG',        '03',          'Leadership'                   FROM DUAL UNION ALL
    /* Address type (IT0006 SUBTY, ANSSA) */
    SELECT 'ANSSA',        '1',           'Permanent residence'          FROM DUAL UNION ALL
    SELECT 'ANSSA',        '2',           'Temporary residence'          FROM DUAL UNION ALL
    SELECT 'ANSSA',        '3',           'Home address'                 FROM DUAL UNION ALL
    SELECT 'ANSSA',        '4',           'Mailing address'              FROM DUAL UNION ALL
    SELECT 'ANSSA',        '5',           'Emergency address'            FROM DUAL
) s ON (t.Domain = s.Domain AND t.ValueKey = s.ValueKey)
WHEN NOT MATCHED THEN INSERT (Domain, ValueKey, ValueTxt) VALUES (s.Domain, s.ValueKey, s.ValueTxt);

/* --- Contract types (T547T) ---------------------------------------------- */
MERGE INTO HR.T547T t
USING (
    SELECT '01' CTTYP, 'Permanent'  CTTXT FROM DUAL UNION ALL
    SELECT '02',       'Fixed-term'        FROM DUAL UNION ALL
    SELECT '03',       'Temporary'         FROM DUAL UNION ALL
    SELECT '04',       'Internship'        FROM DUAL
) s ON (t.CTTYP = s.CTTYP)
WHEN NOT MATCHED THEN INSERT (CTTYP, CTTXT) VALUES (s.CTTYP, s.CTTXT);

/* --- Additional attendance types (reuse T554S, KENNZ='P') ---------------- */
MERGE INTO HR.T554S t
USING (
    SELECT '01' MOABW, '0500' AWART, 'Training'   ATEXT, 'P' KENNZ FROM DUAL UNION ALL
    SELECT '01',       '0600',       'Conference',       'P'       FROM DUAL
) s ON (t.MOABW = s.MOABW AND t.AWART = s.AWART)
WHEN NOT MATCHED THEN INSERT (MOABW, AWART, ATEXT, KENNZ) VALUES (s.MOABW, s.AWART, s.ATEXT, s.KENNZ);

COMMIT;

/* --- Demo records (only if not already present) -------------------------- */
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM HR.PA0021 WHERE PERNR IN (1000, 1001);
    IF v_count = 0 THEN
        /* IT0016 Contract Elements */
        INSERT INTO HR.PA0016 (PERNR, BEGDA, ENDDA, CTTYP, PRBEZ, KDGFB, KDGF2, AEDTM, UNAME)
        VALUES (1000, DATE '2020-03-01', DATE '9999-12-31', '01', 6.0, 3.0, 3.0, DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0016 (PERNR, BEGDA, ENDDA, CTTYP, PRBEZ, KDGFB, KDGF2, AEDTM, UNAME)
        VALUES (1001, DATE '2021-06-15', DATE '9999-12-31', '02', 3.0, 1.0, 1.0, DATE '2021-06-15', 'ADMIN');

        /* IT0019 Monitoring of Dates */
        INSERT INTO HR.PA0019 (PERNR, SUBTY, BEGDA, ENDDA, TERMN, MNDAT, AEDTM, UNAME)
        VALUES (1001, '01', DATE '2021-06-15', DATE '9999-12-31', DATE '2021-09-15', DATE '2021-09-01', DATE '2021-06-15', 'ADMIN');
        INSERT INTO HR.PA0019 (PERNR, SUBTY, BEGDA, ENDDA, TERMN, MNDAT, AEDTM, UNAME)
        VALUES (1001, '04', DATE '2021-06-15', DATE '9999-12-31', DATE '2026-06-15', DATE '2026-06-01', DATE '2021-06-15', 'ADMIN');
        INSERT INTO HR.PA0019 (PERNR, SUBTY, BEGDA, ENDDA, TERMN, MNDAT, AEDTM, UNAME)
        VALUES (1000, '04', DATE '2020-03-01', DATE '9999-12-31', DATE '2026-03-01', DATE '2026-02-15', DATE '2020-03-01', 'ADMIN');

        /* IT0021 Family Members */
        INSERT INTO HR.PA0021 (PERNR, SUBTY, OBJPS, BEGDA, ENDDA, FANAM, FAVOR, FGBDT, FASEX, FGBLD, AEDTM, UNAME)
        VALUES (1000, '1', '01', DATE '2010-06-20', DATE '9999-12-31', 'Schmidt', 'Julia', DATE '1984-02-18', '2', 'DE', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0021 (PERNR, SUBTY, OBJPS, BEGDA, ENDDA, FANAM, FAVOR, FGBDT, FASEX, FGBLD, AEDTM, UNAME)
        VALUES (1000, '2', '01', DATE '2012-04-11', DATE '9999-12-31', 'Schmidt', 'Max', DATE '2012-04-11', '1', 'DE', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0021 (PERNR, SUBTY, OBJPS, BEGDA, ENDDA, FANAM, FAVOR, FGBDT, FASEX, FGBLD, AEDTM, UNAME)
        VALUES (1000, '2', '02', DATE '2015-09-30', DATE '9999-12-31', 'Schmidt', 'Emma', DATE '2015-09-30', '2', 'DE', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0021 (PERNR, SUBTY, OBJPS, BEGDA, ENDDA, FANAM, FAVOR, FGBDT, FASEX, FGBLD, AEDTM, UNAME)
        VALUES (1001, '6', '01', DATE '2021-06-15', DATE '9999-12-31', 'Nguyen', 'Peter', DATE '1988-01-05', '1', 'US', DATE '2021-06-15', 'ADMIN');

        /* IT0022 Education */
        INSERT INTO HR.PA0022 (PERNR, SUBTY, BEGDA, ENDDA, SLABS, INSTI, SLAND, SFACH, SLGRA, AEDTM, UNAME)
        VALUES (1000, '10', DATE '2001-10-01', DATE '2006-07-31', 'Diplom (Master)', 'TU Berlin', 'DE', 'Business Administration', '1.7', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0022 (PERNR, SUBTY, BEGDA, ENDDA, SLABS, INSTI, SLAND, SFACH, SLGRA, AEDTM, UNAME)
        VALUES (1001, '10', DATE '2009-09-01', DATE '2013-05-31', 'B.Sc.', 'NYU', 'US', 'Human Resources Mgmt', '3.8 GPA', DATE '2021-06-15', 'ADMIN');
        INSERT INTO HR.PA0022 (PERNR, SUBTY, BEGDA, ENDDA, SLABS, INSTI, SLAND, SFACH, SLGRA, AEDTM, UNAME)
        VALUES (1001, '40', DATE '2013-09-01', DATE '2017-06-30', 'Ph.D.', 'Columbia University', 'US', 'Organizational Psychology', NULL, DATE '2021-06-15', 'ADMIN');

        /* IT0023 Previous Employers (work experience) */
        INSERT INTO HR.PA0023 (PERNR, BEGDA, ENDDA, ARBGB, ORT01, LAND1, TASK, BRANC, AEDTM, UNAME)
        VALUES (1000, DATE '2006-08-01', DATE '2020-02-29', 'Muster GmbH', 'Munich', 'DE', 'HR Business Partner', 'Manufacturing', DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0023 (PERNR, BEGDA, ENDDA, ARBGB, ORT01, LAND1, TASK, BRANC, AEDTM, UNAME)
        VALUES (1001, DATE '2017-07-01', DATE '2021-05-31', 'Acme Corp', 'Boston', 'US', 'HR Analyst', 'Technology', DATE '2021-06-15', 'ADMIN');

        /* IT0024 Qualifications / Skills */
        INSERT INTO HR.PA0024 (PERNR, SUBTY, BEGDA, ENDDA, QUALI, AUSPR, AEDTM, UNAME)
        VALUES (1000, '03', DATE '2020-03-01', DATE '9999-12-31', 'People leadership', 8, DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0024 (PERNR, SUBTY, BEGDA, ENDDA, QUALI, AUSPR, AEDTM, UNAME)
        VALUES (1000, '02', DATE '2020-03-01', DATE '9999-12-31', 'English (fluent)', 7, DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0024 (PERNR, SUBTY, BEGDA, ENDDA, QUALI, AUSPR, AEDTM, UNAME)
        VALUES (1000, '01', DATE '2020-03-01', DATE '9999-12-31', 'SAP SuccessFactors', 6, DATE '2020-03-01', 'ADMIN');
        INSERT INTO HR.PA0024 (PERNR, SUBTY, BEGDA, ENDDA, QUALI, AUSPR, AEDTM, UNAME)
        VALUES (1001, '01', DATE '2021-06-15', DATE '9999-12-31', 'HR Analytics', 8, DATE '2021-06-15', 'ADMIN');
        INSERT INTO HR.PA0024 (PERNR, SUBTY, BEGDA, ENDDA, QUALI, AUSPR, AEDTM, UNAME)
        VALUES (1001, '02', DATE '2021-06-15', DATE '9999-12-31', 'Spanish (intermediate)', 5, DATE '2021-06-15', 'ADMIN');

        /* IT2002 Attendances */
        INSERT INTO HR.PA2002 (PERNR, SUBTY, BEGDA, ENDDA, AWART, ABWTG, STDAZ, AEDTM, UNAME)
        VALUES (1000, '0500', DATE '2026-05-04', DATE '2026-05-06', '0500', 3.00, 24.00, DATE '2026-04-20', 'ADMIN');
        INSERT INTO HR.PA2002 (PERNR, SUBTY, BEGDA, ENDDA, AWART, ABWTG, STDAZ, AEDTM, UNAME)
        VALUES (1001, '0400', DATE '2026-03-10', DATE '2026-03-12', '0400', 3.00, 24.00, DATE '2026-03-01', 'ADMIN');
        INSERT INTO HR.PA2002 (PERNR, SUBTY, BEGDA, ENDDA, AWART, ABWTG, STDAZ, AEDTM, UNAME)
        VALUES (1001, '1000', DATE '2026-04-15', DATE '2026-04-15', '1000', NULL, 3.50, DATE '2026-04-15', 'ADMIN');

        COMMIT;
    END IF;
END;
/
