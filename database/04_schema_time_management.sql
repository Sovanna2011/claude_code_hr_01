SET DEFINE OFF
/* ============================================================================
   HR Module - Time Management (PT) - core objects
   Platform : Oracle Database
   Reference: SAP ECC 6.0 EHP8 - Time Management (PT)

   Absence / attendance records mirror infotype 2001 (Absences) and 2002
   (Attendances). Quota records mirror infotype 2006 (Absence Quotas).

   Oracle note: SAP TIME fields (BEGUZ/ENDUZ) map to a .NET TimeSpan, which the
   Oracle EF Core provider stores as INTERVAL DAY TO SECOND.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   PA2001 - Absences (Infotype 2001). SUBTY = absence type (AWART, T554S).
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA2001
        (
            PERNR    NUMBER(10)              NOT NULL,
            SUBTY    VARCHAR2(4)             NOT NULL,            -- Absence type (AWART)
            OBJPS    VARCHAR2(2)             DEFAULT ' ' NOT NULL,
            SPRPS    CHAR(1)                 DEFAULT ' ' NOT NULL,
            BEGDA    DATE                    NOT NULL,
            ENDDA    DATE                    NOT NULL,
            SEQNR    NUMBER(10)              DEFAULT 1 NOT NULL,
            AWART    VARCHAR2(4)             NOT NULL,            -- Attendance/Absence type
            ABWTG    NUMBER(7,2)             NULL,                -- Absence days
            STDAZ    NUMBER(7,2)             NULL,                -- Absence hours
            BEGUZ    INTERVAL DAY(2) TO SECOND(0) NULL,          -- Start time
            ENDUZ    INTERVAL DAY(2) TO SECOND(0) NULL,          -- End time
            APPROVED NUMBER(1)               DEFAULT 0 NOT NULL,
            AEDTM    DATE                    NULL,
            UNAME    VARCHAR2(12)            NULL,
            CONSTRAINT PK_PA2001 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, BEGDA, SEQNR),
            CONSTRAINT FK_PA2001_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA2006 - Absence Quotas (Infotype 2006). E.g. annual leave entitlement.
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA2006
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   NOT NULL,                       -- Quota type (KTART, T556A)
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            KTART   VARCHAR2(4)   NOT NULL,                       -- Absence quota type
            ANZHL   NUMBER(9,2)   NOT NULL,                       -- Quota entitlement number
            KVERB   NUMBER(9,2)   DEFAULT 0 NOT NULL,             -- Deducted amount
            DESTA   DATE          NULL,                           -- Deduction from
            DEEND   DATE          NULL,                           -- Deduction to
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA2006 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, BEGDA, SEQNR),
            CONSTRAINT FK_PA2006_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_PA2001_Period ON HR.PA2001 (PERNR, BEGDA, ENDDA)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
