# Spotify Database Schema

An educational **Microsoft SQL Server** database project modeled after Spotify's core features. The schema covers user management, music content, social interactions, wallet payments, concert ticketing, and advanced SQL concepts — all organized into numbered, self-contained script files.

![Stupify](https://github.com/user-attachments/assets/47c18cdc-10f5-4933-8348-175ad6e9f9e3)

---

## Table of Contents

- [Features](#features)
- [Database: SpotifyAcademyDB](#database-spotifyacademydb)
- [Project Structure](#project-structure)
- [Schema Overview](#schema-overview)
- [Security Model](#security-model)
- [Functions & Stored Procedures](#functions--stored-procedures)
- [Triggers](#triggers)
- [Transactions & Concurrency](#transactions--concurrency)
- [Import / Export & XML](#import--export--xml)
- [Reporting & Analytics](#reporting--analytics)
- [Indexes](#indexes)
- [Getting Started](#getting-started)
- [Example Usage](#example-usage)
- [Notes](#notes)
- [License](#license)

---

## Features

- Full relational schema for users, artists, albums, tracks, and playlists
- Wallet system with fund transfers and subscription package support
- Concert ticketing with transactional ticket purchasing
- Social features: friendship requests, user messaging (friends-only enforcement), follows, likes, and comments
- Track play history and genre-interest scoring
- XML storage, XQuery filtering, and BULK INSERT import pipeline
- Role-based security: server roles, database roles, and granular object permissions
- Triggers for audit logging, schema change tracking, and business rule enforcement
- Advanced reporting: window functions, PIVOT, CTEs, grouping sets, and string aggregation
- Scalar, inline table-valued, and multi-statement table-valued functions
- Full demonstration of transaction modes, isolation levels, savepoints, and `XACT_STATE()`
- DDL lifecycle examples: `ALTER TABLE`, `DROP TABLE`, and database-scoped DDL trigger

---

## Database: SpotifyAcademyDB

All objects live in the `SpotifyAcademyDB` database under the `dbo` schema. The master runner (`00_master.sql`) executes all section scripts in order via SQLCMD mode.

---

## Project Structure

| File | Purpose |
|------|---------|
| `00_master.sql` | SQLCMD master runner — executes all sections in order |
| `01_schema.sql` | Database creation, all `CREATE TABLE` DDL, constraints, and `ALTER TABLE` demos |
| `02_sample_data.sql` | `INSERT` statements to populate every table with realistic seed data |
| `03_security.sql` | Logins, users, server/database roles, and object-level `GRANT`/`DENY`/`REVOKE` |
| `04_transactions.sql` | AutoCommit, implicit, explicit transactions; savepoints; isolation levels |
| `05_functions_and_procedures.sql` | Scalar/TVF/MSTVF functions, views, and stored procedures |
| `06_triggers.sql` | DML triggers (audit, friends-only messages, INSTEAD OF) and DDL trigger |
| `07_import_export_xml.sql` | `BULK INSERT`, `OPENROWSET`, `bcp`, XML insert, XQuery, FLWOR expressions |
| `08_reporting.sql` | Joins, set operators, aggregates, window functions, PIVOT, advanced grouping |
| `Stupify_Indexes.sql` | Index definitions for query performance optimization |

---

## Schema Overview

### Core Tables

| Table | Description |
|-------|-------------|
| `Users` | App users with email, password hash, date of birth, profile image, and phone number |
| `Artists` | Artist profiles with genre and image |
| `Albums` | Albums linked to artists with release date and cover image |
| `Tracks` | Individual tracks with duration, region, age rating, playlist restriction flag, and raw music file |
| `Playlists` | User-owned playlists with visibility (`public`/`private`), description, and auto-calculated total duration |
| `PlaylistTracks` | Many-to-many join with track ordering and add timestamp |
| `UserFollows` | User-to-artist follow relationships |
| `UserLikes` | Polymorphic likes for tracks, playlists, or albums via `ContentType` |
| `UserPlayedSong` | Play history per user and track with play date |
| `UserRelationships` | Friendship table with `RelationshipType` and `Status` (pending/accepted) |
| `UserMessages` | Direct messages between users (friends-only, enforced by trigger) |
| `TrackLyrics` | One-to-one lyrics storage per track |
| `Similarities` | User similarity scores for recommendation logic |

### Packages & Payments

| Table | Description |
|-------|-------------|
| `Packages` | Subscription plans (e.g., Free, Premium) |
| `Features` | Feature catalogue (e.g., offline mode, high quality) |
| `PackageFeatures` | Many-to-many linking packages to features |
| `UserPackages` | Active subscriptions per user |
| `Wallets` | Per-user wallet with balance |
| `Payments` | Payment records linked to users and packages |

### Concerts & Ticketing

| Table | Description |
|-------|-------------|
| `Concerts` | Concert details with venue, date, and ticket price |
| `Tickets` | Issued tickets with `valid`/`used`/`cancelled` status |

### Audit & Utility

| Table | Description |
|-------|-------------|
| `AuditLog` | General-purpose DML audit log (entity, action, details, caller) |
| `SchemaChangeLog` | DDL event log populated by the database-scoped trigger |
| `PlaylistXmlArchive` | XML-typed archive of playlist data |
| `StageTrackImport` | Staging table for CSV bulk import pipeline |

### Views

| View | Description |
|------|-------------|
| `vw_UserPreferences` | Aggregates liked genres and followed artists per user |
| `vw_TrackRecommendations` | Scores tracks by genre interest using `fn_GetGenreInterest` |
| `vw_UserFriendActivity` | Shows friend listening activity for a viewing user |
| `vw_PlaylistCreationPortal` | Updatable view over `Playlists` (backed by an INSTEAD OF INSERT trigger) |

---

## Security Model

Defined in `03_security.sql`:

- **SQL Login**: `SpotifySqlLogin` with password policy and expiration enabled
- **Windows Login**: `DOMAIN\SpotifyWinUser` (demo placeholder)
- **Custom Server Role**: `SpotifyStreamingServerRole` — also assigned to the `securityadmin` fixed server role
- **Database User**: `SpotifyAppUser` mapped to the SQL login
- **Custom Database Role**: `SpotifyApiRole` with:
  - `db_datareader` + `db_datawriter` membership
  - `SELECT/INSERT/UPDATE/DELETE/REFERENCES` on `Tracks`
  - `SELECT` on `Users`, `Albums`, `Artists`
  - `EXECUTE WITH GRANT OPTION` on `usp_SearchTracks`
  - `DENY DELETE … CASCADE` on `Users`
  - Column-level `DENY UPDATE` on `Users.Email` and `REVOKE SELECT` on `Users.PasswordHash`

---

## Functions & Stored Procedures

Defined in `05_functions_and_procedures.sql`:

### Scalar Functions

| Function | Parameters | Returns |
|----------|-----------|---------|
| `fn_GetUserAge` | `@DateOfBirth DATE` | Exact age as `INT`, leap-year safe |
| `fn_GetGenreInterest` | `@UserID`, `@Genre` | Weighted score `DECIMAL(10,2)` — likes × 2 + plays / 3 |

### Inline Table-Valued Function (TVF)

| Function | Parameters | Returns |
|----------|-----------|---------|
| `fn_UserTopTracks` | `@UserID` | Top 10 most-played tracks for the user |

### Multi-Statement Table-Valued Function (MSTVF)

| Function | Parameters | Returns |
|----------|-----------|---------|
| `fn_PlaylistSummary` | `@PlaylistID` | Track count, total duration, and average track length |

### Stored Procedures

| Procedure | Purpose |
|-----------|---------|
| `usp_CreatePlaylist` | Insert a new playlist for a user with optional visibility and description |
| `usp_AddTrackToPlaylist` | Add a track to an existing playlist with explicit ordering |
| `usp_SearchTracks` | Multi-filter search by name, artist, album, genre, region, and age rating |
| `usp_TransferFunds` | Atomic wallet-to-wallet balance transfer with full rollback on failure |
| `usp_BuyConcertTicket` | Purchase a concert ticket: delegates payment to `usp_TransferFunds`, then issues a ticket |

---

## Triggers

Defined in `06_triggers.sql`:

| Trigger | Type | Scope | Behavior |
|---------|------|-------|----------|
| `trg_UserLikes_Audit` | AFTER INSERT/UPDATE/DELETE | `UserLikes` | Writes all like changes to `AuditLog` with operation type and caller |
| `trg_UserMessages_FriendsOnly` | AFTER INSERT | `UserMessages` | Rolls back and throws error 50001 if users are not accepted friends |
| `trg_PlaylistCreationPortal_Insert` | INSTEAD OF INSERT | `vw_PlaylistCreationPortal` | Routes inserts through the view into the underlying `Playlists` table |
| `trg_DatabaseSchemaAudit` | DDL — DATABASE scope | CREATE/ALTER/DROP TABLE & PROCEDURE | Captures `EVENTDATA()` XML into `SchemaChangeLog` |

---

## Transactions & Concurrency

Demonstrated in `04_transactions.sql`:

- **AutoCommit** — default single-statement transaction mode
- **Implicit Transactions** — `SET IMPLICIT_TRANSACTIONS ON` with required explicit `COMMIT`
- **Explicit Transactions** — manual `BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK`
- **Savepoints** — `SAVE TRANSACTION` with selective rollback to a named point
- **`XACT_STATE()` checking** — `1` (committable), `-1` (uncommittable), `0` (no active transaction)
- **Isolation Levels**: `READ UNCOMMITTED`, `READ COMMITTED` (default), `REPEATABLE READ`, `SERIALIZABLE`, `SNAPSHOT`

---

## Import / Export & XML

Defined in `07_import_export_xml.sql`:

- **`BULK INSERT`** — loads `spotify_tracks.csv` into `StageTrackImport` with UTF-8 codepage, header skip, and batch sizing
- **`OPENROWSET`** — commented example for importing directly from an Excel file
- **`bcp`** — commented export command for dumping `Tracks` to a flat file
- **XML storage** — typed `XML` column in `PlaylistXmlArchive` with five sample playlists across genres (LoFi, Rock, Ambient, Pop, Jazz)
- **XQuery (`.value()` + `.nodes()`)** — shreds playlist names and per-track attributes into relational rows
- **FLWOR expressions** — filters tracks where `durationSeconds > 200` and returns transformed XML nodes

---

## Reporting & Analytics

Defined in `08_reporting.sql`:

- **Joins**: `INNER`, `LEFT`, `RIGHT`, `FULL OUTER`
- **Set Operators**: `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT`
- **`CASE` expressions**: simple and searched form for age rating labels and duration classification (Short / Medium / Long)
- **Aggregate Functions**: `AVG`, `COUNT`, `SUM`, `MAX`, `MIN`, `COUNT(DISTINCT …)`
- **String Functions**: `UPPER`, `LOWER`, `LEN`, `TRIM`, `SUBSTRING`, `CHARINDEX`, `PATINDEX`, `REPLACE`, `REPLICATE`, `CONCAT`
- **Window Functions**: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE()`, running `SUM() OVER (PARTITION BY …)`, `LAG()`, `LEAD()`, `FIRST_VALUE()`, `LAST_VALUE()`
- **`PIVOT`**: genre play counts pivoted by calendar month (January – March)
- **`GROUPING SETS` / `ROLLUP` / `CUBE`**: multi-dimensional aggregation across artist and album dimensions
- **`STRING_AGG`**: comma-separated track name lists per album

---

## Indexes

Defined in `Stupify_Indexes.sql`. Indexes are applied to high-frequency query columns across core tables to reduce I/O cost and accelerate the reporting and function queries.

---

## Getting Started

### Prerequisites

- **Microsoft SQL Server** 2016 or later (Express, Developer, or Standard edition)
- **SQL Server Management Studio (SSMS)** with SQLCMD mode enabled, or Azure Data Studio

> No external extensions are required. UUID/GUID generation uses the built-in `NEWID()` function.

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Kebabist/Spotify-Database-Schema.git
   cd Spotify-Database-Schema
   ```

2. **Option A — Run all at once (SQLCMD mode in SSMS):**
   - Open `00_master.sql` in SSMS
   - Update the `:setvar path` variable at the top to your local folder path
   - Enable SQLCMD Mode: **Query → SQLCMD Mode**
   - Execute (`F5`)

3. **Option B — Run files individually in numbered order:**
   ```
   01_schema.sql
   02_sample_data.sql
   03_security.sql
   04_transactions.sql
   05_functions_and_procedures.sql
   06_triggers.sql
   07_import_export_xml.sql
   08_reporting.sql
   Stupify_Indexes.sql
   ```

4. Verify setup:
   ```sql
   SELECT name FROM sys.databases WHERE name = 'SpotifyAcademyDB';
   USE SpotifyAcademyDB;
   SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
   ```

---

## Example Usage

### Search for Tracks
```sql
EXEC dbo.usp_SearchTracks
    @SearchTerm = 'love',
    @Genre      = 'Pop',
    @Region     = 'US';
```

### Create a Playlist
```sql
EXEC dbo.usp_CreatePlaylist
    @UserID              = '<user-guid>',
    @PlaylistName        = 'Evening Chill',
    @Visibility          = 'private',
    @PlaylistDescription = 'Low BPM tracks for winding down';
```

### Add a Track to a Playlist
```sql
EXEC dbo.usp_AddTrackToPlaylist
    @PlaylistID = '<playlist-guid>',
    @TrackID    = '<track-guid>',
    @TrackOrder = 1;
```

### Transfer Wallet Funds
```sql
EXEC dbo.usp_TransferFunds
    @SourceUserID = '<sender-guid>',
    @DestUserID   = '<receiver-guid>',
    @Amount       = 15.00;
```

### Buy a Concert Ticket
```sql
EXEC dbo.usp_BuyConcertTicket
    @UserID    = '<user-guid>',
    @ConcertID = '<concert-guid>';
```

### Get a User's Top Tracks
```sql
SELECT * FROM dbo.fn_UserTopTracks('<user-guid>');
```

### Get a Playlist Summary
```sql
SELECT * FROM dbo.fn_PlaylistSummary('<playlist-guid>');
```

### Check Genre Interest Score
```sql
SELECT dbo.fn_GetGenreInterest('<user-guid>', 'Jazz') AS InterestScore;
```

### View Friend Activity
```sql
SELECT *
FROM dbo.vw_UserFriendActivity
WHERE viewing_user_id = '<user-guid>';
```

### View Track Recommendations
```sql
SELECT TOP 10 *
FROM dbo.vw_TrackRecommendations
ORDER BY RecommendationScore DESC;
```

---

## Notes

- All primary keys use `UNIQUEIDENTIFIER` with `NEWID()` as the default — no identity columns on core entities.
- `trg_UserMessages_FriendsOnly` enforces friendship-only messaging at the database layer, independent of application logic.
- `usp_BuyConcertTicket` calls `usp_TransferFunds` internally, demonstrating nested transactional stored procedure composition.
- `trg_DatabaseSchemaAudit` is a **database-scoped DDL trigger** — it has no `dbo.` prefix and is dropped with `DROP TRIGGER … ON DATABASE`.
- The file paths in `07_import_export_xml.sql` (`C:\Users\FFear\...`) are local placeholders — update them to match your environment before running BULK INSERT.
- The Windows login in `03_security.sql` (`DOMAIN\SpotifyWinUser`) is a placeholder — replace with a valid Windows account before executing.

---

## License

This project is for **educational purposes only** and is not affiliated with or endorsed by Spotify AB.
