SET DEFINE OFF
/* ============================================================================
   HR Module - Customizing / Control Tables (T-tables)
   Platform : Oracle Database
   Reference: SAP ECC 6.0 EHP8 - Enterprise & Personnel structure customizing

   These are the SAP configuration tables that drive the enterprise structure
   (company code, personnel area/subarea) and personnel structure (employee
   group/subgroup), plus the various value-help / check tables.
   ============================================================================ */

/* T001  - Company Codes */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T001
        (
            BUKRS VARCHAR2(4)   NOT NULL,     -- Company code
            BUTXT NVARCHAR2(50) NULL,         -- Name
            LAND1 VARCHAR2(3)   NULL,         -- Country
            WAERS VARCHAR2(5)   NULL,         -- Currency
            CONSTRAINT PK_T001 PRIMARY KEY (BUKRS)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T500P - Personnel Areas */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T500P
        (
            WERKS VARCHAR2(4)   NOT NULL,     -- Personnel area
            NAME1 NVARCHAR2(60) NULL,         -- Name
            BUKRS VARCHAR2(4)   NULL,         -- Company code
            MOLGA VARCHAR2(2)   NULL,         -- Country grouping
            CONSTRAINT PK_T500P PRIMARY KEY (WERKS)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T001P - Personnel Subareas */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T001P
        (
            WERKS VARCHAR2(4)   NOT NULL,     -- Personnel area
            BTRTL VARCHAR2(4)   NOT NULL,     -- Personnel subarea
            BTEXT NVARCHAR2(30) NULL,         -- Text
            CONSTRAINT PK_T001P PRIMARY KEY (WERKS, BTRTL)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T501  - Employee Group */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T501
        (
            PERSG VARCHAR2(1)   NOT NULL,     -- Employee group
            PTEXT NVARCHAR2(30) NULL,
            CONSTRAINT PK_T501 PRIMARY KEY (PERSG)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T503K - Employee Subgroup */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T503K
        (
            PERSK VARCHAR2(2)   NOT NULL,     -- Employee subgroup
            PTEXT NVARCHAR2(30) NULL,
            CONSTRAINT PK_T503K PRIMARY KEY (PERSK)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T528T - Position texts (job/position short & long text) - simplified */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T528T
        (
            PLANS NUMBER(10)    NOT NULL,     -- Position
            PLSTX NVARCHAR2(40) NULL,
            CONSTRAINT PK_T528T PRIMARY KEY (PLANS)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T529A - Personnel action types */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T529A
        (
            MASSN VARCHAR2(2)   NOT NULL,     -- Action type
            MNTXT NVARCHAR2(40) NULL,         -- Text
            CONSTRAINT PK_T529A PRIMARY KEY (MASSN)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T530  - Reasons for action */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T530
        (
            MASSN VARCHAR2(2)   NOT NULL,
            MASSG VARCHAR2(2)   NOT NULL,
            MGTXT NVARCHAR2(40) NULL,
            CONSTRAINT PK_T530 PRIMARY KEY (MASSN, MASSG)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T554S - Absence / Attendance types */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T554S
        (
            MOABW VARCHAR2(2)   DEFAULT '01' NOT NULL, -- Grouping
            AWART VARCHAR2(4)   NOT NULL,     -- Absence/attendance type
            ATEXT NVARCHAR2(30) NULL,
            KENNZ CHAR(1)       NULL,         -- 'A'=absence 'P'=attendance
            CONSTRAINT PK_T554S PRIMARY KEY (MOABW, AWART)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T005  - Countries */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T005
        (
            LAND1 VARCHAR2(3)   NOT NULL,     -- Country key
            LANDX NVARCHAR2(50) NULL,         -- Country name
            WAERS VARCHAR2(5)   NULL,
            CONSTRAINT PK_T005 PRIMARY KEY (LAND1)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* T512T - Wage type texts */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.T512T
        (
            LGART VARCHAR2(4)   NOT NULL,     -- Wage type
            LGTXT NVARCHAR2(30) NULL,
            CONSTRAINT PK_T512T PRIMARY KEY (LGART)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

/* Generic domain fixed-value table for simple keys (gender, marital status,
   form of address, communication type) - emulates SAP domain value ranges. */
BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE HR.DomainValue
        (
            Domain   VARCHAR2(20)  NOT NULL,  -- GESCH, FAMST, ANRED, USRTY, STAT2
            ValueKey VARCHAR2(10)  NOT NULL,
            ValueTxt NVARCHAR2(40) NULL,
            CONSTRAINT PK_DomainValue PRIMARY KEY (Domain, ValueKey)
        )]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/
