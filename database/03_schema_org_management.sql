/* ============================================================================
   HR Module - Organizational Management (OM)
   Platform : Microsoft SQL Server (T-SQL)
   Reference: SAP ECC 6.0 EHP8 - Organizational Management (PA-OS)

   OM in SAP is built from objects and the relationships between them:
     HRP1000  Objects   (OTYPE O=Org unit, S=Position, C=Job, P=Person)
     HRP1001  Relationships between objects (evaluation paths)
     HRP1002  Description (infotype 1002, verbal text) - simplified here

   Standard relationship (RELAT) / sign (RSIGN) combinations used:
     A 002 "reports to"        S->S (position reports to position)
     B 002 "is line supervisor of"
     A 003 "belongs to"        S->O (position belongs to org unit)
     B 003 "incorporates"      O->S
     A 007 "is described by"   S->C (position described by job)
     B 008 "holder"            S->P (position is held by person)
     B 012 "is managed by"     O->S (org unit managed by chief position)
   ============================================================================ */

USE HRModule;
GO

/* ----------------------------------------------------------------------------
   HRP1000 - Object (Org unit / Position / Job)
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.HRP1000','U') IS NULL
CREATE TABLE HR.HRP1000
(
    MANDT   NVARCHAR(3)   DEFAULT '100' NOT NULL,          -- Client
    PLVAR   NVARCHAR(2)   DEFAULT '01'  NOT NULL,          -- Plan version (active)
    OTYPE   NVARCHAR(2)   NOT NULL,                        -- Object type O/S/C/P
    OBJID   INT           NOT NULL,                        -- Object ID
    ISTAT   NVARCHAR(1)   DEFAULT '1'   NOT NULL,          -- Planning status (1=active)
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   NVARCHAR(3)   DEFAULT '000' NOT NULL,
    LANGU   NVARCHAR(1)   DEFAULT 'E'   NOT NULL,
    SHORT   NVARCHAR(12)  NULL,                            -- Object abbreviation
    STEXT   NVARCHAR(40)  NULL,                            -- Object name / description
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CONSTRAINT PK_HRP1000 PRIMARY KEY (PLVAR, OTYPE, OBJID, ISTAT, ENDDA, BEGDA, SEQNR)
);
GO

/* ----------------------------------------------------------------------------
   HRP1001 - Relationships
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.HRP1001','U') IS NULL
CREATE TABLE HR.HRP1001
(
    MANDT   NVARCHAR(3)   DEFAULT '100' NOT NULL,
    PLVAR   NVARCHAR(2)   DEFAULT '01'  NOT NULL,
    OTYPE   NVARCHAR(2)   NOT NULL,                        -- Source object type
    OBJID   INT           NOT NULL,                        -- Source object ID
    ISTAT   NVARCHAR(1)   DEFAULT '1'   NOT NULL,
    BEGDA   DATE          NOT NULL,
    ENDDA   DATE          DEFAULT '9999-12-31' NOT NULL,
    SEQNR   NVARCHAR(3)   DEFAULT '000' NOT NULL,
    RSIGN   NVARCHAR(1)   NOT NULL,                        -- Relationship specification A/B
    RELAT   NVARCHAR(3)   NOT NULL,                        -- Relationship (002,003,007,008,012...)
    SCLAS   NVARCHAR(2)   NOT NULL,                        -- Type of related object
    SOBID   NVARCHAR(45)  NOT NULL,                        -- ID of related object
    PRIOX   NVARCHAR(4)   NULL,                            -- Priority
    AEDTM   DATE          NULL,
    UNAME   NVARCHAR(12)  NULL,
    CONSTRAINT PK_HRP1001 PRIMARY KEY (PLVAR, OTYPE, OBJID, ISTAT, ENDDA, BEGDA, RSIGN, RELAT, SCLAS, SOBID, SEQNR)
);
GO

IF INDEX_ID('HR.HRP1001', 'IX_HRP1001_Source') IS NULL
CREATE INDEX IX_HRP1001_Source ON HR.HRP1001 (OTYPE, OBJID, RELAT, RSIGN, BEGDA, ENDDA);
GO
IF INDEX_ID('HR.HRP1001', 'IX_HRP1001_Target') IS NULL
CREATE INDEX IX_HRP1001_Target ON HR.HRP1001 (SCLAS, SOBID, RELAT, RSIGN, BEGDA, ENDDA);
GO
