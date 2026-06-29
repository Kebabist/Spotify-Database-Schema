--  Logins, Users, Roles & Permissions

USE SpotifyAcademyDB;
GO

-- Clean up database-level security objects first to make the script repeatable
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SpotifyAppUser')
BEGIN
    -- Safely drop memberships
    ALTER ROLE db_datareader DROP MEMBER SpotifyAppUser;
    ALTER ROLE db_datawriter DROP MEMBER SpotifyAppUser;
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SpotifyApiRole' AND type = 'R')
        ALTER ROLE SpotifyApiRole DROP MEMBER SpotifyAppUser;
    
    DROP USER SpotifyAppUser;
END;

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SpotifyApiRole' AND type = 'R')
    DROP ROLE SpotifyApiRole;
GO

USE master;
GO

-- Clean up server-level security objects
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'SpotifyStreamingServerRole' AND type = 'R')
BEGIN
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'SpotifySqlLogin')
        ALTER SERVER ROLE SpotifyStreamingServerRole DROP MEMBER SpotifySqlLogin;
    DROP SERVER ROLE SpotifyStreamingServerRole;
END;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'SpotifySqlLogin')
BEGIN
    ALTER SERVER ROLE securityadmin DROP MEMBER SpotifySqlLogin;
    DROP LOGIN SpotifySqlLogin;
END;
GO

-- SQL Server Authentication Login
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'SpotifySqlLogin')
    CREATE LOGIN SpotifySqlLogin
        WITH PASSWORD        = 'StrongP@ssw0rd!2026',
             CHECK_POLICY    = ON,
             CHECK_EXPIRATION= ON,
             DEFAULT_DATABASE= SpotifyAcademyDB;
GO

-- Windows Authentication Login (demo; adjust domain\user)
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'PCNAME-PC\Username')
    CREATE LOGIN [DOMAIN\SpotifyWinUser] FROM WINDOWS
        WITH DEFAULT_DATABASE = SpotifyAcademyDB;
GO

--  Custom Server Role 
IF NOT EXISTS (SELECT 1 FROM sys.server_principals
               WHERE name = N'SpotifyStreamingServerRole' AND type = 'R')
    CREATE SERVER ROLE SpotifyStreamingServerRole AUTHORIZATION [sa];
GO

-- Add SQL login to the custom server role
ALTER SERVER ROLE SpotifyStreamingServerRole ADD MEMBER SpotifySqlLogin;
GO

-- ── Server Role Assignments
-- sysadmin   : full server control
-- securityadmin: manage logins
-- serveradmin  : configure server-wide settings
-- setupadmin   : manage linked servers
-- processadmin : manage processes
-- diskadmin    : manage disk files
-- dbcreator    : create/alter/drop databases
-- bulkadmin    : run BULK INSERT
ALTER SERVER ROLE securityadmin ADD MEMBER SpotifySqlLogin;  
GO

USE SpotifyAcademyDB;
GO

-- Database User mapped to SQL Login 
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SpotifyAppUser')
    CREATE USER SpotifyAppUser FOR LOGIN SpotifySqlLogin;
GO

--  Custom Database Role 
IF NOT EXISTS (SELECT 1 FROM sys.database_principals
               WHERE name = N'SpotifyApiRole' AND type = 'R')
    CREATE ROLE SpotifyApiRole AUTHORIZATION dbo;
GO

-- Database Role Memberships 
-- db_owner          : full database control
-- db_datareader     : SELECT on all tables
-- db_datawriter     : INSERT/UPDATE/DELETE on all tables
-- db_ddladmin       : run DDL statements
-- db_backupoperator : back up the database
-- db_accessadmin    : add/remove db users
-- db_securityadmin  : manage role membership & object permissions
-- db_denydatareader : cannot SELECT any table
-- db_denydatawriter : cannot INSERT/UPDATE/DELETE any table
ALTER ROLE db_datareader ADD MEMBER SpotifyAppUser;
ALTER ROLE db_datawriter ADD MEMBER SpotifyAppUser;
ALTER ROLE SpotifyApiRole ADD MEMBER SpotifyAppUser;
GO

-- Object-Level Permissions
-- Grant DML + REFERENCES on Tracks table
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES
    ON dbo.Tracks TO SpotifyApiRole;
GO

-- Grant SELECT on additional tables
GRANT SELECT ON dbo.Users    TO SpotifyApiRole;
GRANT SELECT ON dbo.Albums   TO SpotifyApiRole;
GRANT SELECT ON dbo.Artists  TO SpotifyApiRole;
GO

-- GRANT EXECUTE WITH GRANT OPTION
IF OBJECT_ID('dbo.usp_SearchTracks', 'P') IS NULL
BEGIN
    EXEC('CREATE PROCEDURE dbo.usp_SearchTracks
              @SearchTerm NVARCHAR(200) = NULL
          AS
          BEGIN
              SELECT TrackID, TrackName FROM dbo.Tracks
              WHERE  (@SearchTerm IS NULL OR TrackName LIKE N''%'' + @SearchTerm + N''%'');
          END');
END;
GO

GRANT EXECUTE ON dbo.usp_SearchTracks TO SpotifyApiRole WITH GRANT OPTION;
GO

-- DENY with CASCADE
-- Prevents SpotifyApiRole (and any principal it granted rights to) from deleting rows in the Users table.
DENY DELETE ON dbo.Users TO SpotifyApiRole CASCADE;   -- CASCADE propagates the deny
GO

-- REVOKE 
-- Remove INSERT on UserComments that was previously granted.
IF OBJECT_ID('dbo.UserComments', 'U') IS NOT NULL
    REVOKE INSERT ON dbo.UserComments FROM SpotifyApiRole;
GO

-- DENY / REVOKE on individual columns
DENY  UPDATE ON dbo.Users (Email) TO SpotifyAppUser;
REVOKE SELECT ON dbo.Users (PasswordHash) FROM SpotifyApiRole;
GO

-- Verify effective permissions 
--Run as SpotifyAppUser to see what it can actually do:
EXECUTE AS USER = 'SpotifyAppUser';
SELECT * FROM fn_my_permissions('dbo.Tracks', 'OBJECT');
REVERT;
GO