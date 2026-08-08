/* ============================================================================
   HR Module - Time Management (PT) - core objects
   Platform : Microsoft SQL Server (T-SQL)
   Reference: SAP ECC 6.0 EHP8 - Time Management (PT)

   Absence / attendance records mirror infotype 2001 (Absences) and 2002
   (Attendances). Quota records mirror infotype 2006 (Absence Quotas).

   Note: SAP TIME fields (BEGUZ/ENDUZ) map to a .NET TimeSpan, which on SQL
   Server is stored as TIME(0).
   ============================================================================ */

USE HRModule;
GO

/* ----------------------------------------------------------------------------
   PA2001 - Absences (Infotype 2001). SUBTY = absence type (AWART, T554S).
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA2001','U') IS NULL
CREATE TABLE HR.PA2001
(
    PERNR    INT           NOT NULL,
    SUBTY    NVARCHAR(4)   NOT NULL,                       -- Absence type (AWART)
    OBJPS    NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS    NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA    DATE          NOT NULL,
    ENDDA    DATE          NOT NULL,
    SEQNR    INT           DEFAULT 1 NOT NULL,
    AWART    NVARCHAR(4)   NOT NULL,                        -- Attendance/Absence type
    ABWTG    DECIMAL(7,2)  NULL,                            -- Absence days
    STDAZ    DECIMAL(7,2)  NULL,                            -- Absence hours
    BEGUZ    TIME(0)       NULL,                            -- Start time
    ENDUZ    TIME(0)       NULL,                            -- End time
    APPROVED BIT           DEFAULT 0 NOT NULL,
    AEDTM    DATE          NULL,
    UNAME    NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    CreatedBy NVARCHAR(12) NULL,                                -- audit: created by
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    ChangedBy NVARCHAR(12) NULL,                                -- audit: last changed by
    CONSTRAINT PK_PA2001 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, BEGDA, SEQNR),
    CONSTRAINT FK_PA2001_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* ----------------------------------------------------------------------------
   PA2006 - Absence Quotas (Infotype 2006). E.g. annual leave entitlement.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.PA2006','U') IS NULL
CREATE TABLE HR.PA2006
(
    PERNR   INT           NOT NULL,
    SUBTY   NVARCHAR(4)   NOT NULL,                        -- Quota type (KTART, T556A)
    OBJPS   NVARCHAR(2)   DEFAULT ' ' NOT NULL,
    SPRPS   NCHAR(1)      DEFAULT ' ' NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          NOT NULL,
    SEQNR   INT           DEFAULT 1 NOT NULL,
    KTART   NVARCHAR(4)   NOT NULL,                        -- Absence quota type
    ANZHL   DECIMAL(9,2)  NOT NULL,                        -- Quota entitlement number
    KVERB   DECIMAL(9,2)  DEFAULT 0 NOT NULL,              -- Deducted amount
    DESTA   DATE          NULL,                            -- Deduction from
    DEEND   DATE          NULL,                            -- Deduction to
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    CreatedBy NVARCHAR(12) NULL,                                -- audit: created by
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    ChangedBy NVARCHAR(12) NULL,                                -- audit: last changed by
    CONSTRAINT PK_PA2006 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, BEGDA, SEQNR),
    CONSTRAINT FK_PA2006_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

IF INDEX_ID('HR.PA2001', 'IX_PA2001_Period') IS NULL
CREATE INDEX IX_PA2001_Period ON HR.PA2001 (PERNR, BEGDA, ENDDA);
GO
