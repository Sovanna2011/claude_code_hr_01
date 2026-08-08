/* ============================================================================
   HR Module - Application Security (Users, Roles)
   Platform : Microsoft SQL Server (T-SQL)
   Reference: SAP authorization concept (roles/profiles, PFCG) - simplified.

   Authentication for the web front end. Three roles mirror typical SAP HCM
   authorization roles:
     HR_ADMIN    - full maintenance (hiring, master data, org, time)
     HR_MANAGER  - display all + record time (absences/attendances)
     EMPLOYEE    - employee self-service: display own record only

   Passwords are stored as PBKDF2-HMAC-SHA256 hashes (100,000 iterations,
   32-byte key) with a per-user salt. The C# backend uses identical parameters
   so the seeded demo users below authenticate out of the box.
   ============================================================================ */

USE HRModule;
GO

IF OBJECT_ID('HR.AppRole','U') IS NULL
CREATE TABLE HR.AppRole
(
    RoleKey   NVARCHAR(20)  NOT NULL,
    RoleName  NVARCHAR(60)  NOT NULL,
    CreatedOn DATETIME2(0)  DEFAULT SYSUTCDATETIME() NOT NULL,   -- audit: created date/time
    ChangedOn DATETIME2(0)  NULL,                                 -- audit: last updated date/time
    CONSTRAINT PK_AppRole PRIMARY KEY (RoleKey)
);
GO

IF OBJECT_ID('HR.AppUser','U') IS NULL
CREATE TABLE HR.AppUser
(
    UserId       INT           IDENTITY(1,1),
    Username     NVARCHAR(60)  NOT NULL,
    DisplayName  NVARCHAR(80)  NULL,
    PasswordHash NVARCHAR(200) NOT NULL,   -- base64 PBKDF2 hash
    PasswordSalt NVARCHAR(200) NOT NULL,   -- base64 salt
    RoleKey      NVARCHAR(20)  NOT NULL,
    PERNR        INT           NULL,        -- linked employee (self-service)
    IsActive     BIT           DEFAULT 1 NOT NULL,
    CreatedOn    DATETIME2(0)  DEFAULT SYSUTCDATETIME() NOT NULL,
    ChangedOn    DATETIME2(0)  NULL,                                -- audit: last updated date/time
    LastLogin    DATETIME2(0)  NULL,
    CONSTRAINT PK_AppUser PRIMARY KEY (UserId),
    CONSTRAINT UQ_AppUser_Username UNIQUE (Username),
    CONSTRAINT FK_AppUser_Role FOREIGN KEY (RoleKey) REFERENCES HR.AppRole(RoleKey),
    CONSTRAINT FK_AppUser_Emp  FOREIGN KEY (PERNR)   REFERENCES HR.EmployeeMaster(PERNR)
);
GO

/* --- Roles --------------------------------------------------------------- */
MERGE INTO HR.AppRole AS t
USING (VALUES
    ('HR_ADMIN',   'HR Administrator'),
    ('HR_MANAGER', 'HR Manager'),
    ('EMPLOYEE',   'Employee (Self-Service)')
) AS s(RoleKey, RoleName) ON (t.RoleKey = s.RoleKey)
WHEN NOT MATCHED THEN INSERT (RoleKey, RoleName) VALUES (s.RoleKey, s.RoleName);
GO

/* --- Demo users ----------------------------------------------------------
   Credentials (demo only):
     admin   / admin123     -> HR_ADMIN
     manager / manager123   -> HR_MANAGER (linked to PERNR 1000)
     linda   / linda123     -> EMPLOYEE   (linked to PERNR 1001)
   ------------------------------------------------------------------------- */
MERGE INTO HR.AppUser AS t
USING (VALUES
    ('admin',   N'Alex Admin',
     'E6XgKGqx24SZqw40twpIvY46z0dMf7+fLZkYNlaAdA0=',
     'SFJNT0RVTEVfU0FMVF8wMQ==', 'HR_ADMIN', CAST(NULL AS INT)),
    ('manager', N'Andreas Schmidt',
     'QHJsLcA2odYIeK4Xqo8O/xUKhI4vI1OU+nYEdL+Z1rI=',
     'SFJNT0RVTEVfU0FMVF8wMg==', 'HR_MANAGER', 1000),
    ('linda',   N'Linda Nguyen',
     'u8tja7bSHpvd9sdXgrnk78HQofSZ0MgOzK05tFN5x8U=',
     'SFJNT0RVTEVfU0FMVF8wMw==', 'EMPLOYEE', 1001)
) AS s(Username, DisplayName, PasswordHash, PasswordSalt, RoleKey, PERNR)
   ON (t.Username = s.Username)
WHEN NOT MATCHED THEN
    INSERT (Username, DisplayName, PasswordHash, PasswordSalt, RoleKey, PERNR)
    VALUES (s.Username, s.DisplayName, s.PasswordHash, s.PasswordSalt, s.RoleKey, s.PERNR);
GO
