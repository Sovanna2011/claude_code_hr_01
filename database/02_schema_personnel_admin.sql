/* ============================================================================
   HR Module - Personnel Administration (PA) Infotypes
   Platform : Microsoft SQL Server (T-SQL)
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

   SAP note: the SAP-initial value of the mandatory key fields SUBTY/OBJPS/SPRPS
   is a single space ' ' (SAP's initial value for character fields). Each DDL
   statement is guarded with IF OBJECT_ID(...) IS NULL so the script is
   re-runnable.
   ============================================================================ */

USE HRModule;
GO

/* ----------------------------------------------------------------------------
   Master record - PA0003 is the SAP payroll status; here we keep a lightweight
   employee master anchor so PERNR referential integrity can be enforced.
   The real personal data lives in PA0002.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.EmployeeMaster','U') IS NULL
CREATE TABLE HR.EmployeeMaster
(
    PERNR       INT          NOT NULL,                    -- Personnel number (8 digit in SAP)
    HireDate    DATE         NULL,                        -- First hiring date
    IsActive    BIT          DEFAULT 1 NOT NULL,
    CreatedOn   DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,
    ChangedOn   DATETIME2(0) NULL,                            -- audit: last updated date/time
    CONSTRAINT PK_EmployeeMaster PRIMARY KEY (PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0000 - Actions (Infotype 0000, Massnahmen)
   Records every personnel action (hiring, org change, leaving, ...).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0000','U') IS NULL
CREATE TABLE HR.PA0000
(
    PERNR   INT          NOT NULL,                        -- Personnel number
    SUBTY   NVARCHAR(4)  DEFAULT ' ' NOT NULL,
    OBJPS   NVARCHAR(2)  DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)     DEFAULT ' ' NOT NULL,
    BEGDA   DATE         NOT NULL,
    ENDDA   DATE         DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT          DEFAULT 1 NOT NULL,
    MASSN   NVARCHAR(2)  NOT NULL,                         -- Action type   (T529A)
    MASSG   NVARCHAR(2)  NULL,                             -- Reason for action (T530)
    STAT2   NCHAR(1)     NULL,                             -- Employment status (0=left,1=inactive,2=retiree,3=active)
    AEDTM   DATE         NULL,
    UNAME   NVARCHAR(12) NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0000 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0000_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0001 - Organizational Assignment (Infotype 0001)
   Links the employee to enterprise & personnel structure and to OM objects.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0001','U') IS NULL
CREATE TABLE HR.PA0001
(
    PERNR   INT          NOT NULL,
    SUBTY   NVARCHAR(4)  DEFAULT ' ' NOT NULL,
    OBJPS   NVARCHAR(2)  DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)     DEFAULT ' ' NOT NULL,
    BEGDA   DATE         NOT NULL,
    ENDDA   DATE         DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT          DEFAULT 1 NOT NULL,
    BUKRS   NVARCHAR(4)  NULL,                             -- Company code   (T001)
    WERKS   NVARCHAR(4)  NULL,                             -- Personnel area (T500P)
    BTRTL   NVARCHAR(4)  NULL,                             -- Personnel subarea (T001P)
    PERSG   NVARCHAR(1)  NULL,                             -- Employee group    (T501)
    PERSK   NVARCHAR(2)  NULL,                             -- Employee subgroup (T503K)
    ORGEH   INT          NULL,                             -- Organizational unit (HRP1000, O)
    PLANS   INT          NULL,                             -- Position            (HRP1000, S)
    STELL   INT          NULL,                             -- Job                 (HRP1000, C)
    KOSTL   NVARCHAR(10) NULL,                             -- Cost center
    ABKRS   NVARCHAR(2)  NULL,                             -- Payroll area
    SACHZ   NVARCHAR(3)  NULL,                             -- Administrator
    AEDTM   DATE         NULL,
    UNAME   NVARCHAR(12) NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0001 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0001_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0002 - Personal Data (Infotype 0002)
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0002','U') IS NULL
CREATE TABLE HR.PA0002
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   DEFAULT ' ' NOT NULL,
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    ANRED   NVARCHAR(1)   NULL,                            -- Form of address key
    NACHN   NVARCHAR(40)  NOT NULL,                        -- Last name
    VORNA   NVARCHAR(40)  NOT NULL,                        -- First name
    MIDNM   NVARCHAR(40)  NULL,                            -- Middle name
    RUFNM   NVARCHAR(40)  NULL,                            -- Nickname / known-as
    TITEL   NVARCHAR(15)  NULL,                            -- Title
    GBDAT   DATE          NULL,                            -- Date of birth
    GBORT   NVARCHAR(40)  NULL,                            -- Place of birth
    GESCH   NCHAR(1)      NULL,                            -- Gender key (1=male,2=female,3=other/undefined)
    NATIO   NVARCHAR(3)   NULL,                            -- Nationality (T005)
    FAMST   NVARCHAR(1)   NULL,                            -- Marital status key
    SPRSL   NVARCHAR(1)   NULL,                            -- Language key
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0002 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0002_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0006 - Addresses (Infotype 0006). SUBTY = address type (T591A).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0006','U') IS NULL
CREATE TABLE HR.PA0006
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   DEFAULT '1' NOT NULL,            -- 1 = permanent residence
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    STRAS   NVARCHAR(60)  NULL,                            -- Street and house number
    ORT01   NVARCHAR(40)  NULL,                            -- City
    ORT02   NVARCHAR(40)  NULL,                            -- District
    PSTLZ   NVARCHAR(10)  NULL,                            -- Postal code
    LAND1   NVARCHAR(3)   NULL,                            -- Country key (T005)
    STATE   NVARCHAR(3)   NULL,                            -- Region / state
    TELNR   NVARCHAR(20)  NULL,                            -- Telephone number
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0006 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0006_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0007 - Planned Working Time (Infotype 0007)
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0007','U') IS NULL
CREATE TABLE HR.PA0007
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   DEFAULT ' ' NOT NULL,
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    SCHKZ   NVARCHAR(8)   NULL,                            -- Work schedule rule (T508A)
    ZTERF   NCHAR(1)      NULL,                            -- Time management status
    EMPCT   DECIMAL(5,2)  NULL,                            -- Employment percentage
    WOSTD   DECIMAL(6,2)  NULL,                            -- Weekly working hours
    MOSTD   DECIMAL(7,2)  NULL,                            -- Monthly working hours
    JRSTD   DECIMAL(8,2)  NULL,                            -- Annual working hours
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0007 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0007_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0008 - Basic Pay (Infotype 0008). Wage types are stored in PA0008_WageType.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0008','U') IS NULL
CREATE TABLE HR.PA0008
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   DEFAULT ' ' NOT NULL,
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    TRFAR   NVARCHAR(2)   NULL,                            -- Pay scale type   (T510A)
    TRFGB   NVARCHAR(2)   NULL,                            -- Pay scale area   (T510G)
    TRFGR   NVARCHAR(8)   NULL,                            -- Pay scale group
    TRFST   NVARCHAR(2)   NULL,                            -- Pay scale level
    BSGRD   DECIMAL(5,2)  NULL,                            -- Capacity utilization level (%)
    DIVGV   DECIMAL(6,2)  NULL,                            -- Working hours per pay period
    WAERS   NVARCHAR(5)   NULL,                            -- Currency key (T500C)
    ANSAL   DECIMAL(15,2) NULL,                            -- Annual salary
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0008 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0008_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR),
    /* Alternate key so the wage-type sub-records can link on the natural
       (PERNR, ENDDA, SEQNR) tuple (SUBTY/OBJPS/SPRPS are constant here). */
    CONSTRAINT UQ_PA0008_Natural UNIQUE (PERNR, ENDDA, SEQNR)
);
GO

/* Wage type sub-records of Basic Pay (SAP fields LGART/BETRG/ANZHL). */
IF OBJECT_ID('HR.PA0008_WageType','U') IS NULL
CREATE TABLE HR.PA0008_WageType
(
    PERNR   INT           NOT NULL,
    ENDDA   DATE          NOT NULL,
    SEQNR   INT           NOT NULL,
    LineNo  INT           NOT NULL,                        -- 1..40 wage type lines
    LGART   NVARCHAR(4)   NOT NULL,                        -- Wage type   (T512W)
    BETRG   DECIMAL(15,2) NULL,                            -- Amount
    WAERS   NVARCHAR(5)   NULL,                            -- Currency
    ANZHL   DECIMAL(9,2)  NULL,                            -- Number / quantity
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0008_WT PRIMARY KEY (PERNR, ENDDA, SEQNR, LineNo),
    CONSTRAINT FK_PA0008_WT FOREIGN KEY (PERNR, ENDDA, SEQNR)
        REFERENCES HR.PA0008(PERNR, ENDDA, SEQNR)          -- links on the natural key (UQ_PA0008_Natural)
);
GO

/* ----------------------------------------------------------------------------
   PA0009 - Bank Details (Infotype 0009)
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0009','U') IS NULL
CREATE TABLE HR.PA0009
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   DEFAULT '0' NOT NULL,            -- 0 = main bank
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    BNKSA   NVARCHAR(2)   NULL,                            -- Bank details type
    EMFTX   NVARCHAR(40)  NULL,                            -- Payee name
    BANKS   NVARCHAR(3)   NULL,                            -- Bank country key
    BANKL   NVARCHAR(15)  NULL,                            -- Bank key / routing
    BANKN   NVARCHAR(34)  NULL,                            -- Bank account number (IBAN capable)
    ZLSCH   NCHAR(1)      NULL,                            -- Payment method
    WAERS   NVARCHAR(5)   NULL,                            -- Currency
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0009 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0009_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0105 - Communication (Infotype 0105). SUBTY = communication type (T591A):
   0010 email, 0020 phone, MAIL system user, CELL mobile, ...
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0105','U') IS NULL
CREATE TABLE HR.PA0105
(
    PERNR      INT            NOT NULL,
    SUBTY      NVARCHAR(4)    NOT NULL,                    -- Communication type (USRTY)
    OBJPS      NVARCHAR(2)    DEFAULT ' ' NOT NULL,
    SPRPS      NCHAR(1)       DEFAULT ' ' NOT NULL,
    BEGDA      DATE           NOT NULL,
    ENDDA      DATE           DEFAULT '9999-12-31' NOT NULL,
    SEQNR      INT            DEFAULT 1 NOT NULL,
    USRID      NVARCHAR(100)  NULL,                        -- Communication ID / value (short)
    USRID_LONG NVARCHAR(241)  NULL,                        -- Long form (e.g. email)
    AEDTM      DATE           NULL,
    UNAME      NVARCHAR(12)   NULL,
    CreatedOn  DATETIME2(0)   DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn  DATETIME2(0)   NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0105 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0105_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* Indexes on validity for fast "record valid on key date" lookups.
   Guarded with IF INDEX_ID(...) IS NULL so the script is re-runnable. */
IF INDEX_ID('HR.PA0001', 'IX_PA0001_Valid') IS NULL
CREATE INDEX IX_PA0001_Valid ON HR.PA0001 (PERNR, BEGDA, ENDDA);
GO
IF INDEX_ID('HR.PA0002', 'IX_PA0002_Valid') IS NULL
CREATE INDEX IX_PA0002_Valid ON HR.PA0002 (PERNR, BEGDA, ENDDA);
GO
IF INDEX_ID('HR.PA0001', 'IX_PA0001_Org') IS NULL
CREATE INDEX IX_PA0001_Org ON HR.PA0001 (ORGEH, BEGDA, ENDDA);
GO
