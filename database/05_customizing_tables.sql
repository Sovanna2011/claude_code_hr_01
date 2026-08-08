/* ============================================================================
   HR Module - Customizing / Control Tables (T-tables)
   Platform : Microsoft SQL Server (T-SQL)
   Reference: SAP ECC 6.0 EHP8 - Enterprise & Personnel structure customizing

   These are the SAP configuration tables that drive the enterprise structure
   (company code, personnel area/subarea) and personnel structure (employee
   group/subgroup), plus the various value-help / check tables.
   ============================================================================ */

USE HRModule;
GO

/* T001  - Company Codes */
IF OBJECT_ID('HR.T001','U') IS NULL
CREATE TABLE HR.T001
(
    BUKRS NVARCHAR(4)   NOT NULL,     -- Company code
    BUTXT NVARCHAR(50)  NULL,         -- Name
    LAND1 NVARCHAR(3)   NULL,         -- Country
    WAERS NVARCHAR(5)   NULL,         -- Currency
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T001 PRIMARY KEY (BUKRS)
);
GO

/* T500P - Personnel Areas */
IF OBJECT_ID('HR.T500P','U') IS NULL
CREATE TABLE HR.T500P
(
    WERKS NVARCHAR(4)   NOT NULL,     -- Personnel area
    NAME1 NVARCHAR(60)  NULL,         -- Name
    BUKRS NVARCHAR(4)   NULL,         -- Company code
    MOLGA NVARCHAR(2)   NULL,         -- Country grouping
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T500P PRIMARY KEY (WERKS)
);
GO

/* T001P - Personnel Subareas */
IF OBJECT_ID('HR.T001P','U') IS NULL
CREATE TABLE HR.T001P
(
    WERKS NVARCHAR(4)   NOT NULL,     -- Personnel area
    BTRTL NVARCHAR(4)   NOT NULL,     -- Personnel subarea
    BTEXT NVARCHAR(30)  NULL,         -- Text
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T001P PRIMARY KEY (WERKS, BTRTL)
);
GO

/* T501  - Employee Group */
IF OBJECT_ID('HR.T501','U') IS NULL
CREATE TABLE HR.T501
(
    PERSG NVARCHAR(1)   NOT NULL,     -- Employee group
    PTEXT NVARCHAR(30)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T501 PRIMARY KEY (PERSG)
);
GO

/* T503K - Employee Subgroup */
IF OBJECT_ID('HR.T503K','U') IS NULL
CREATE TABLE HR.T503K
(
    PERSK NVARCHAR(2)   NOT NULL,     -- Employee subgroup
    PTEXT NVARCHAR(30)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T503K PRIMARY KEY (PERSK)
);
GO

/* T528T - Position texts (job/position short & long text) - simplified */
IF OBJECT_ID('HR.T528T','U') IS NULL
CREATE TABLE HR.T528T
(
    PLANS INT           NOT NULL,     -- Position
    PLSTX NVARCHAR(40)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T528T PRIMARY KEY (PLANS)
);
GO

/* T529A - Personnel action types */
IF OBJECT_ID('HR.T529A','U') IS NULL
CREATE TABLE HR.T529A
(
    MASSN NVARCHAR(2)   NOT NULL,     -- Action type
    MNTXT NVARCHAR(40)  NULL,         -- Text
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T529A PRIMARY KEY (MASSN)
);
GO

/* T530  - Reasons for action */
IF OBJECT_ID('HR.T530','U') IS NULL
CREATE TABLE HR.T530
(
    MASSN NVARCHAR(2)   NOT NULL,
    MASSG NVARCHAR(2)   NOT NULL,
    MGTXT NVARCHAR(40)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T530 PRIMARY KEY (MASSN, MASSG)
);
GO

/* T554S - Absence / Attendance types */
IF OBJECT_ID('HR.T554S','U') IS NULL
CREATE TABLE HR.T554S
(
    MOABW NVARCHAR(2)   DEFAULT '01' NOT NULL, -- Grouping
    AWART NVARCHAR(4)   NOT NULL,     -- Absence/attendance type
    ATEXT NVARCHAR(30)  NULL,
    KENNZ NCHAR(1)      NULL,         -- 'A'=absence 'P'=attendance
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T554S PRIMARY KEY (MOABW, AWART)
);
GO

/* T005  - Countries */
IF OBJECT_ID('HR.T005','U') IS NULL
CREATE TABLE HR.T005
(
    LAND1 NVARCHAR(3)   NOT NULL,     -- Country key
    LANDX NVARCHAR(50)  NULL,         -- Country name
    WAERS NVARCHAR(5)   NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T005 PRIMARY KEY (LAND1)
);
GO

/* T512T - Wage type texts */
IF OBJECT_ID('HR.T512T','U') IS NULL
CREATE TABLE HR.T512T
(
    LGART NVARCHAR(4)   NOT NULL,     -- Wage type
    LGTXT NVARCHAR(30)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_T512T PRIMARY KEY (LGART)
);
GO

/* Generic domain fixed-value table for simple keys (gender, marital status,
   form of address, communication type) - emulates SAP domain value ranges. */
IF OBJECT_ID('HR.DomainValue','U') IS NULL
CREATE TABLE HR.DomainValue
(
    Domain   NVARCHAR(20)  NOT NULL,  -- GESCH, FAMST, ANRED, USRTY, STAT2
    ValueKey NVARCHAR(10)  NOT NULL,
    ValueTxt NVARCHAR(40)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_DomainValue PRIMARY KEY (Domain, ValueKey)
);
GO
