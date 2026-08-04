-- ============================================================================
--  HR Module (Oracle edition) - master installer
--
--  Run with SQL*Plus / SQLcl as a privileged user (creates the HR schema):
--      sqlplus system/<password>@<host>:1521/<service> @run_all.sql
--
--  SET DEFINE OFF disables '&' substitution so literals such as
--  'Data Privacy & GDPR' load verbatim.
-- ============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR CONTINUE

PROMPT == 01_schema.sql ==
@@01_schema.sql
PROMPT == 02_seed.sql ==
@@02_seed.sql
PROMPT == 03_views_procedures.sql ==
@@03_views_procedures.sql

PROMPT ============================================
PROMPT  HR Module (Oracle) install complete.
PROMPT  Schema: HR   Demo users: admin/admin123,
PROMPT  manager/manager123, linda/linda123
PROMPT ============================================
