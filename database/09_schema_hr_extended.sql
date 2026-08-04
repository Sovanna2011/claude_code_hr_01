SET DEFINE OFF
/* ============================================================================
   HR Module - Extended Personnel Administration Infotypes
   Platform : Oracle Database
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

/* ----------------------------------------------------------------------------
   PA0016 - Contract Elements (Infotype 0016). Time constraint 1 (one valid).
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0016
        (
            PERNR   NUMBER(10)   NOT NULL,
            SUBTY   VARCHAR2(4)  DEFAULT ' ' NOT NULL,
            OBJPS   VARCHAR2(2)  DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)      DEFAULT ' ' NOT NULL,
            BEGDA   DATE         NOT NULL,
            ENDDA   DATE         DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)   DEFAULT 1 NOT NULL,
            CTTYP   VARCHAR2(2)  NULL,               -- Contract type (T547T)
            PRBEZ   NUMBER(4,1)  NULL,               -- Probation period (months)
            KDGFB   NUMBER(4,1)  NULL,               -- Notice period, employer (months)
            KDGF2   NUMBER(4,1)  NULL,               -- Notice period, employee (months)
            EGZuo   VARCHAR2(2)  NULL,               -- (spare) grouping
            AEDTM   DATE         NULL,
            UNAME   VARCHAR2(12) NULL,
            CONSTRAINT PK_PA0016 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0016_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0019 - Monitoring of Dates (Infotype 0019). SUBTY = task type (TMART).
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0019
        (
            PERNR    NUMBER(10)   NOT NULL,
            SUBTY    VARCHAR2(4)  NOT NULL,           -- Task type (TMART)
            OBJPS    VARCHAR2(2)  DEFAULT ' ' NOT NULL,
            SPRPS    CHAR(1)      DEFAULT ' ' NOT NULL,
            BEGDA    DATE         NOT NULL,
            ENDDA    DATE         DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR    NUMBER(10)   DEFAULT 1 NOT NULL,
            TERMN    DATE         NOT NULL,           -- Date of task / deadline
            MNDAT    DATE         NULL,               -- Reminder date
            REMINDED NUMBER(1)    DEFAULT 0 NOT NULL,
            AEDTM    DATE         NULL,
            UNAME    VARCHAR2(12) NULL,
            CONSTRAINT PK_PA0019 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0019_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0021 - Family Members / Dependents (Infotype 0021). SUBTY = family type.
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0021
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   NOT NULL,           -- Family/related person type (FAMSA)
            OBJPS   VARCHAR2(2)   DEFAULT '01' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' '  NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            FANAM   NVARCHAR2(40) NULL,               -- Last name of family member
            FAVOR   NVARCHAR2(40) NULL,               -- First name of family member
            FGBDT   DATE          NULL,               -- Date of birth
            FASEX   CHAR(1)       NULL,               -- Gender (1/2)
            FGBLD   VARCHAR2(3)   NULL,               -- Country of birth
            FGBOT   NVARCHAR2(40) NULL,               -- Place of birth
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0021 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0021_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0022 - Education (Infotype 0022). SUBTY = education establishment type.
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0022
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   NOT NULL,           -- Education establishment type (SLART)
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            SLABS   NVARCHAR2(40) NULL,               -- Certificate / degree
            INSTI   NVARCHAR2(60) NULL,               -- Institute / school name
            SLAND   VARCHAR2(3)   NULL,               -- Country of establishment
            SFACH   NVARCHAR2(40) NULL,               -- Branch of study / major
            SLGRA   NVARCHAR2(20) NULL,               -- Final grade
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0022 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0022_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0023 - Other / Previous Employers (Infotype 0023) - work experience.
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0023
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   DEFAULT ' ' NOT NULL,
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            ARBGB   NVARCHAR2(60) NULL,               -- Previous employer
            ORT01   NVARCHAR2(40) NULL,               -- Place
            LAND1   VARCHAR2(3)   NULL,               -- Country
            TASK    NVARCHAR2(60) NULL,               -- Activity / job title
            BRANC   NVARCHAR2(40) NULL,               -- Industry
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0023 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0023_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA0024 - Qualifications / Skills (Infotype 0024).
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA0024
        (
            PERNR   NUMBER(10)    NOT NULL,
            SUBTY   VARCHAR2(4)   DEFAULT ' ' NOT NULL,
            OBJPS   VARCHAR2(2)   DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)       DEFAULT ' ' NOT NULL,
            BEGDA   DATE          NOT NULL,
            ENDDA   DATE          DEFAULT DATE '9999-12-31' NOT NULL,
            SEQNR   NUMBER(10)    DEFAULT 1 NOT NULL,
            QUALI   NVARCHAR2(60) NOT NULL,           -- Qualification / skill
            AUSPR   NUMBER(10)    NULL,               -- Proficiency (0-9)
            AEDTM   DATE          NULL,
            UNAME   VARCHAR2(12)  NULL,
            CONSTRAINT PK_PA0024 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, SEQNR),
            CONSTRAINT FK_PA0024_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   PA2002 - Attendances (Infotype 2002). SUBTY = attendance type (AWART).
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.PA2002
        (
            PERNR   NUMBER(10)               NOT NULL,
            SUBTY   VARCHAR2(4)              NOT NULL,          -- Attendance type (AWART)
            OBJPS   VARCHAR2(2)              DEFAULT ' ' NOT NULL,
            SPRPS   CHAR(1)                  DEFAULT ' ' NOT NULL,
            BEGDA   DATE                     NOT NULL,
            ENDDA   DATE                     NOT NULL,
            SEQNR   NUMBER(10)               DEFAULT 1 NOT NULL,
            AWART   VARCHAR2(4)              NOT NULL,          -- Attendance type
            ABWTG   NUMBER(7,2)              NULL,              -- Attendance days
            STDAZ   NUMBER(7,2)              NULL,              -- Attendance hours
            BEGUZ   INTERVAL DAY(2) TO SECOND(0) NULL,         -- Start time
            ENDUZ   INTERVAL DAY(2) TO SECOND(0) NULL,         -- End time
            AEDTM   DATE                     NULL,
            UNAME   VARCHAR2(12)             NULL,
            CONSTRAINT PK_PA2002 PRIMARY KEY (PERNR, SUBTY, OBJPS, SPRPS, ENDDA, BEGDA, SEQNR),
            CONSTRAINT FK_PA2002_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* ----------------------------------------------------------------------------
   T547T - Contract type texts (customizing for IT0016).
   ---------------------------------------------------------------------------- */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T547T
        (
            CTTYP VARCHAR2(2)   NOT NULL,
            CTTXT NVARCHAR2(40) NULL,
            CONSTRAINT PK_T547T PRIMARY KEY (CTTYP)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* Validity indexes for list-type infotypes. */
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_PA0021_Emp ON HR.PA0021 (PERNR)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_PA0022_Emp ON HR.PA0022 (PERNR)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_PA0023_Emp ON HR.PA0023 (PERNR)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX HR.IX_PA2002_Emp ON HR.PA2002 (PERNR, BEGDA, ENDDA)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
