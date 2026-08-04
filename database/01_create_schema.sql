SET DEFINE OFF
/* ============================================================================
   HR Module - Schema Creation Script
   Platform : Oracle Database (19c / 21c / 23ai)
   Reference: SAP ECC 6.0 EHP8 - Human Capital Management (HCM)

   This module reproduces the core HCM data model. Tables follow SAP naming
   conventions (PAnnnn = Personnel Administration infotypes, HRPnnnn =
   Organizational Management, Tnnn = Customizing / control tables).

   In Oracle a "schema" is owned by a database user, so the SAP HR application
   area is modelled as an Oracle user/schema called HR (the SQL Server version
   used a [HR] schema inside an HRModule database). Run this file as a DBA
   (SYS or SYSTEM) connected to the target pluggable database; the remaining
   scripts are run while connected as the HR user.

   Run order (see run_all.sql):
     01_create_schema.sql          <- this file  (run as DBA)
     02_schema_personnel_admin.sql
     03_schema_org_management.sql
     04_schema_time_management.sql
     05_customizing_tables.sql
     06_seed_reference_data.sql
     07_stored_procedures.sql
     08_views.sql
     09_schema_hr_extended.sql
     10_seed_hr_extended.sql
     11_schema_security.sql
     12_schema_modules.sql
     13_schema_payroll_time.sql
   ============================================================================ */

/* ----------------------------------------------------------------------------
   HR user / schema. Idempotent: only created when it does not yet exist.
   Adjust the tablespace and password to your site's standards.
   ---------------------------------------------------------------------------- */
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'HR';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER HR IDENTIFIED BY "HrModule#2024" '
                       || 'DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP '
                       || 'QUOTA UNLIMITED ON USERS';
        EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE PROCEDURE, '
                       || 'CREATE SEQUENCE, CREATE TABLE TO HR';
    END IF;
END;
/

/* ----------------------------------------------------------------------------
   Number range table - emulates SAP number range object RP_PERNR (personnel
   numbers) and the OM object id ranges. In SAP these are maintained via SNRO.

   From here on every object is created in the HR schema. When running the
   scripts while connected AS HR, the unqualified name resolves to HR.<name>;
   the explicit HR. qualifier is kept for clarity and so a DBA session can run
   the scripts too.
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE HR.NumberRange
        (
            RangeObject   VARCHAR2(20) NOT NULL,   -- e.g. PERNR, OBJID
            FromNumber    NUMBER(19)   NOT NULL,
            ToNumber      NUMBER(19)   NOT NULL,
            CurrentNumber NUMBER(19)   NOT NULL,
            CONSTRAINT PK_NumberRange PRIMARY KEY (RangeObject)
        )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;   -- ORA-00955: name already used
END;
/
