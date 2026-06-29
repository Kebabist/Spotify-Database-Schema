-- Trigger section.
USE SpotifyAcademyDB;
GO

IF OBJECT_ID(N'dbo.trg_UserLikes_Audit', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_UserLikes_Audit;
GO
CREATE TRIGGER dbo.trg_UserLikes_Audit
ON dbo.UserLikes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.AuditLog (EntityName, ActionName, Details, ChangedBy)
    SELECT N'UserLikes',
           CASE
               WHEN i.UserID IS NOT NULL AND d.UserID IS NULL THEN N'INSERT'
               WHEN i.UserID IS NOT NULL AND d.UserID IS NOT NULL THEN N'UPDATE'
               WHEN i.UserID IS NULL AND d.UserID IS NOT NULL THEN N'DELETE'
           END,
           CONCAT(N'UserID=', COALESCE(CONVERT(NVARCHAR(36), i.UserID), CONVERT(NVARCHAR(36), d.UserID)),
                  N'; ContentType=', COALESCE(i.ContentType, d.ContentType),
                  N'; ContentID=', COALESCE(CONVERT(NVARCHAR(36), i.ContentID), CONVERT(NVARCHAR(36), d.ContentID))),
           SUSER_SNAME()
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON i.UserID = d.UserID AND i.ContentID = d.ContentID AND i.ContentType = d.ContentType;
END;
GO

IF OBJECT_ID(N'dbo.trg_UserMessages_FriendsOnly', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_UserMessages_FriendsOnly;
GO
CREATE TRIGGER dbo.trg_UserMessages_FriendsOnly
ON dbo.UserMessages
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.UserRelationships ur
            WHERE ((ur.UserID = i.SenderID AND ur.RelatedUserID = i.RecipientID)
                OR (ur.UserID = i.RecipientID AND ur.RelatedUserID = i.SenderID))
              AND ur.RelationshipType = N'friendship'
              AND ur.Status = N'accepted'
        )
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, N'Users must be friends to send messages.', 1;
    END;
END;
GO

CREATE OR ALTER VIEW dbo.vw_PlaylistCreationPortal
AS
SELECT PlaylistID, UserID, PlaylistName, PlaylistDescription, Visibility
FROM dbo.Playlists;
GO

IF OBJECT_ID(N'dbo.trg_PlaylistCreationPortal_Insert', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_PlaylistCreationPortal_Insert;
GO
CREATE TRIGGER dbo.trg_PlaylistCreationPortal_Insert
ON dbo.vw_PlaylistCreationPortal
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Playlists (UserID, PlaylistName, PlaylistDescription, Visibility)
    SELECT UserID, PlaylistName, PlaylistDescription, COALESCE(Visibility, N'public')
    FROM inserted;
END;
GO

--  Drop check: remove dbo. prefix, use 'TR' type for DML but DDL triggers
--    use a different OBJECT_ID class. Use sys.triggers instead. 
IF EXISTS (
    SELECT 1 FROM sys.triggers
    WHERE name  = N'trg_DatabaseSchemaAudit'
      AND parent_class = 0           -- 0 = DATABASE scope, not a table
)
    DROP TRIGGER trg_DatabaseSchemaAudit ON DATABASE;  -- must specify ON DATABASE
GO

--  no schema prefix, scope declared via ON DATABASE 
CREATE TRIGGER trg_DatabaseSchemaAudit        --  no dbo. prefix
ON DATABASE                                   -- scope is the database
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE,
    CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.SchemaChangeLog (EventType, SchemaName, ObjectName, EventData)
    SELECT
        EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]',    'NVARCHAR(100)'),
        EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]',   'NVARCHAR(100)'),
        EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]',   'NVARCHAR(256)'),
        EVENTDATA();
END;
GO
