SET DEFINE OFF
/* ============================================================================
   HR Module - Personnel Administration (PA) Infotypes
   Platform : Oracle Database
   Reference: SAP ECC 6.0 EHP8 - Personnel Administration (PA-PA)

   Every infotype record is time-dependent and carries the standard SAP
   infotype key fields:
     PERNR  Personnel number
     SUBTY  Subtype
     OBJPS  Object identification
     SPRPS  Lock indicator ('X' = locked)
     BEGDA  Start date of validity  (SAP "Begin date")
     ENDDA  End   date of validity  (SAP "End date", 9999-12-31 = open ended)
     SEQNR  Sequence number (used when several records share a validity period)
     AEDTM  Last changed on
     UNAME  Changed by

   Oracle note: the empty string '' is treated as NULL in Oracle, so the
   SAP-initial value of the mandatory key fields SUBTY/OBJPS/SPRPS is a single
   space ' ' (which is also SAP's initial value for character fields). Each
   DDL statement is wrapped in a PL/SQL block that ignores ORA-00955
   ("name is already used by an existing object") so the script is re-runnable.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Master record - PA0003 is the SAP payroll status; here we keep a lightweight
   employee master anchor so PERNR referential integrity can be enforced.
   The real personal data lives in PA0002.
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.EmployeeMaster
        (
            PERNR       NUMBER(10)   NOT NULL,                    -- Personnel number (8 digit in SAP)
            HireDate    DATE         NULL,                        -- First hiring date
            IsActive    NUMBER(1)    DEFAULT 1 NOT NULL,
            CreatedOn   TIMESTAMP(0) DEFAULT SYSTIMESTAMP NOT NULL,
            CONSTRAINT PK_EmployeeMaster PRIMARY KEY (PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0000 - Actions (Infotype 0000, Massnahmen)
   Records every personnel action (hiring, org change, leaving, ...).
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0000
        (
            PERNR   NUMBER(10)   NOT NULL,                        -- Personnel number
            SUBTY   VARCHAR2(4)  DEFAULT ' ' NOT NULL,
            OBJPS   VARCHAR2(2)  DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)      DEFAULT ' ' NOT NULL,
            BEGDA   DATE         NOT NULL,
            ENDDA   DATE         DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)   DEFAULT 1 NOT NULL,
            MASSN   VARCHAR2(2)  NOT NULL,                        -- Action type   (T529A)
            MASSG   VARCHAR2(2)  NULL,                            -- Reason for action (T530)
            STAT2   CHAR(1)      NULL,                            -- Employment status (0=left,1=inactive,2=retiree,3=active)
            AEDTM   DATE         NULL,
            UNAME   VARCHAR2(12) NULL,
            CONSTRAINT PK_PA0000 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0000_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0001 - Organizational Assignment (Infotype 0001)
   Links the employee to enterprise & personnel structure and to OM objects.
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0001
        (
            PERNR   NUMBER(10)   NOT NULL,
            SUBTY   VARCHAR2(4)  DEFAULT ' ' NOT NULL,
            OBJPS   VARCHAR2(2)  DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)      DEFAULT ' ' NOT NULL,
            BEGDA   DATE         NOT NULL,
            ENDDA   DATE         DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)   DEFAULT 1 NOT NULL,
            BUKRS   VARCHAR2(4)  NULL,                            -- Company code   (T001)
            WERKS   VARCHAR2(4)  NULL,                            -- Personnel area (T500P)
            BTRTL   VARCHAR2(4)  NULL,                            -- Personnel subarea (T001P)
            PERSG   VARCHAR2(1)  NULL,                            -- Employee group    (T501)
            PERSK   VARCHAR2(2)  NULL,                            -- Employee subgroup (T503K)
            ORGEH   NUMBER(10)   NULL,                            -- Organizational unit (HRP1000, O)
            PLANS   NUMBER(10)   NULL,                            -- Position            (HRP1000, S)
            STELL   NUMBER(10)   NULL,                            -- Job                 (HRP1000, C)
            KOSTL   VARCHAR2(10) NULL,                            -- Cost center
            ABKRS   VARCHAR2(2)  NULL,                            -- Payroll area
            SACHZ   VARCHAR2(3)  NULL,                            -- Administrator
            AEDTM   DATE         NULL,
            UNAME   VARCHAR2(12) NULL,
            CONSTRAINT PK_PA0001 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0001_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0002 - Personal Data (Infotype 0002)
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0002
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   DEFAULT ' ' NOT NULL,
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            ANRED   VARCHAR2(1)   NULL,                           -- Form of address key
            NACHN   NVARCHAR2(40) NOT NULL,                       -- Last name
            VORNA   NVARCHAR2(40) NOT NULL,                       -- First name
            MIDNM   NVARCHAR2(40) NULL,                           -- Middle name
            RUFNM   NVARCHAR2(40) NULL,                           -- Nickname / known-as
            TITEL   VARCHAR2(15)  NULL,                           -- Title
            GBDAT   DATE          NULL,                           -- Date of birth
            GBORT   NVARCHAR2(40) NULL,                           -- Place of birth
            GESCH   CHAR(1)       NULL,                           -- Gender key (1=male,2=female,3=other/undefined)
            NATIO   VARCHAR2(3)   NULL,                           -- Nationality (T005)
            FAMST   VARCHAR2(1)   NULL,                           -- Marital status key
            SPRSL   VARCHAR2(1)   NULL,                           -- Language key
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0002 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0002_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0006 - Addresses (Infotype 0006). SUBTY = address type (T591A).
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0006
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   DEFAULT '1' NOT NULL,           -- 1 = permanent residence
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            STRAS   NVARCHAR2(60) NULL,                           -- Street and house number
            ORT01   NVARCHAR2(40) NULL,                           -- City
            ORT02   NVARCHAR2(40) NULL,                           -- District
            PSTLZ   VARCHAR2(10)  NULL,                           -- Postal code
            LAND1   VARCHAR2(3)   NULL,                           -- Country key (T005)
            STATE   VARCHAR2(3)   NULL,                           -- Region / state
            TELNR   VARCHAR2(20)  NULL,                           -- Telephone number
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0006 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0006_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0007 - Planned Working Time (Infotype 0007)
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0007
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   DEFAULT ' ' NOT NULL,
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            SCHKZ   VARCHAR2(8)   NULL,                           -- Work schedule rule (T508A)
            ZTERF   CHAR(1)       NULL,                           -- Time management status
            EMPCT   NUMBER(5,2)   NULL,                           -- Employment percentage
            WOSTD   NUMBER(6,2)   NULL,                           -- Weekly working hours
            MOSTD   NUMBER(7,2)   NULL,                           -- Monthly working hours
            JRSTD   NUMBER(8,2)   NULL,                           -- Annual working hours
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0007 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0007_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0008 - Basic Pay (Infotype 0008). Wage types are stored in PA0008_WageType.
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0008
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   DEFAULT ' ' NOT NULL,
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            TRFAR   VARCHAR2(2)   NULL,                           -- Pay scale type   (T510A)
            TRFGB   VARCHAR2(2)   NULL,                           -- Pay scale area   (T510G)
            TRFGR   VARCHAR2(8)   NULL,                           -- Pay scale group
            TRFST   VARCHAR2(2)   NULL,                           -- Pay scale level
            BSGRD   NUMBER(5,2)   NULL,                           -- Capacity utilization level (%)
            DIVGV   NUMBER(6,2)   NULL,                           -- Working hours per pay period
            WAERS   VARCHAR2(5)   NULL,                           -- Currency key (T500C)
            ANSAL   NUMBER(15,2)  NULL,                           -- Annual salary
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0008 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0008_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR),
            /* Alternate key so the wage-type sub-records can link on the natural
               (PERNR, ENDDA, SEQNR) tuple (SUBTY/OBJPS/SPRPS are constant here). */
            CONSTRAINT UQ_PA0008_Natural UNIQUE (PERNR, ENDDA, SEQNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* Wage type sub-records of Basic Pay (SAP fields LGART/BETRG/ANZHL). */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0008_WageType
        (
            PERNR   NUMBER(10)    NOT NULL,
            ENDDA   DATE          NOT NULL,
            SEQNR   NUMBER(10)    NOT NULL,
            LineNo  NUMBER(10)    NOT NULL,                       -- 1..40 wage type lines
            LGART   VARCHAR2(4)   NOT NULL,                       -- Wage type   (T512W)
            BETRG   NUMBER(15,2)  NULL,                           -- Amount
            WAERS   VARCHAR2(5)   NULL,                           -- Currency
            ANZHL   NUMBER(9,2)   NULL,                           -- Number / quantity
            CONSTRAINT PK_PA0008_WT PRIMARY KEY (PERNR, ENDDA, SEQNR, LineNo),
            CONSTRAINT FK_PA0008_WT FOREIGN KEY (PERNR, ENDDA, SEQNR)
                REFERENCES HR.PA0008(PERNR, ENDDA, SEQNR)         -- links on the natural key (UQ_PA0008_Natural)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0009 - Bank Details (Infotype 0009)
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0009
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   DEFAULT '0' NOT NULL,           -- 0 = main bank
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            BNKSA   VARCHAR2(2)   NULL,                           -- Bank details type
            EMFTX   NVARCHAR2(40) NULL,                           -- Payee name
            BANKS   VARCHAR2(3)   NULL,                           -- Bank country key
            BANKL   VARCHAR2(15)  NULL,                           -- Bank key / routing
            BANKN   VARCHAR2(34)  NULL,                           -- Bank account number (IBAN capable)
            ZLSCH   CHAR(1)       NULL,                           -- Payment method
            WAERS   VARCHAR2(5)   NULL,                           -- Currency
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0009 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0009_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0105 - Communication (Infotype 0105). SUBTY = communication type (T591A):
   0010 email, 0020 phone, MAIL system user, CELL mobile, ...
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0105
        (
            PERNR      NUMBER(10)     NOT NULL,
            SUBTY      VARCHAR2(4)    NOT NULL,                   -- Communication type (USRTY)
            OBJPS      VARCHAR2(2)    DEFAULT ' ' NOT NULL,
            SPRPS      CHAR(1)        DEFAULT ' ' NOT NULL,
            BEGDA      DATE           NOT NULL,
            ENDDA      DATE           DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR      NUMBER(10)     DEFAULT 1 NOT NULL,
            USRID      NVARCHAR2(100) NULL,                       -- Communication ID / value (short)
            USRID_LONG NVARCHAR2(241) NULL,                       -- Long form (e.g. email)
            AEDTM      DATE           NULL,
            UNAME      VARCHAR2(12)   NULL,
            CONSTRAINT PK_PA0105 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0105_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* Indexes on validity for fast "record valid on key date" lookups.
   ORA-00955 (name already used) is ignored so the script is re-runnable. */
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_PA0001_Valid ON HR.PA0001 (PERNR, BEGDA, ENDDA)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_PA0002_Valid ON HR.PA0002 (PERNR, BEGDA, ENDDA)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_PA0001_Org ON HR.PA0001 (ORGEH, BEGDA, ENDDA)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
