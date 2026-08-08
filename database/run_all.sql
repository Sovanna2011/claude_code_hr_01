/* ============================================================================
   HR Module - Master install script (Microsoft SQL Server)

   Run with sqlcmd from the database/ directory, using a login that can
   CREATE DATABASE (e.g. sa):

       cd database
       sqlcmd -S localhost -U sa -P <pwd> -i run_all.sql

   01_create_schema.sql creates the HRModule database and the [HR] schema; the
   remaining scripts create objects as HR.<name> inside that database (each one
   begins with USE HRModule). All scripts are idempotent (re-runnable).

   Note: the :r includes below are resolved relative to the current working
   directory, so run sqlcmd from the database/ folder (or pass full paths).
   :on error exit stops the install on the first error.
   ============================================================================ */
:on error exit

PRINT '=== 01 create database / schema ===';
:r 01_create_schema.sql
PRINT '=== 02 personnel administration ===';
:r 02_schema_personnel_admin.sql
PRINT '=== 03 organizational management ===';
:r 03_schema_org_management.sql
PRINT '=== 04 time management ===';
:r 04_schema_time_management.sql
PRINT '=== 05 customizing tables ===';
:r 05_customizing_tables.sql
PRINT '=== 06 seed reference & demo data ===';
:r 06_seed_reference_data.sql
PRINT '=== 07 stored procedures ===';
:r 07_stored_procedures.sql
PRINT '=== 08 views ===';
:r 08_views.sql
PRINT '=== 09 extended infotypes ===';
:r 09_schema_hr_extended.sql
PRINT '=== 10 extended seed data ===';
:r 10_seed_hr_extended.sql
PRINT '=== 11 security (users & roles) ===';
:r 11_schema_security.sql
PRINT '=== 12 modules (leave / recruitment / training) ===';
:r 12_schema_modules.sql
PRINT '=== 13 payroll & overtime ===';
:r 13_schema_payroll_time.sql

PRINT 'HR Module database installation complete.';
GO
