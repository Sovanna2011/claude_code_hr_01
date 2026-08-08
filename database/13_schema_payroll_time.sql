/* ============================================================================
   HR Module - Payroll (PY) & Overtime / Public Holidays
   Platform : Microsoft SQL Server (T-SQL)
   Reference: SAP ECC 6.0 EHP8 - Payroll and Time Management

     HR.PublicHoliday   Holiday calendar (drives OT categorisation)
     HR.OvertimeRecord  Recorded overtime hours per employee/day
     HR.PayrollResult   Payroll run results (RT-style: gross/net per period)
     HR.PayrollConfig   Rates & OT multipliers (customizing)

   Overtime is categorised by date: public holiday > Sunday > normal, each with
   its own pay multiplier - reproduced by the app/report logic.
   ============================================================================ */

USE HRModule;
GO

IF OBJECT_ID('HR.PublicHoliday','U') IS NULL
CREATE TABLE HR.PublicHoliday
(
    HolDate  DATE          NOT NULL,
    HolName  NVARCHAR(60)  NULL,
    MOLGA    NVARCHAR(2)   DEFAULT '01' NOT NULL, -- country grouping
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PublicHoliday PRIMARY KEY (MOLGA, HolDate)
);
GO

/* OvertimeRecord.Category is a computed column. The weekday test is done with
   NLS-neutral date arithmetic (1970-01-04 was a Sunday) so it is deterministic.
   Public-holiday overrides Sunday/Normal; the app resolves the final category
   against HR.PublicHoliday (a computed column cannot join a table). */
IF OBJECT_ID('HR.OvertimeRecord','U') IS NULL
CREATE TABLE HR.OvertimeRecord
(
    OtId      INT          IDENTITY(1,1),
    PERNR     INT          NOT NULL,
    OtDate    DATE         NOT NULL,
    Hours     DECIMAL(6,2) NOT NULL,
    Category  AS (
        CASE WHEN DATEDIFF(DAY, '1970-01-04', OtDate) % 7 = 0
             THEN 'Sunday' ELSE 'Normal' END),
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_OvertimeRecord PRIMARY KEY (OtId),
    CONSTRAINT FK_Ot_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

IF OBJECT_ID('HR.PayrollConfig','U') IS NULL
CREATE TABLE HR.PayrollConfig
(
    ConfigKey NVARCHAR(30) NOT NULL,
    NumValue  DECIMAL(9,4) NOT NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PayrollConfig PRIMARY KEY (ConfigKey)
);
GO

IF OBJECT_ID('HR.PayrollResult','U') IS NULL
CREATE TABLE HR.PayrollResult
(
    ResultId   INT           IDENTITY(1,1),
    PERNR      INT           NOT NULL,
    PeriodFrom DATE          NOT NULL,
    PeriodTo   DATE          NOT NULL,
    BaseAmount DECIMAL(15,2) NOT NULL,
    OtAmount   DECIMAL(15,2) DEFAULT 0 NOT NULL,
    Gross      DECIMAL(15,2) NOT NULL,
    Tax        DECIMAL(15,2) DEFAULT 0 NOT NULL,
    Social     DECIMAL(15,2) DEFAULT 0 NOT NULL,
    Net        DECIMAL(15,2) NOT NULL,
    Currency   NVARCHAR(5)   DEFAULT 'EUR' NOT NULL,
    RunOn      DATETIME2(0)  DEFAULT SYSUTCDATETIME() NOT NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_PayrollResult PRIMARY KEY (ResultId),
    CONSTRAINT FK_PR_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* --- Seed ---------------------------------------------------------------- */
MERGE INTO HR.PayrollConfig AS t
USING (VALUES
    ('TAX_RATE',       0.15),
    ('SOCIAL_RATE',    0.09),
    ('OT_MULT_NORMAL', 1.25),
    ('OT_MULT_SUNDAY', 1.5),
    ('OT_MULT_HOLIDAY',2.0),
    ('MONTHLY_FACTOR', 4.33)
) AS s(ConfigKey, NumValue) ON (t.ConfigKey = s.ConfigKey)
WHEN NOT MATCHED THEN INSERT (ConfigKey, NumValue) VALUES (s.ConfigKey, s.NumValue);
GO

MERGE INTO HR.PublicHoliday AS t
USING (VALUES
    ('2026-01-01', N'New Year'),
    ('2026-04-03', N'Good Friday'),
    ('2026-05-01', N'Labour Day'),
    ('2026-10-03', N'Day of German Unity'),
    ('2026-12-25', N'Christmas Day'),
    ('2026-12-26', N'Boxing Day')
) AS s(HolDate, HolName) ON (t.MOLGA = '01' AND t.HolDate = s.HolDate)
WHEN NOT MATCHED THEN INSERT (HolDate, HolName) VALUES (s.HolDate, s.HolName);
GO

IF NOT EXISTS (SELECT 1 FROM HR.OvertimeRecord)
BEGIN
    INSERT INTO HR.OvertimeRecord (PERNR, OtDate, Hours) VALUES (1000, '2026-06-02', 2.0);
    INSERT INTO HR.OvertimeRecord (PERNR, OtDate, Hours) VALUES (1000, '2026-06-07', 4.0);
    INSERT INTO HR.OvertimeRecord (PERNR, OtDate, Hours) VALUES (1000, '2026-05-01', 3.0);
    INSERT INTO HR.OvertimeRecord (PERNR, OtDate, Hours) VALUES (1001, '2026-06-03', 1.5);
    INSERT INTO HR.OvertimeRecord (PERNR, OtDate, Hours) VALUES (1001, '2026-06-14', 3.0);
    INSERT INTO HR.OvertimeRecord (PERNR, OtDate, Hours) VALUES (1001, '2026-12-25', 2.0);
END
GO
