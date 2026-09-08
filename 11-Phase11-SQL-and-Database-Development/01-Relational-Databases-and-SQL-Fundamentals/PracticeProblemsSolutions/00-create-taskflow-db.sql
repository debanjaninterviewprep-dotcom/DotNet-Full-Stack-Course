/*=============================================================================
  TaskFlow — Phase 11 Sample Database
  -----------------------------------------------------------------------------
  This is THE shared database for every topic in Phase 11. Run it once, then
  every Notes.md / Practice-Problems.md example in topics 01–22 will work.

  Target   : SQL Server 2019+ / Azure SQL Database / SQL Server on Linux (Docker)
  Idempotent: YES — safe to re-run. It drops and recreates all objects.
  Runtime  : ~5 seconds.

  Usage (sqlcmd):
      sqlcmd -S localhost -U sa -P "<your-password>" -i 00-create-taskflow-db.sql
  Usage (Azure Data Studio / SSMS):
      Open, press F5.

  NOTE FOR AZURE SQL DATABASE:
      Azure SQL cannot run `CREATE DATABASE` from inside another database's
      context in the same batch. Create `TaskFlowDb` from the portal first, then
      run this script with the `USE` statement removed (see section 0).
=============================================================================*/

SET NOCOUNT ON;
GO

/*-----------------------------------------------------------------------------
  0. Database
-----------------------------------------------------------------------------*/
IF DB_ID(N'TaskFlowDb') IS NULL
BEGIN
    PRINT 'Creating database TaskFlowDb...';
    EXEC (N'CREATE DATABASE TaskFlowDb');
END
GO

USE TaskFlowDb;   -- <-- remove this line when running against Azure SQL Database
GO

/*-----------------------------------------------------------------------------
  1. Drop existing objects (child-first so FKs unwind cleanly)
-----------------------------------------------------------------------------*/
DROP TABLE IF EXISTS audit.TaskHistory;
DROP TABLE IF EXISTS app.TimeEntries;
DROP TABLE IF EXISTS app.TaskLabels;
DROP TABLE IF EXISTS app.Comments;
DROP TABLE IF EXISTS app.TaskAssignments;
DROP TABLE IF EXISTS app.Tasks;
DROP TABLE IF EXISTS app.Labels;
DROP TABLE IF EXISTS app.Projects;
DROP TABLE IF EXISTS app.TeamMembers;
DROP TABLE IF EXISTS app.Teams;
DROP TABLE IF EXISTS app.Users;
DROP TABLE IF EXISTS ref.Priorities;
DROP TABLE IF EXISTS ref.TaskStatuses;
GO

/*-----------------------------------------------------------------------------
  2. Schemas
     app   — transactional/business tables
     ref   — small reference (lookup) tables
     audit — history / append-only tables
-----------------------------------------------------------------------------*/
IF SCHEMA_ID(N'app')   IS NULL EXEC (N'CREATE SCHEMA app');
IF SCHEMA_ID(N'ref')   IS NULL EXEC (N'CREATE SCHEMA ref');
IF SCHEMA_ID(N'audit') IS NULL EXEC (N'CREATE SCHEMA audit');
GO

/*-----------------------------------------------------------------------------
  3. Reference tables
-----------------------------------------------------------------------------*/
CREATE TABLE ref.TaskStatuses
(
    StatusId    TINYINT        NOT NULL CONSTRAINT PK_TaskStatuses PRIMARY KEY,
    StatusCode  VARCHAR(20)    NOT NULL CONSTRAINT UQ_TaskStatuses_Code UNIQUE,
    StatusName  NVARCHAR(50)   NOT NULL,
    IsTerminal  BIT            NOT NULL CONSTRAINT DF_TaskStatuses_IsTerminal DEFAULT (0),
    SortOrder   TINYINT        NOT NULL
);

CREATE TABLE ref.Priorities
(
    PriorityId   TINYINT       NOT NULL CONSTRAINT PK_Priorities PRIMARY KEY,
    PriorityCode VARCHAR(20)   NOT NULL CONSTRAINT UQ_Priorities_Code UNIQUE,
    PriorityName NVARCHAR(50)  NOT NULL,
    SlaHours     SMALLINT      NULL      -- NULL = no SLA. Deliberate: teaches NULL handling.
);
GO

/*-----------------------------------------------------------------------------
  4. Core tables
-----------------------------------------------------------------------------*/
CREATE TABLE app.Users
(
    UserId       INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_Users PRIMARY KEY,
    Email        NVARCHAR(256)  NOT NULL CONSTRAINT UQ_Users_Email UNIQUE,
    FirstName    NVARCHAR(100)  NOT NULL,
    LastName     NVARCHAR(100)  NOT NULL,
    -- PERSISTED so it can be indexed; teaches computed columns in topic 02.
    FullName     AS (FirstName + N' ' + LastName) PERSISTED,
    JobTitle     NVARCHAR(100)  NULL,
    ManagerId    INT            NULL,      -- self-reference: powers self-joins & recursive CTEs
    HourlyRate   DECIMAL(9,2)   NULL,
    CountryCode  CHAR(2)        NOT NULL CONSTRAINT DF_Users_Country DEFAULT ('GB'),
    IsActive     BIT            NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    CreatedAtUtc DATETIME2(3)   NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Users_Manager FOREIGN KEY (ManagerId) REFERENCES app.Users (UserId),
    CONSTRAINT CK_Users_HourlyRate CHECK (HourlyRate IS NULL OR HourlyRate >= 0)
);

CREATE TABLE app.Teams
(
    TeamId       INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_Teams PRIMARY KEY,
    TeamName     NVARCHAR(100)  NOT NULL CONSTRAINT UQ_Teams_Name UNIQUE,
    Department   NVARCHAR(100)  NOT NULL,
    LeadUserId   INT            NULL,
    CreatedAtUtc DATETIME2(3)   NOT NULL CONSTRAINT DF_Teams_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Teams_Lead FOREIGN KEY (LeadUserId) REFERENCES app.Users (UserId)
);

CREATE TABLE app.TeamMembers
(
    TeamId    INT          NOT NULL,
    UserId    INT          NOT NULL,
    RoleName  NVARCHAR(50) NOT NULL CONSTRAINT DF_TeamMembers_Role DEFAULT (N'Member'),
    JoinedOn  DATE         NOT NULL CONSTRAINT DF_TeamMembers_Joined DEFAULT (CAST(SYSUTCDATETIME() AS DATE)),
    CONSTRAINT PK_TeamMembers PRIMARY KEY (TeamId, UserId),   -- composite key
    CONSTRAINT FK_TeamMembers_Team FOREIGN KEY (TeamId) REFERENCES app.Teams (TeamId) ON DELETE CASCADE,
    CONSTRAINT FK_TeamMembers_User FOREIGN KEY (UserId) REFERENCES app.Users (UserId)
);

CREATE TABLE app.Projects
(
    ProjectId    INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_Projects PRIMARY KEY,
    ProjectCode  VARCHAR(10)    NOT NULL CONSTRAINT UQ_Projects_Code UNIQUE,
    ProjectName  NVARCHAR(150)  NOT NULL,
    TeamId       INT            NOT NULL,
    OwnerUserId  INT            NOT NULL,
    Budget       DECIMAL(12,2)  NULL,
    StartDate    DATE           NOT NULL,
    EndDate      DATE           NULL,       -- NULL = still running
    IsArchived   BIT            NOT NULL CONSTRAINT DF_Projects_Archived DEFAULT (0),
    CONSTRAINT FK_Projects_Team  FOREIGN KEY (TeamId)      REFERENCES app.Teams (TeamId),
    CONSTRAINT FK_Projects_Owner FOREIGN KEY (OwnerUserId) REFERENCES app.Users (UserId),
    CONSTRAINT CK_Projects_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
);

CREATE TABLE app.Labels
(
    LabelId   INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_Labels PRIMARY KEY,
    LabelName NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Labels_Name UNIQUE,
    ColorHex  CHAR(7)       NOT NULL CONSTRAINT DF_Labels_Color DEFAULT ('#808080'),
    CONSTRAINT CK_Labels_ColorHex CHECK (ColorHex LIKE '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')
);

CREATE TABLE app.Tasks
(
    TaskId         INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_Tasks PRIMARY KEY,
    ProjectId      INT            NOT NULL,
    ParentTaskId   INT            NULL,      -- self-reference: sub-tasks, recursive CTEs
    Title          NVARCHAR(200)  NOT NULL,
    Description    NVARCHAR(MAX)  NULL,
    StatusId       TINYINT        NOT NULL,
    PriorityId     TINYINT        NOT NULL,
    EstimatedHours DECIMAL(6,2)   NULL,
    StoryPoints    TINYINT        NULL,
    DueDate        DATE           NULL,
    CompletedAtUtc DATETIME2(3)   NULL,
    CreatedByUserId INT           NOT NULL,
    CreatedAtUtc   DATETIME2(3)   NOT NULL CONSTRAINT DF_Tasks_CreatedAt DEFAULT (SYSUTCDATETIME()),
    ModifiedAtUtc  DATETIME2(3)   NULL,
    -- Deliberately holds valid JSON: powers the JSON lessons in topic 18.
    MetadataJson   NVARCHAR(MAX)  NULL,
    CONSTRAINT FK_Tasks_Project  FOREIGN KEY (ProjectId)       REFERENCES app.Projects (ProjectId),
    CONSTRAINT FK_Tasks_Parent   FOREIGN KEY (ParentTaskId)    REFERENCES app.Tasks (TaskId),
    CONSTRAINT FK_Tasks_Status   FOREIGN KEY (StatusId)        REFERENCES ref.TaskStatuses (StatusId),
    CONSTRAINT FK_Tasks_Priority FOREIGN KEY (PriorityId)      REFERENCES ref.Priorities (PriorityId),
    CONSTRAINT FK_Tasks_Creator  FOREIGN KEY (CreatedByUserId) REFERENCES app.Users (UserId),
    CONSTRAINT CK_Tasks_Estimate CHECK (EstimatedHours IS NULL OR EstimatedHours > 0),
    CONSTRAINT CK_Tasks_Json     CHECK (MetadataJson IS NULL OR ISJSON(MetadataJson) = 1)
);

CREATE TABLE app.TaskAssignments
(
    TaskId       INT          NOT NULL,
    UserId       INT          NOT NULL,
    AssignedOn   DATE         NOT NULL CONSTRAINT DF_TaskAssign_On DEFAULT (CAST(SYSUTCDATETIME() AS DATE)),
    IsPrimary    BIT          NOT NULL CONSTRAINT DF_TaskAssign_Primary DEFAULT (0),
    CONSTRAINT PK_TaskAssignments PRIMARY KEY (TaskId, UserId),
    CONSTRAINT FK_TaskAssign_Task FOREIGN KEY (TaskId) REFERENCES app.Tasks (TaskId) ON DELETE CASCADE,
    CONSTRAINT FK_TaskAssign_User FOREIGN KEY (UserId) REFERENCES app.Users (UserId)
);

CREATE TABLE app.TaskLabels
(
    TaskId  INT NOT NULL,
    LabelId INT NOT NULL,
    CONSTRAINT PK_TaskLabels PRIMARY KEY (TaskId, LabelId),
    CONSTRAINT FK_TaskLabels_Task  FOREIGN KEY (TaskId)  REFERENCES app.Tasks (TaskId) ON DELETE CASCADE,
    CONSTRAINT FK_TaskLabels_Label FOREIGN KEY (LabelId) REFERENCES app.Labels (LabelId) ON DELETE CASCADE
);

CREATE TABLE app.Comments
(
    CommentId       INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_Comments PRIMARY KEY,
    TaskId          INT            NOT NULL,
    AuthorUserId    INT            NOT NULL,
    ParentCommentId INT            NULL,     -- threaded replies
    Body            NVARCHAR(MAX)  NOT NULL,
    PostedAtUtc     DATETIME2(3)   NOT NULL CONSTRAINT DF_Comments_Posted DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Comments_Task   FOREIGN KEY (TaskId)          REFERENCES app.Tasks (TaskId) ON DELETE CASCADE,
    CONSTRAINT FK_Comments_Author FOREIGN KEY (AuthorUserId)    REFERENCES app.Users (UserId),
    CONSTRAINT FK_Comments_Parent FOREIGN KEY (ParentCommentId) REFERENCES app.Comments (CommentId)
);

CREATE TABLE app.TimeEntries
(
    TimeEntryId INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_TimeEntries PRIMARY KEY,
    TaskId      INT           NOT NULL,
    UserId      INT           NOT NULL,
    WorkDate    DATE          NOT NULL,
    Hours       DECIMAL(5,2)  NOT NULL,
    Notes       NVARCHAR(400) NULL,
    IsBillable  BIT           NOT NULL CONSTRAINT DF_TimeEntries_Billable DEFAULT (1),
    CONSTRAINT FK_TimeEntries_Task FOREIGN KEY (TaskId) REFERENCES app.Tasks (TaskId) ON DELETE CASCADE,
    CONSTRAINT FK_TimeEntries_User FOREIGN KEY (UserId) REFERENCES app.Users (UserId),
    CONSTRAINT CK_TimeEntries_Hours CHECK (Hours > 0 AND Hours <= 24)
);

CREATE TABLE audit.TaskHistory
(
    TaskHistoryId  BIGINT        NOT NULL IDENTITY(1,1) CONSTRAINT PK_TaskHistory PRIMARY KEY,
    TaskId         INT           NOT NULL,
    ChangedAtUtc   DATETIME2(3)  NOT NULL CONSTRAINT DF_TaskHistory_At DEFAULT (SYSUTCDATETIME()),
    ChangedBy      SYSNAME       NOT NULL CONSTRAINT DF_TaskHistory_By DEFAULT (SUSER_SNAME()),
    ColumnName     SYSNAME       NOT NULL,
    OldValue       NVARCHAR(400) NULL,
    NewValue       NVARCHAR(400) NULL
    -- Deliberately NO foreign key: audit rows must survive task deletion.
);
GO

/*-----------------------------------------------------------------------------
  5. Seed reference data
-----------------------------------------------------------------------------*/
INSERT INTO ref.TaskStatuses (StatusId, StatusCode, StatusName, IsTerminal, SortOrder) VALUES
    (1, 'BACKLOG',     N'Backlog',       0, 1),
    (2, 'TODO',        N'To Do',         0, 2),
    (3, 'IN_PROGRESS', N'In Progress',   0, 3),
    (4, 'IN_REVIEW',   N'In Review',     0, 4),
    (5, 'BLOCKED',     N'Blocked',       0, 5),
    (6, 'DONE',        N'Done',          1, 6),
    (7, 'CANCELLED',   N'Cancelled',     1, 7);

INSERT INTO ref.Priorities (PriorityId, PriorityCode, PriorityName, SlaHours) VALUES
    (1, 'CRITICAL', N'Critical',  4),
    (2, 'HIGH',     N'High',     24),
    (3, 'MEDIUM',   N'Medium',   72),
    (4, 'LOW',      N'Low',     168),
    (5, 'NONE',     N'No Priority', NULL);   -- NULL SLA on purpose
GO

/*-----------------------------------------------------------------------------
  6. Seed users (with a 3-level management hierarchy)
-----------------------------------------------------------------------------*/
SET IDENTITY_INSERT app.Users ON;
INSERT INTO app.Users (UserId, Email, FirstName, LastName, JobTitle, ManagerId, HourlyRate, CountryCode, IsActive) VALUES
    ( 1, N'ada.lovelace@taskflow.io',     N'Ada',     N'Lovelace',  N'CTO',                 NULL,  180.00, 'GB', 1),
    ( 2, N'grace.hopper@taskflow.io',     N'Grace',   N'Hopper',    N'VP Engineering',         1,  150.00, 'US', 1),
    ( 3, N'alan.turing@taskflow.io',      N'Alan',    N'Turing',    N'VP Research',            1,  150.00, 'GB', 1),
    ( 4, N'linus.torvalds@taskflow.io',   N'Linus',   N'Torvalds',  N'Engineering Manager',    2,  120.00, 'FI', 1),
    ( 5, N'margaret.hamilton@taskflow.io',N'Margaret',N'Hamilton',  N'Engineering Manager',    2,  120.00, 'US', 1),
    ( 6, N'barbara.liskov@taskflow.io',   N'Barbara', N'Liskov',    N'Principal Engineer',     3,  135.00, 'US', 1),
    ( 7, N'ken.thompson@taskflow.io',     N'Ken',     N'Thompson',  N'Senior Engineer',        4,   95.00, 'US', 1),
    ( 8, N'dennis.ritchie@taskflow.io',   N'Dennis',  N'Ritchie',   N'Senior Engineer',        4,   95.00, 'US', 1),
    ( 9, N'anita.borg@taskflow.io',       N'Anita',   N'Borg',      N'Engineer',               4,   72.50, 'US', 1),
    (10, N'radia.perlman@taskflow.io',    N'Radia',   N'Perlman',   N'Senior Engineer',        5,   98.00, 'US', 1),
    (11, N'jean.bartik@taskflow.io',      N'Jean',    N'Bartik',    N'Engineer',               5,   70.00, 'US', 1),
    (12, N'katherine.johnson@taskflow.io',N'Katherine',N'Johnson',  N'Data Analyst',           5,   68.00, 'US', 1),
    (13, N'shafi.goldwasser@taskflow.io', N'Shafi',   N'Goldwasser',N'Security Engineer',      6,  110.00, 'IL', 1),
    (14, N'tim.berners-lee@taskflow.io',  N'Tim',     N'Berners-Lee',N'Architect',             3,  140.00, 'GB', 1),
    (15, N'joan.clarke@taskflow.io',      N'Joan',    N'Clarke',    N'QA Lead',                2,   88.00, 'GB', 1),
    (16, N'hedy.lamarr@taskflow.io',      N'Hedy',    N'Lamarr',    N'QA Engineer',           15,   64.00, 'AT', 1),
    (17, N'donald.knuth@taskflow.io',     N'Donald',  N'Knuth',     N'Principal Engineer',     3,  135.00, 'US', 0),  -- inactive
    (18, N'edsger.dijkstra@taskflow.io',  N'Edsger',  N'Dijkstra',  N'Engineer',               6,   75.00, 'NL', 0),  -- inactive
    (19, N'sophie.wilson@taskflow.io',    N'Sophie',  N'Wilson',    NULL,                      4,     NULL, 'GB', 1),  -- NULL title AND rate
    (20, N'guido.rossum@taskflow.io',     N'Guido',   N'van Rossum',N'Engineer',            NULL,   80.00, 'NL', 1);  -- no manager
SET IDENTITY_INSERT app.Users OFF;
GO

/*-----------------------------------------------------------------------------
  7. Seed teams, memberships, projects, labels
-----------------------------------------------------------------------------*/
SET IDENTITY_INSERT app.Teams ON;
INSERT INTO app.Teams (TeamId, TeamName, Department, LeadUserId) VALUES
    (1, N'Platform',      N'Engineering', 4),
    (2, N'Web',           N'Engineering', 5),
    (3, N'Data',          N'Engineering', 5),
    (4, N'Security',      N'Engineering', 6),
    (5, N'Quality',       N'Engineering', 15),
    (6, N'Research',      N'R&D',         3),
    (7, N'Design System', N'Product',     NULL);   -- team with no lead
SET IDENTITY_INSERT app.Teams OFF;

INSERT INTO app.TeamMembers (TeamId, UserId, RoleName, JoinedOn) VALUES
    (1,  4, N'Lead',        '2024-01-15'), (1,  7, N'Member', '2024-01-15'),
    (1,  8, N'Member',      '2024-02-01'), (1,  9, N'Member', '2024-06-10'),
    (1, 19, N'Member',      '2025-03-01'),
    (2,  5, N'Lead',        '2024-01-15'), (2, 10, N'Member', '2024-01-20'),
    (2, 11, N'Member',      '2024-09-01'), (2, 20, N'Member', '2025-01-06'),
    (3,  5, N'Lead',        '2024-03-01'), (3, 12, N'Member', '2024-03-01'),
    (4,  6, N'Lead',        '2024-02-10'), (4, 13, N'Member', '2024-02-10'),
    (5, 15, N'Lead',        '2024-01-15'), (5, 16, N'Member', '2024-04-22'),
    (6,  3, N'Lead',        '2024-01-15'), (6,  6, N'Member', '2024-01-15'),
    (6, 14, N'Member',      '2024-01-15'),
    -- Ken is in two teams: proves M:N and creates duplicate-row traps in joins.
    (4,  7, N'Consultant',  '2025-02-01');

SET IDENTITY_INSERT app.Projects ON;
INSERT INTO app.Projects (ProjectId, ProjectCode, ProjectName, TeamId, OwnerUserId, Budget, StartDate, EndDate, IsArchived) VALUES
    (1, 'TF-CORE',  N'TaskFlow Core API',            1,  4, 250000.00, '2024-02-01', NULL,         0),
    (2, 'TF-WEB',   N'TaskFlow Web Client',          2,  5, 180000.00, '2024-02-15', NULL,         0),
    (3, 'TF-RPT',   N'Reporting & Analytics',        3,  5,  95000.00, '2024-05-01', NULL,         0),
    (4, 'TF-SEC',   N'Security Hardening',           4,  6,  60000.00, '2024-06-01', NULL,         0),
    (5, 'TF-QA',    N'Test Automation Suite',        5, 15,  45000.00, '2024-04-01', NULL,         0),
    (6, 'TF-MOB',   N'Mobile App (Cancelled)',       2,  5,      NULL, '2024-08-01', '2024-11-30', 1),
    (7, 'TF-LAB',   N'Research Spikes',              6,  3,      NULL, '2024-01-10', NULL,         0),
    (8, 'TF-DS',    N'Design System v2',             7, 14,  30000.00, '2025-01-05', NULL,         0);  -- team has no lead
SET IDENTITY_INSERT app.Projects OFF;

SET IDENTITY_INSERT app.Labels ON;
INSERT INTO app.Labels (LabelId, LabelName, ColorHex) VALUES
    (1, N'bug',          '#D73A4A'), (2, N'feature',      '#0E8A16'),
    (3, N'tech-debt',    '#FBCA04'), (4, N'security',     '#B60205'),
    (5, N'performance',  '#1D76DB'), (6, N'documentation','#0075CA'),
    (7, N'good-first-issue', '#7057FF'), (8, N'wont-fix', '#FFFFFF');
SET IDENTITY_INSERT app.Labels OFF;
GO

/*-----------------------------------------------------------------------------
  8. Seed tasks
     Mix of: sub-tasks, NULL due dates, NULL estimates, terminal + open statuses,
     an orphan-free but label-free task, and JSON metadata on some rows.
-----------------------------------------------------------------------------*/
SET IDENTITY_INSERT app.Tasks ON;
INSERT INTO app.Tasks
    (TaskId, ProjectId, ParentTaskId, Title, StatusId, PriorityId, EstimatedHours, StoryPoints, DueDate, CompletedAtUtc, CreatedByUserId, CreatedAtUtc, MetadataJson)
VALUES
    ( 1, 1, NULL, N'Design database schema',              6, 2, 24.00,  8, '2024-03-01', '2024-02-28T16:40:00', 4, '2024-02-05T09:00:00', N'{"epic":"foundation","reviewers":["grace","alan"]}'),
    ( 2, 1,    1, N'Draft ER diagram',                    6, 3,  6.00,  2, '2024-02-15', '2024-02-14T11:05:00', 7, '2024-02-05T09:10:00', NULL),
    ( 3, 1,    1, N'Write migration scripts',             6, 3, 10.00,  3, '2024-02-25', '2024-02-26T18:20:00', 8, '2024-02-06T10:00:00', NULL),
    ( 4, 1, NULL, N'Implement auth endpoints',            6, 1, 32.00, 13, '2024-04-15', '2024-04-18T09:30:00', 4, '2024-03-02T08:00:00', N'{"epic":"identity","risk":"high"}'),
    ( 5, 1, NULL, N'Add pagination to task list API',     3, 3, 12.00,  5, '2025-08-30', NULL,                  7, '2025-07-01T13:00:00', NULL),
    ( 6, 1, NULL, N'Fix N+1 query on project detail',     4, 2,  8.00,  3, '2025-09-05', NULL,                  8, '2025-07-15T15:30:00', N'{"epic":"performance","detected_by":"apm"}'),
    ( 7, 1, NULL, N'Introduce outbox pattern',            1, 4, 40.00, 21, NULL,         NULL,                  4, '2025-06-20T11:00:00', NULL),
    ( 8, 1, NULL, N'Upgrade to .NET 9',                   2, 3,  NULL, NULL, '2025-12-01', NULL,                4, '2025-08-01T09:15:00', NULL),
    ( 9, 2, NULL, N'Scaffold Angular workspace',          6, 2, 16.00,  5, '2024-03-10', '2024-03-08T14:00:00', 5, '2024-02-20T09:00:00', NULL),
    (10, 2, NULL, N'Build task board component',          6, 2, 40.00, 13, '2024-06-30', '2024-07-04T17:45:00',10, '2024-04-01T09:00:00', N'{"epic":"ui","a11y":true}'),
    (11, 2,   10, N'Drag & drop interaction',             6, 3, 14.00,  5, '2024-06-20', '2024-06-19T12:00:00',10, '2024-04-02T09:00:00', NULL),
    (12, 2,   10, N'Keyboard accessibility pass',         5, 2,  8.00,  3, '2025-07-31', NULL,                 11, '2024-04-02T09:05:00', N'{"blocked_by":"design-tokens"}'),
    (13, 2, NULL, N'Dark mode theme',                     3, 4, 12.00,  5, '2025-10-15', NULL,                 20, '2025-05-11T10:00:00', NULL),
    (14, 2, NULL, N'Optimise bundle size',                2, 3, 10.00,  3, NULL,         NULL,                 10, '2025-07-22T16:00:00', N'{"epic":"performance","budget_kb":250}'),
    (15, 3, NULL, N'Define reporting star schema',        6, 2, 20.00,  8, '2024-06-15', '2024-06-12T10:20:00',12, '2024-05-02T09:00:00', NULL),
    (16, 3, NULL, N'Build burndown chart query',          6, 3, 12.00,  5, '2024-07-30', '2024-08-02T11:00:00',12, '2024-06-01T09:00:00', NULL),
    (17, 3, NULL, N'Nightly ETL to warehouse',            3, 2, 30.00, 13, '2025-09-30', NULL,                 12, '2025-04-10T09:00:00', N'{"epic":"analytics","schedule":"0 2 * * *"}'),
    (18, 3, NULL, N'Cohort retention report',             1, 4,  NULL, NULL, NULL,       NULL,                  5, '2025-06-01T09:00:00', NULL),
    (19, 4, NULL, N'Threat model the API',                6, 1, 16.00,  8, '2024-07-01', '2024-06-28T15:00:00', 6, '2024-06-03T09:00:00', N'{"epic":"security","framework":"STRIDE"}'),
    (20, 4, NULL, N'Remove dynamic SQL from reports',     3, 1, 18.00,  8, '2025-08-15', NULL,                 13, '2025-06-15T09:00:00', N'{"epic":"security","cwe":"CWE-89"}'),
    (21, 4, NULL, N'Rotate all service credentials',      2, 2,  6.00,  2, '2025-09-20', NULL,                 13, '2025-07-30T09:00:00', NULL),
    (22, 4, NULL, N'Enable Always Encrypted on PII',      1, 2, 24.00, 13, NULL,         NULL,                  6, '2025-05-20T09:00:00', NULL),
    (23, 5, NULL, N'Set up Playwright harness',           6, 3, 14.00,  5, '2024-05-15', '2024-05-13T13:30:00',15, '2024-04-05T09:00:00', NULL),
    (24, 5, NULL, N'API contract tests',                  3, 3, 20.00,  8, '2025-09-10', NULL,                 16, '2025-06-25T09:00:00', NULL),
    (25, 5, NULL, N'Flaky test triage',                   5, 3,  NULL, NULL, '2025-08-01', NULL,                16, '2025-07-05T09:00:00', N'{"flake_rate":0.07}'),
    (26, 6, NULL, N'Evaluate MAUI vs React Native',       7, 3,  8.00,  3, '2024-09-01', NULL,                  5, '2024-08-05T09:00:00', NULL),
    (27, 6, NULL, N'Mobile design spike',                 7, 4, 12.00,  5, '2024-10-01', NULL,                  5, '2024-08-06T09:00:00', NULL),
    (28, 7, NULL, N'Vector search prototype',             3, 5, 24.00,  8, NULL,         NULL,                  3, '2025-03-01T09:00:00', N'{"epic":"research"}'),
    (29, 7, NULL, N'CRDT collaboration spike',            1, 5,  NULL, NULL, NULL,       NULL,                 14, '2025-04-15T09:00:00', NULL),
    (30, 7, NULL, N'Formal verification of scheduler',    1, 5, 60.00, 21, NULL,         NULL,                  3, '2025-02-01T09:00:00', NULL),
    (31, 8, NULL, N'Audit existing components',           3, 3, 16.00,  5, '2025-09-15', NULL,                 14, '2025-01-10T09:00:00', NULL),
    (32, 8, NULL, N'Publish token package',               2, 3, 10.00,  3, '2025-10-01', NULL,                 14, '2025-02-01T09:00:00', NULL),
    (33, 8, NULL, N'Write contribution guide',            1, 4,  4.00,  1, NULL,         NULL,                 14, '2025-02-05T09:00:00', NULL),
    (34, 1, NULL, N'Add rate limiting middleware',        2, 2,  8.00,  3, '2025-09-25', NULL,                  4, '2025-08-10T09:00:00', NULL),
    (35, 2, NULL, N'Fix timezone bug on due dates',       3, 1,  4.00,  2, '2025-08-20', NULL,                 11, '2025-08-05T09:00:00', N'{"epic":"bugfix","cwe":null}');
SET IDENTITY_INSERT app.Tasks OFF;
GO

/*-----------------------------------------------------------------------------
  9. Seed assignments, labels, comments, time entries
     Note: some tasks have NO assignee and some users have NO tasks — this is
     deliberate so LEFT/RIGHT/FULL joins produce visibly different results.
-----------------------------------------------------------------------------*/
INSERT INTO app.TaskAssignments (TaskId, UserId, AssignedOn, IsPrimary) VALUES
    ( 1,  4, '2024-02-05', 1), ( 2,  7, '2024-02-05', 1), ( 3,  8, '2024-02-06', 1),
    ( 4,  7, '2024-03-02', 1), ( 4,  8, '2024-03-02', 0), ( 5,  9, '2025-07-01', 1),
    ( 6,  8, '2025-07-15', 1), ( 6,  7, '2025-07-20', 0), ( 7,  4, '2025-06-20', 1),
    ( 9, 10, '2024-02-20', 1), (10, 10, '2024-04-01', 1), (10, 11, '2024-04-01', 0),
    (11, 10, '2024-04-02', 1), (12, 11, '2024-04-02', 1), (13, 20, '2025-05-11', 1),
    (14, 10, '2025-07-22', 1), (15, 12, '2024-05-02', 1), (16, 12, '2024-06-01', 1),
    (17, 12, '2025-04-10', 1), (19,  6, '2024-06-03', 1), (19, 13, '2024-06-03', 0),
    (20, 13, '2025-06-15', 1), (21, 13, '2025-07-30', 1), (23, 15, '2024-04-05', 1),
    (24, 16, '2025-06-25', 1), (25, 16, '2025-07-05', 1), (28, 14, '2025-03-01', 1),
    (31, 14, '2025-01-10', 1), (32, 14, '2025-02-01', 1), (35, 11, '2025-08-05', 1),
    (34, 19, '2025-08-10', 1);
-- Tasks 8, 18, 22, 26, 27, 29, 30, 33 are intentionally UNASSIGNED.
-- Users 1, 2, 3, 5, 17, 18 intentionally have NO task assignments.

INSERT INTO app.TaskLabels (TaskId, LabelId) VALUES
    ( 1, 2), ( 4, 2), ( 4, 4), ( 5, 2), ( 6, 1), ( 6, 5), ( 7, 3),
    ( 8, 3), (10, 2), (12, 1), (13, 2), (14, 5), (16, 2), (17, 2),
    (19, 4), (20, 4), (20, 3), (21, 4), (22, 4), (24, 2), (25, 1),
    (26, 8), (27, 8), (31, 3), (32, 2), (33, 6), (34, 5), (35, 1);
-- Labels 7 ('good-first-issue') is intentionally UNUSED.

INSERT INTO app.Comments (TaskId, AuthorUserId, ParentCommentId, Body, PostedAtUtc) VALUES
    ( 1,  2, NULL, N'Please keep the audit table append-only.',              '2024-02-06T10:00:00'),
    ( 1,  4,    1, N'Agreed — no FK, no updates.',                           '2024-02-06T10:22:00'),
    ( 4, 13, NULL, N'Use short-lived tokens and rotate signing keys.',       '2024-03-05T09:40:00'),
    ( 5,  4, NULL, N'Keyset pagination, not OFFSET — the table will grow.',  '2025-07-02T08:15:00'),
    ( 5,  9,    4, N'Makes sense, reworking the query now.',                 '2025-07-02T09:01:00'),
    ( 6,  4, NULL, N'Confirmed 400ms saved after batching the includes.',    '2025-07-18T14:10:00'),
    (12, 15, NULL, N'Blocked until the design tokens ship.',                 '2025-07-10T11:00:00'),
    (17,  5, NULL, N'Watch the nightly window — it overlaps with backups.',  '2025-04-12T16:30:00'),
    (20,  6, NULL, N'Every dynamic statement must be parameterised.',        '2025-06-16T09:00:00'),
    (20, 13,    9, N'Rewriting with sp_executesql and typed params.',        '2025-06-16T10:30:00'),
    (25, 15, NULL, N'Quarantine anything above 5% flake rate.',              '2025-07-06T12:00:00'),
    (35, 10, NULL, N'Store UTC, convert at the edge. Always.',               '2025-08-06T09:20:00');

INSERT INTO app.TimeEntries (TaskId, UserId, WorkDate, Hours, IsBillable, Notes) VALUES
    ( 1,  4, '2024-02-06',  6.00, 1, N'Schema draft'),
    ( 1,  4, '2024-02-07',  7.50, 1, N'Review with Grace'),
    ( 1,  4, '2024-02-08',  5.25, 1, NULL),
    ( 2,  7, '2024-02-12',  3.00, 1, NULL),
    ( 2,  7, '2024-02-13',  2.75, 1, N'ERD polish'),
    ( 3,  8, '2024-02-20',  4.00, 1, NULL),
    ( 3,  8, '2024-02-21',  6.50, 1, NULL),
    ( 4,  7, '2024-03-11',  8.00, 1, N'Token issuance'),
    ( 4,  7, '2024-03-12',  7.00, 1, NULL),
    ( 4,  8, '2024-03-13',  6.00, 1, N'Refresh flow'),
    ( 5,  9, '2025-07-03',  4.50, 1, NULL),
    ( 5,  9, '2025-07-04',  5.00, 1, N'Keyset rewrite'),
    ( 6,  8, '2025-07-16',  3.25, 1, NULL),
    ( 6,  8, '2025-07-17',  4.00, 1, N'Batched includes'),
    (10, 10, '2024-04-08',  7.00, 1, NULL),
    (10, 10, '2024-04-09',  8.00, 1, NULL),
    (10, 11, '2024-04-10',  6.50, 1, NULL),
    (12, 11, '2025-07-08',  3.00, 0, N'Non-billable spike'),
    (17, 12, '2025-04-15',  5.00, 1, NULL),
    (17, 12, '2025-04-16',  6.00, 1, N'Incremental load'),
    (19,  6, '2024-06-10',  8.00, 1, N'STRIDE workshop'),
    (20, 13, '2025-06-18',  7.25, 1, NULL),
    (20, 13, '2025-06-19',  6.75, 1, N'sp_executesql rewrite'),
    (23, 15, '2024-04-22',  6.00, 1, NULL),
    (24, 16, '2025-07-01',  4.00, 1, NULL),
    (24, 16, '2025-07-02',  5.50, 1, NULL),
    (28, 14, '2025-03-10',  8.00, 0, N'Research time'),
    (31, 14, '2025-01-20',  4.25, 1, NULL),
    (35, 11, '2025-08-07',  2.00, 1, N'Repro + fix');
GO

/*-----------------------------------------------------------------------------
  10. Verification
-----------------------------------------------------------------------------*/
PRINT '';
PRINT '=== TaskFlowDb created ===';

SELECT 'ref.TaskStatuses'   AS TableName, COUNT(*) AS RowCount FROM ref.TaskStatuses
UNION ALL SELECT 'ref.Priorities',        COUNT(*) FROM ref.Priorities
UNION ALL SELECT 'app.Users',             COUNT(*) FROM app.Users
UNION ALL SELECT 'app.Teams',             COUNT(*) FROM app.Teams
UNION ALL SELECT 'app.TeamMembers',       COUNT(*) FROM app.TeamMembers
UNION ALL SELECT 'app.Projects',          COUNT(*) FROM app.Projects
UNION ALL SELECT 'app.Labels',            COUNT(*) FROM app.Labels
UNION ALL SELECT 'app.Tasks',             COUNT(*) FROM app.Tasks
UNION ALL SELECT 'app.TaskAssignments',   COUNT(*) FROM app.TaskAssignments
UNION ALL SELECT 'app.TaskLabels',        COUNT(*) FROM app.TaskLabels
UNION ALL SELECT 'app.Comments',          COUNT(*) FROM app.Comments
UNION ALL SELECT 'app.TimeEntries',       COUNT(*) FROM app.TimeEntries
ORDER BY TableName;
GO

/*  Expected row counts
    ------------------------------------
    app.Comments        12
    app.Labels           8
    app.Projects         8
    app.Tasks           35
    app.TaskAssignments 31
    app.TaskLabels      28
    app.Teams            7
    app.TeamMembers     20
    app.TimeEntries     29
    app.Users           20
    ref.Priorities       5
    ref.TaskStatuses     7
*/
