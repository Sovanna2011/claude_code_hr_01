/* ============================================================================
   HR Module - Extended Personnel Administration Infotypes
   Platform : Microsoft SQL Server (T-SQL)
   Reference: SAP ECC 6.0 EHP8 - PA (Personal Development / Time)

   Adds the infotypes needed for a fuller HR master record:
     PA0016  Contract Elements
     PA0019  Monitoring of Dates (task deadlines)
     PA0021  Family Members / Dependents
     PA0022  Education
     PA0023  Other/Previous Employers (work experience)
     PA0024  Qualifications (skills)
     PA2002  Attendances

   All tables carry the standard SAP infotype key
   (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR) and administrative fields.
   ============================================================================ */

USE HRModule;
GO

/* ----------------------------------------------------------------------------
   PA0016 - Contract Elements (Infotype 0016). Time constraint 1 (one valid).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0016','U') IS NULL
CREATE TABLE HR.PA0016
(
    PERNR   INT          NOT NULL,
    SUBTY   NVARCHAR(4)  DEFAULT ' ' NOT NULL,
    OBJPS   NVARCHAR(2)  DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)     DEFAULT ' ' NOT NULL,
    BEGDA   DATE         NOT NULL,
    ENDDA   DATE         DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT          DEFAULT 1 NOT NULL,
    CTTYP   NVARCHAR(2)  NULL,               -- Contract type (T547T)
    PRBEZ   DECIMAL(4,1) NULL,               -- Probation period (months)
    KDGFB   DECIMAL(4,1) NULL,               -- Notice period, employer (months)
    KDGF2   DECIMAL(4,1) NULL,               -- Notice period, employee (months)
    EGZuo   NVARCHAR(2)  NULL,               -- (spare) grouping
    AEDTM   DATE         NULL,
    UNAME   NVARCHAR(12) NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0016 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0016_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0019 - Monitoring of Dates (Infotype 0019). SUBTY = task type (TMART).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0019','U') IS NULL
CREATE TABLE HR.PA0019
(
    PERNR    INT          NOT NULL,
    SUBTY    NVARCHAR(4)  NOT NULL,           -- Task type (TMART)
    OBJPS    NVARCHAR(2)  DEFAULT ' ' NOT NULL,
    SPRPS    NCHAR(1)     DEFAULT ' ' NOT NULL,
    BEGDA    DATE         NOT NULL,
    ENDDA    DATE         DEFAULT '9999-12-31' NOT NULL,
    SEQNR    INT          DEFAULT 1 NOT NULL,
    TERMN    DATE         NOT NULL,           -- Date of task / deadline
    MNDAT    DATE         NULL,               -- Reminder date
    REMINDED BIT          DEFAULT 0 NOT NULL,
    AEDTM    DATE         NULL,
    UNAME    NVARCHAR(12) NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0019 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0019_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0021 - Family Members / Dependents (Infotype 0021). SUBTY = family type.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0021','U') IS NULL
CREATE TABLE HR.PA0021
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   NOT NULL,           -- Family/related person type (FAMSA)
    OBJPS   NVARCHAR(2)   DEFAULT '01' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' '  NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    FANAM   NVARCHAR(40)  NULL,               -- Last name of family member
    FAVOR   NVARCHAR(40)  NULL,               -- First name of family member
    FGBDT   DATE          NULL,               -- Date of birth
    FASEX   NCHAR(1)      NULL,               -- Gender (1/2)
    FGBLD   NVARCHAR(3)   NULL,               -- Country of birth
    FGBOT   NVARCHAR(40)  NULL,               -- Place of birth
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0021 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0021_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0022 - Education (Infotype 0022). SUBTY = education establishment type.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0022','U') IS NULL
CREATE TABLE HR.PA0022
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   NOT NULL,           -- Education establishment type (SLART)
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    SLABS   NVARCHAR(40)  NULL,               -- Certificate / degree
    INSTI   NVARCHAR(60)  NULL,               -- Institute / school name
    SLAND   NVARCHAR(3)   NULL,               -- Country of establishment
    SFACH   NVARCHAR(40)  NULL,               -- Branch of study / major
    SLGRA   NVARCHAR(20)  NULL,               -- Final grade
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0022 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0022_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0023 - Other / Previous Employers (Infotype 0023) - work experience.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0023','U') IS NULL
CREATE TABLE HR.PA0023
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   DEFAULT ' ' NOT NULL,
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    ARBGB   NVARCHAR(60)  NULL,               -- Previous employer
    ORT01   NVARCHAR(40)  NULL,               -- Place
    LAND1   NVARCHAR(3)   NULL,               -- Country
    TASK    NVARCHAR(60)  NULL,               -- Activity / job title
    BRANC   NVARCHAR(40)  NULL,               -- Industry
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0023 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0023_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA0024 - Qualifications / Skills (Infotype 0024).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA0024','U') IS NULL
CREATE TABLE HR.PA0024
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   DEFAULT ' ' NOT NULL,
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    QUALI   NVARCHAR(60)  NOT NULL,           -- Qualification / skill
    AUSPR   INT           NULL,               -- Proficiency (0-9)
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA0024 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
    CONSTRAINT FK_PA0024_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA2002 - Attendances (Infotype 2002). SUBTY = attendance type (AWART).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA2002','U') IS NULL
CREATE TABLE HR.PA2002
(
    PERNR   INT          NOT NULL,
    SUBTY   NVARCHAR(4)  NOT NULL,          -- Attendance type (AWART)
    OBJPS   NVARCHAR(2)  DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)     DEFAULT ' ' NOT NULL,
    BEGDA   DATE         NOT NULL,
    ENDDA   DATE         NOT NULL,
    SEQNR   INT          DEFAULT 1 NOT NULL,
    AWART   NVARCHAR(4)  NOT NULL,          -- Attendance type
    ABWTG   DECIMAL(7,2) NULL,              -- Attendance days
    STDAZ   DECIMAL(7,2) NULL,              -- Attendance hours
    BEGUZ   TIME         NULL,              -- Start time
    ENDUZ   TIME         NULL,              -- End time
    AEDTM   DATE         NULL,
    UNAME   NVARCHAR(12) NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PA2002 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, BEGDA, SEQNR),
    CONSTRAINT FK_PA2002_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   T547T - Contract type texts (customizing for IT0016).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.T547T','U') IS NULL
CREATE TABLE HR.T547T
(
    CTTYP NVARCHAR(2)   NOT NULL,
    CTTXT NVARCHAR(40)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T547T PRIMARY KEY (CTTYP)
);
GO

/* Validity indexes for list-type infotypes. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PA0021_Emp' AND object_id=OBJECT_ID('HR.PA0021'))
    CREATE INDEX IX_PA0021_Emp ON HR.PA0021 (PERNR);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PA0022_Emp' AND object_id=OBJECT_ID('HR.PA0022'))
    CREATE INDEX IX_PA0022_Emp ON HR.PA0022 (PERNR);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PA0023_Emp' AND object_id=OBJECT_ID('HR.PA0023'))
    CREATE INDEX IX_PA0023_Emp ON HR.PA0023 (PERNR);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PA2002_Emp' AND object_id=OBJECT_ID('HR.PA2002'))
    CREATE INDEX IX_PA2002_Emp ON HR.PA2002 (PERNR, BEGDA, ENDDA);
GO
