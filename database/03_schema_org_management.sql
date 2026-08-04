SET DEFINE OFF
/* ============================================================================
   HR Module - Organizational Management (OM)
   Platform : Oracle Database
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

/* ----------------------------------------------------------------------------
   HRP1000 - Object (Org unit / Position / Job)
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.HRP1000
        (
            MANDT   VARCHAR2(3)   DEFAULT '100' NOT NULL,         -- Client
            PLVAR   VARCHAR2(2)   DEFAULT '01'  NOT NULL,         -- Plan version (active)
            OTYPE   VARCHAR2(2)   NOT NULL,                       -- Object type O/S/C/P
            OBJID   NUMBER(10)    NOT NULL,                       -- Object ID
            ISTAT   VARCHAR2(1)   DEFAULT '1'   NOT NULL,         -- Planning status (1=active)
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   VARCHAR2(3)   DEFAULT '000' NOT NULL,
            LANGU   VARCHAR2(1)   DEFAULT 'E'   NOT NULL,
            SHORT   NVARCHAR2(12) NULL,                           -- Object abbreviation
            STEXT   NVARCHAR2(40) NULL,                           -- Object name / description
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_HRP1000 PRIMARY KEY (PLVAR, OTYPE, OBJID, ISTAT, ENDDA, BEGDA, SEQNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   HRP1001 - Relationships
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.HRP1001
        (
            MANDT   VARCHAR2(3)   DEFAULT '100' NOT NULL,
            PLVAR   VARCHAR2(2)   DEFAULT '01'  NOT NULL,
            OTYPE   VARCHAR2(2)   NOT NULL,                       -- Source object type
            OBJID   NUMBER(10)    NOT NULL,                       -- Source object ID
            ISTAT   VARCHAR2(1)   DEFAULT '1'   NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   VARCHAR2(3)   DEFAULT '000' NOT NULL,
            RSIGN   VARCHAR2(1)   NOT NULL,                       -- Relationship specification A/B
            RELAT   VARCHAR2(3)   NOT NULL,                       -- Relationship (002,003,007,008,012...)
            SCLAS   VARCHAR2(2)   NOT NULL,                       -- Type of related object
            SOBID   VARCHAR2(45)  NOT NULL,                       -- ID of related object
            PRIOX   VARCHAR2(4)   NULL,                           -- Priority
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_HRP1001 PRIMARY KEY (PLVAR, OTYPE, OBJID, ISTAT, ENDDA, BEGDA, RSIGN, RELAT, SCLAS, SOBID, SEQNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_HRP1001_Source ON HR.HRP1001 (OTYPE, OBJID, RELAT, RSIGN, BEGDA, ENDDA)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_HRP1001_Target ON HR.HRP1001 (SCLAS, SOBID, RELAT, RSIGN, BEGDA, ENDDA)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
