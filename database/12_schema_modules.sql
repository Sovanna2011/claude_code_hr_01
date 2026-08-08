/* ============================================================================
   HR Module - Additional functional modules
   Platform : Microsoft SQL Server (T-SQL)
   Reference: SAP ECC 6.0 EHP8
     - Leave Management (ESS/MSS leave request & approval workflow over IT2001/2006)
     - Recruitment (E-Recruiting: requisitions & candidates)
     - Training & Event Management (course catalog & bookings; D = course type)
   ============================================================================ */

USE HRModule;
GO

/* ----------------------------------------------------------------------------
   Leave Management - request/approval workflow. On approval the app writes the
   absence (IT2001) and deducts the quota (IT2006), mirroring the demo logic.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.LeaveRequest','U') IS NULL
CREATE TABLE HR.LeaveRequest
(
    RequestId   INT            IDENTITY(1,1),
    PERNR       INT            NOT NULL,
    AWART       NVARCHAR(4)    NOT NULL,        -- leave type (T554S)
    BEGDA       DATE           NOT NULL,
    ENDDA       DATE           NOT NULL,
    Days        DECIMAL(7,2)   NOT NULL,
    Status      NVARCHAR(10)   DEFAULT 'Pending' NOT NULL, -- Pending/Approved/Rejected
    Note        NVARCHAR(200)  NULL,
    RequestedOn DATETIME2(0)   DEFAULT SYSUTCDATETIME() NOT NULL,
    DecidedBy   NVARCHAR(60)   NULL,
    DecidedOn   DATETIME2(0)   NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_LeaveRequest PRIMARY KEY (RequestId),
    CONSTRAINT FK_LReq_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR),
    CONSTRAINT CK_LReq_Status CHECK (Status IN ('Pending','Approved','Rejected'))
);
GO

/* ----------------------------------------------------------------------------
   Recruitment - requisitions and applicants.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.JobRequisition','U') IS NULL
CREATE TABLE HR.JobRequisition
(
    ReqId     INT           NOT NULL,
    Title     NVARCHAR(80)  NOT NULL,
    ORGEH     INT           NULL,             -- hiring org unit (HRP1000 O)
    Openings  INT           DEFAULT 1 NOT NULL,
    Status    NVARCHAR(10)  DEFAULT 'Open' NOT NULL,
    PostedOn  DATE          NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_JobRequisition PRIMARY KEY (ReqId)
);
GO

IF OBJECT_ID('HR.Applicant','U') IS NULL
CREATE TABLE HR.Applicant
(
    ApplicantId INT            IDENTITY(1,1),
    ReqId       INT            NOT NULL,
    Name        NVARCHAR(80)   NOT NULL,
    Email       NVARCHAR(120)  NULL,
    Stage       NVARCHAR(12)   DEFAULT 'Screening' NOT NULL, -- Screening/Interview/Offer/Hired/Rejected
    AppliedOn   DATE           NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_Applicant PRIMARY KEY (ApplicantId),
    CONSTRAINT FK_App_Req FOREIGN KEY (ReqId) REFERENCES HR.JobRequisition(ReqId)
);
GO

/* ----------------------------------------------------------------------------
   Training & Event Management - catalog and bookings.
   ---------------------------------------------------------------------------- */
IF OBJECT_ID('HR.TrainingCourse','U') IS NULL
CREATE TABLE HR.TrainingCourse
(
    CourseId   NVARCHAR(8)   NOT NULL,        -- e.g. D100 (SAP course type D)
    Title      NVARCHAR(80)  NOT NULL,
    Category   NVARCHAR(30)  NULL,
    Hours      DECIMAL(6,1)  NULL,
    CourseDate DATE          NULL,
    Seats      INT           NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_TrainingCourse PRIMARY KEY (CourseId)
);
GO

IF OBJECT_ID('HR.TrainingBooking','U') IS NULL
CREATE TABLE HR.TrainingBooking
(
    BookingId INT          IDENTITY(1,1),
    PERNR     INT          NOT NULL,
    CourseId  NVARCHAR(8)  NOT NULL,
    Status    NVARCHAR(12) DEFAULT 'Confirmed' NOT NULL,
    BookedOn  DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,
    CreatedOn DATETIME2(0) DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0) NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_TrainingBooking PRIMARY KEY (BookingId),
    CONSTRAINT UQ_Booking UNIQUE (PERNR, CourseId),
    CONSTRAINT FK_Book_Emp FOREIGN KEY (PERNR) REFERENCES HR.EmployeeMaster(PERNR),
    CONSTRAINT FK_Book_Course FOREIGN KEY (CourseId) REFERENCES HR.TrainingCourse(CourseId)
);
GO

/* --- Seed ---------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM HR.JobRequisition)
BEGIN
    INSERT INTO HR.JobRequisition (ReqId, Title, ORGEH, Openings, Status, PostedOn)
    VALUES (50001, N'HR Business Partner', 50000010, 1, 'Open', '2026-06-01');
    INSERT INTO HR.JobRequisition (ReqId, Title, ORGEH, Openings, Status, PostedOn)
    VALUES (50002, N'Financial Analyst', 50000020, 2, 'Open', '2026-07-01');

    INSERT INTO HR.Applicant (ReqId, Name, Email, Stage, AppliedOn)
    VALUES (50001, N'Sophie Turner', N's.turner@mail.com', 'Interview', '2026-06-10');
    INSERT INTO HR.Applicant (ReqId, Name, Email, Stage, AppliedOn)
    VALUES (50001, N'Mark Lee', N'm.lee@mail.com', 'Screening', '2026-06-15');
    INSERT INTO HR.Applicant (ReqId, Name, Email, Stage, AppliedOn)
    VALUES (50002, N'Ana Silva', N'a.silva@mail.com', 'Offer', '2026-07-08');
END
GO

IF NOT EXISTS (SELECT 1 FROM HR.TrainingCourse)
BEGIN
    INSERT INTO HR.TrainingCourse (CourseId, Title, Category, Hours, CourseDate, Seats)
    VALUES ('D100', N'Leadership Essentials', N'Leadership', 16, '2026-09-15', 12);
    INSERT INTO HR.TrainingCourse (CourseId, Title, Category, Hours, CourseDate, Seats)
    VALUES ('D200', N'SAP HCM Fundamentals', N'Technical', 24, '2026-10-06', 20);
    INSERT INTO HR.TrainingCourse (CourseId, Title, Category, Hours, CourseDate, Seats)
    VALUES ('D300', N'Business English (B2)', N'Language', 40, '2026-11-03', 15);
    INSERT INTO HR.TrainingCourse (CourseId, Title, Category, Hours, CourseDate, Seats)
    VALUES ('D400', N'Data Privacy & GDPR', N'Compliance', 4, '2026-09-01', 50);

    INSERT INTO HR.TrainingBooking (PERNR, CourseId, Status) VALUES (1000, 'D100', 'Confirmed');
    INSERT INTO HR.TrainingBooking (PERNR, CourseId, Status) VALUES (1001, 'D200', 'Confirmed');
END
GO

IF NOT EXISTS (SELECT 1 FROM HR.LeaveRequest)
BEGIN
    INSERT INTO HR.LeaveRequest (PERNR, AWART, BEGDA, ENDDA, Days, Status, Note)
    VALUES (1001, '0100', '2026-08-10', '2026-08-14', 5, 'Pending', N'Summer holiday');
    INSERT INTO HR.LeaveRequest (PERNR, AWART, BEGDA, ENDDA, Days, Status, Note)
    VALUES (1001, '0200', '2026-05-04', '2026-05-04', 1, 'Approved', N'Doctor');
END
GO
