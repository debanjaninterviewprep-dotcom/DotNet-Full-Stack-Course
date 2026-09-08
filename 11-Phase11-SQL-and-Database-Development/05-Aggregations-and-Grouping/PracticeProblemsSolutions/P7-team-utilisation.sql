/*=============================================================================
  Topic 05 — Aggregations & Grouping
  P7 — Team Utilisation Report                                        (Hard)
  -----------------------------------------------------------------------------
  Tags: multi-level-aggregation | string-agg | fan-out | having | nulls

  PROBLEM
  -------
  One row per team — all 7 teams, including "Design System" which has no
  members — with:

    TeamName, Department   from app.Teams
    LeadName               FullName of the lead, or '(no lead)'
    MemberCount            distinct users in app.TeamMembers
    MemberList             comma-separated FullNames, alphabetical
    ProjectCount           projects owned by the team
    TaskCount              tasks across those projects
    OpenTaskCount          non-terminal tasks
    LoggedHours            hours logged BY TEAM MEMBERS on those tasks, 0 if none
    BilledValue            SUM(Hours * HourlyRate) for billable entries only,
                           0 if none
    AvgHourlyRate          average rate of members who have one, 4 dp, NULL-safe

  Then a second statement filtering to teams whose OpenTaskCount exceeds
  their MemberCount, with a comment justifying HAVING vs an outer filter.

  RULES
  -----
  - Absolutely no row multiplication. Pre-aggregate every child to the right
    grain before joining. Grains in play: team -> project -> task -> time entry.
  - Ken Thompson (UserId 7) belongs to two teams. Confirm MemberCount handles
    that and say in a comment what "correctly" means here.
  - Sophie Wilson (UserId 19) has a NULL HourlyRate. Document how she affects
    AvgHourlyRate and BilledValue.
  - No SELECT DISTINCT.

  EXPECTED
  --------
  Exactly 7 rows.
  "Design System" present with MemberCount 0, MemberList NULL,
  LeadName '(no lead)'.
  "Platform" shows 5 members with a correctly sorted MemberList.
  Total LoggedHours across all teams is LESS than 160.00 — work out why
  before assuming you have a bug.
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- Part 1: the utilisation report
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Part 2: teams where OpenTaskCount > MemberCount, plus the justification
-------------------------------------------------------------------------------

-- TODO: your solution here
