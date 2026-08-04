/* ============================================================================
   HR Module - Master install script (Oracle Database)

   Run with SQL*Plus or SQLcl from a privileged account (e.g. SYSTEM) connected
   to the target pluggable database:

       sqlplus system/<pwd>@//localhost:1521/XEPDB1 @database/run_all.sql
   or  sql     system/<pwd>@//localhost:1521/FREEPDB1 @database/run_all.sql

   01_create_schema.sql creates the HR user/schema (default password
   HrModule#2024 - change it for anything but a throwaway dev box). Every other
   object is created fully qualified as HR.<name>, so a DBA-level account can
   run the whole script in one pass. Alternatively run 01 as a DBA, then
   CONNECT HR/<pwd> and run 02..13. All scripts are idempotent (re-runnable).
   ============================================================================ */
SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

PROMPT === 01 create schema / user ===
@@01_create_schema.sql
PROMPT === 02 personnel administration ===
@@02_schema_personnel_admin.sql
PROMPT === 03 organizational management ===
@@03_schema_org_management.sql
PROMPT === 04 time management ===
@@04_schema_time_management.sql
PROMPT === 05 customizing tables ===
@@05_customizing_tables.sql
PROMPT === 06 seed reference & demo data ===
@@06_seed_reference_data.sql
PROMPT === 07 stored procedures ===
@@07_stored_procedures.sql
PROMPT === 08 views ===
@@08_views.sql
PROMPT === 09 extended infotypes ===
@@09_schema_hr_extended.sql
PROMPT === 10 extended seed data ===
@@10_seed_hr_extended.sql
PROMPT === 11 security (users & roles) ===
@@11_schema_security.sql
PROMPT === 12 modules (leave / recruitment / training) ===
@@12_schema_modules.sql
PROMPT === 13 payroll & overtime ===
@@13_schema_payroll_time.sql

PROMPT HR Module database installation complete.
