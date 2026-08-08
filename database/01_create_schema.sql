/* ============================================================================
   HR Module - Schema Creation Script
   Platform : Microsoft SQL Server (2019 / 2022)
   Reference: SAP ECC 6.0 EHP8 - Human Capital Management (HCM)

   This module reproduces the core HCM data model. Tables follow SAP naming
   conventions (PAnnnn = Personnel Administration infotypes, HRPnnnn =
   Organizational Management, Tnnn = Customizing / control tables).

   In SQL Server the SAP HR application area is modelled as a schema called
   [HR] inside a database called [HRModule]. This first script creates the
   database and the schema; every other object is created as HR.<name>.

   Run with sqlcmd (or SSMS) from a login with rights to CREATE DATABASE,
   e.g.:  sqlcmd -S localhost -U sa -P <pwd> -i database/run_all.sql

   Run order (see run_all.sql):
     01_create_schema.sql          <- this file
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

   All scripts are idempotent (re-runnable).
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Database. Idempotent: only created when it does not yet exist.
   ---------------------------------------------------------------------------- */
IF DB_ID('HRModule') IS NULL
    CREATE DATABASE HRModule;
GO

USE HRModule;
GO

/* ----------------------------------------------------------------------------
   HR schema. Idempotent.
   ---------------------------------------------------------------------------- */
IF SCHEMA_ID('HR') IS NULL
    EXEC('CREATE SCHEMA HR');
GO

/* ----------------------------------------------------------------------------
   Optional: a dedicated login/user for the application instead of 'sa'.
   Uncomment and adjust the password for anything but a throwaway dev box, and
   point ConnectionStrings:HRModule in appsettings.json at it.

   IF SUSER_ID('hr_app') IS NULL
       CREATE LOGIN hr_app WITH PASSWORD = 'HrModule#2024', DEFAULT_DATABASE = HRModule;
   IF USER_ID('hr_app') IS NULL
       CREATE USER hr_app FOR LOGIN hr_app;
   ALTER ROLE db_datareader ADD MEMBER hr_app;
   ALTER ROLE db_datawriter ADD MEMBER hr_app;
   GRANT EXECUTE ON SCHEMA::HR TO hr_app;
   ---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
   Number range table - emulates SAP number range object RP_PERNR (personnel
   numbers) and the OM object id ranges. In SAP these are maintained via SNRO.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.NumberRange','U') IS NULL
CREATE TABLE HR.NumberRange
(
    RangeObject   NVARCHAR(20) NOT NULL,   -- e.g. PERNR, OBJID
    FromNumber    BIGINT       NOT NULL,
    ToNumber      BIGINT       NOT NULL,
    CurrentNumber BIGINT       NOT NULL,
    CreatedOn     DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    CreatedBy NVARCHAR(12) NULL,                                -- audit: created by
    ChangedOn     DATETIME2(0) NULL,                                 -- audit: last updated date/time
    ChangedBy NVARCHAR(12) NULL,                                -- audit: last changed by
    CONSTRAINT PK_NumberRange PRIMARY KEY (RangeObject)
);
GO
