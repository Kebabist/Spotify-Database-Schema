-- Schema section: database creation, core DDL, constraints, and ALTER TABLE demo.
IF DB_ID(N'SpotifyAcademyDB') IS NULL
BEGIN
    CREATE DATABASE SpotifyAcademyDB;
END;
GO

USE SpotifyAcademyDB;
GO

-- Drop database-scoped DDL trigger first to prevent it firing during clean-up drops
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_DatabaseSchemaAudit' AND parent_class = 0)
    DROP TRIGGER trg_DatabaseSchemaAudit ON DATABASE;
GO

DROP VIEW IF EXISTS dbo.vw_UserFriendActivity;
DROP VIEW IF EXISTS dbo.vw_UserPreferences;
DROP VIEW IF EXISTS dbo.vw_TrackRecommendations;
DROP VIEW IF EXISTS dbo.vw_PlaylistCreationPortal;
GO

DROP TRIGGER IF EXISTS dbo.trg_UserLikes_Audit;
DROP TRIGGER IF EXISTS dbo.trg_UserMessages_FriendsOnly;
DROP TRIGGER IF EXISTS dbo.trg_PlaylistCreationPortal_Insert;
GO

DROP PROCEDURE IF EXISTS dbo.usp_CreatePlaylist;
DROP PROCEDURE IF EXISTS dbo.usp_AddTrackToPlaylist;
DROP PROCEDURE IF EXISTS dbo.usp_SearchTracks;
DROP PROCEDURE IF EXISTS dbo.usp_TransferFunds;
DROP PROCEDURE IF EXISTS dbo.usp_BuyConcertTicket;
GO

DROP FUNCTION IF EXISTS dbo.fn_GetUserAge;
DROP FUNCTION IF EXISTS dbo.fn_GetGenreInterest;
DROP FUNCTION IF EXISTS dbo.fn_UserTopTracks;
DROP FUNCTION IF EXISTS dbo.fn_PlaylistSummary;
GO

DROP TABLE IF EXISTS dbo.PlaylistXmlArchive;
DROP TABLE IF EXISTS dbo.SchemaChangeLog;
DROP TABLE IF EXISTS dbo.AuditLog;
DROP TABLE IF EXISTS dbo.StageTrackImport;
DROP TABLE IF EXISTS dbo.UserMessages;
DROP TABLE IF EXISTS dbo.TrackLyrics;
DROP TABLE IF EXISTS dbo.UserComments;
DROP TABLE IF EXISTS dbo.Tickets;
DROP TABLE IF EXISTS dbo.Concerts;
DROP TABLE IF EXISTS dbo.Wallets;
DROP TABLE IF EXISTS dbo.UserRelationships;
DROP TABLE IF EXISTS dbo.Similarities;
DROP TABLE IF EXISTS dbo.UserPlayedSong;
DROP TABLE IF EXISTS dbo.Payments;
DROP TABLE IF EXISTS dbo.UserPackages;
DROP TABLE IF EXISTS dbo.PackageFeatures;
DROP TABLE IF EXISTS dbo.Features;
DROP TABLE IF EXISTS dbo.UserLikes;
DROP TABLE IF EXISTS dbo.UserFollows;
DROP TABLE IF EXISTS dbo.PlaylistTracks;
DROP TABLE IF EXISTS dbo.Playlists;
DROP TABLE IF EXISTS dbo.Tracks;
DROP TABLE IF EXISTS dbo.Albums;
DROP TABLE IF EXISTS dbo.Artists;
DROP TABLE IF EXISTS dbo.Packages;
DROP TABLE IF EXISTS dbo.Users;
GO

CREATE TABLE dbo.Users (
    UserID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Users_UserID DEFAULT NEWID(),
    DisplayName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(120) NOT NULL,
    PasswordHash NVARCHAR(200) NOT NULL,
    DateOfBirth DATE NULL,
    ProfileImage VARBINARY(MAX) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Users PRIMARY KEY (UserID),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);

CREATE TABLE dbo.Artists (
    ArtistID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Artists_ArtistID DEFAULT NEWID(),
    ArtistName NVARCHAR(100) NOT NULL,
    Genre NVARCHAR(50) NOT NULL,
    ProfileImage VARBINARY(MAX) NULL,
    CONSTRAINT PK_Artists PRIMARY KEY (ArtistID)
);

CREATE TABLE dbo.Albums (
    AlbumID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Albums_AlbumID DEFAULT NEWID(),
    ArtistID UNIQUEIDENTIFIER NOT NULL,
    AlbumName NVARCHAR(100) NOT NULL,
    ReleaseDate DATE NULL,
    CoverImage VARBINARY(MAX) NULL,
    CONSTRAINT PK_Albums PRIMARY KEY (AlbumID),
    CONSTRAINT FK_Albums_Artists FOREIGN KEY (ArtistID) REFERENCES dbo.Artists(ArtistID)
);

CREATE TABLE dbo.Tracks (
    TrackID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Tracks_TrackID DEFAULT NEWID(),
    AlbumID UNIQUEIDENTIFIER NOT NULL,
    TrackName NVARCHAR(100) NOT NULL,
    DurationSeconds INT NOT NULL,
    FilePath NVARCHAR(260) NULL,
    Region NVARCHAR(50) NULL,
    AgeRating NVARCHAR(10) NULL,
    PlaylistRestriction BIT NOT NULL CONSTRAINT DF_Tracks_PlaylistRestriction DEFAULT (0),
    MusicFile VARBINARY(MAX) NULL,
    CONSTRAINT PK_Tracks PRIMARY KEY (TrackID),
    CONSTRAINT FK_Tracks_Albums FOREIGN KEY (AlbumID) REFERENCES dbo.Albums(AlbumID),
    CONSTRAINT CK_Tracks_Duration CHECK (DurationSeconds > 0)
);

CREATE TABLE dbo.Playlists (
    PlaylistID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Playlists_PlaylistID DEFAULT NEWID(),
    UserID UNIQUEIDENTIFIER NOT NULL,
    PlaylistName NVARCHAR(100) NOT NULL,
    TotalDurationSeconds INT NOT NULL CONSTRAINT DF_Playlists_TotalDuration DEFAULT (0),
    CoverImage VARBINARY(MAX) NULL,
    PlaylistDescription NVARCHAR(MAX) NULL,
    Visibility NVARCHAR(10) NOT NULL CONSTRAINT DF_Playlists_Visibility DEFAULT (N'public'),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Playlists_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Playlists PRIMARY KEY (PlaylistID),
    CONSTRAINT FK_Playlists_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_Playlists_Visibility CHECK (Visibility IN (N'public', N'private'))
);

CREATE TABLE dbo.PlaylistTracks (
    PlaylistID UNIQUEIDENTIFIER NOT NULL,
    TrackID UNIQUEIDENTIFIER NOT NULL,
    TrackOrder INT NOT NULL,
    AddedAt DATETIME2(0) NOT NULL CONSTRAINT DF_PlaylistTracks_AddedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_PlaylistTracks PRIMARY KEY (PlaylistID, TrackID),
    CONSTRAINT FK_PlaylistTracks_Playlists FOREIGN KEY (PlaylistID) REFERENCES dbo.Playlists(PlaylistID),
    CONSTRAINT FK_PlaylistTracks_Tracks FOREIGN KEY (TrackID) REFERENCES dbo.Tracks(TrackID),
    CONSTRAINT CK_PlaylistTracks_Order CHECK (TrackOrder > 0)
);

CREATE TABLE dbo.UserFollows (
    UserID UNIQUEIDENTIFIER NOT NULL,
    ArtistID UNIQUEIDENTIFIER NOT NULL,
    FollowedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserFollows_FollowedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_UserFollows PRIMARY KEY (UserID, ArtistID),
    CONSTRAINT FK_UserFollows_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_UserFollows_Artists FOREIGN KEY (ArtistID) REFERENCES dbo.Artists(ArtistID)
);

CREATE TABLE dbo.UserLikes (
    UserID UNIQUEIDENTIFIER NOT NULL,
    ContentID UNIQUEIDENTIFIER NOT NULL,
    ContentType NVARCHAR(20) NOT NULL,
    LikedOn DATETIME2(0) NOT NULL CONSTRAINT DF_UserLikes_LikedOn DEFAULT SYSDATETIME(),
    CONSTRAINT PK_UserLikes PRIMARY KEY (UserID, ContentID, ContentType),
    CONSTRAINT FK_UserLikes_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_UserLikes_ContentType CHECK (ContentType IN (N'track', N'album', N'playlist'))
);

CREATE TABLE dbo.Features (
    FeatureID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Features_FeatureID DEFAULT NEWID(),
    FeatureName NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Features PRIMARY KEY (FeatureID),
    CONSTRAINT UQ_Features_Name UNIQUE (FeatureName)
);

CREATE TABLE dbo.Packages (
    PackageID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Packages_PackageID DEFAULT NEWID(),
    PackageName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    NumberOfAccounts INT NOT NULL,
    PackageDescription NVARCHAR(MAX) NULL,
    CONSTRAINT PK_Packages PRIMARY KEY (PackageID),
    CONSTRAINT CK_Packages_Price CHECK (Price >= 0),
    CONSTRAINT CK_Packages_Accounts CHECK (NumberOfAccounts > 0)
);

CREATE TABLE dbo.PackageFeatures (
    PackageID UNIQUEIDENTIFIER NOT NULL,
    FeatureID UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT PK_PackageFeatures PRIMARY KEY (PackageID, FeatureID),
    CONSTRAINT FK_PackageFeatures_Packages FOREIGN KEY (PackageID) REFERENCES dbo.Packages(PackageID),
    CONSTRAINT FK_PackageFeatures_Features FOREIGN KEY (FeatureID) REFERENCES dbo.Features(FeatureID)
);

CREATE TABLE dbo.UserPackages (
    UserID UNIQUEIDENTIFIER NOT NULL,
    PackageID UNIQUEIDENTIFIER NOT NULL,
    StartDate DATETIME2(0) NOT NULL,
    EndDate DATETIME2(0) NOT NULL,
    CONSTRAINT PK_UserPackages PRIMARY KEY (UserID, PackageID),
    CONSTRAINT FK_UserPackages_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_UserPackages_Packages FOREIGN KEY (PackageID) REFERENCES dbo.Packages(PackageID),
    CONSTRAINT CK_UserPackages_Dates CHECK (EndDate > StartDate)
);

CREATE TABLE dbo.Payments (
    PaymentID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Payments_PaymentID DEFAULT NEWID(),
    UserID UNIQUEIDENTIFIER NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL,
    PaymentDate DATETIME2(0) NOT NULL CONSTRAINT DF_Payments_PaymentDate DEFAULT SYSDATETIME(),
    Amount DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Payments PRIMARY KEY (PaymentID),
    CONSTRAINT FK_Payments_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_Payments_Amount CHECK (Amount >= 0)
);

CREATE TABLE dbo.UserPlayedSong (
    PlayID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_UserPlayedSong_PlayID DEFAULT NEWID(),
    UserID UNIQUEIDENTIFIER NOT NULL,
    TrackID UNIQUEIDENTIFIER NOT NULL,
    PlayDate DATETIME2(0) NOT NULL CONSTRAINT DF_UserPlayedSong_PlayDate DEFAULT SYSDATETIME(),
    CONSTRAINT PK_UserPlayedSong PRIMARY KEY (PlayID),
    CONSTRAINT FK_UserPlayedSong_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_UserPlayedSong_Tracks FOREIGN KEY (TrackID) REFERENCES dbo.Tracks(TrackID)
);

CREATE TABLE dbo.Similarities (
    UserID UNIQUEIDENTIFIER NOT NULL,
    TrackID UNIQUEIDENTIFIER NOT NULL,
    SimilarityScore FLOAT NOT NULL,
    CONSTRAINT PK_Similarities PRIMARY KEY (UserID, TrackID),
    CONSTRAINT FK_Similarities_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Similarities_Tracks FOREIGN KEY (TrackID) REFERENCES dbo.Tracks(TrackID),
    CONSTRAINT CK_Similarities_Score CHECK (SimilarityScore >= 0 AND SimilarityScore <= 1)
);

CREATE TABLE dbo.UserRelationships (
    UserID UNIQUEIDENTIFIER NOT NULL,
    RelatedUserID UNIQUEIDENTIFIER NOT NULL,
    RelationshipType NVARCHAR(20) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserRelationships_CreatedAt DEFAULT SYSDATETIME(),
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_UserRelationships_Status DEFAULT (N'pending'),
    CONSTRAINT PK_UserRelationships PRIMARY KEY (UserID, RelatedUserID, RelationshipType),
    CONSTRAINT FK_UserRelationships_User FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_UserRelationships_RelatedUser FOREIGN KEY (RelatedUserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_UserRelationships_Type CHECK (RelationshipType IN (N'friendship', N'follower')),
    CONSTRAINT CK_UserRelationships_Status CHECK (Status IN (N'pending', N'accepted', N'blocked', N'rejected'))
);

CREATE TABLE dbo.Wallets (
    WalletID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Wallets_WalletID DEFAULT NEWID(),
    UserID UNIQUEIDENTIFIER NOT NULL,
    Balance DECIMAL(10,2) NOT NULL CONSTRAINT DF_Wallets_Balance DEFAULT (0),
    CONSTRAINT PK_Wallets PRIMARY KEY (WalletID),
    CONSTRAINT UQ_Wallets_User UNIQUE (UserID),
    CONSTRAINT FK_Wallets_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID)
);

CREATE TABLE dbo.Concerts (
    ConcertID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Concerts_ConcertID DEFAULT NEWID(),
    ArtistID UNIQUEIDENTIFIER NOT NULL,
    ConcertName NVARCHAR(150) NOT NULL,
    ConcertDate DATETIME2(0) NOT NULL,
    Venue NVARCHAR(150) NOT NULL,
    TicketPrice DECIMAL(10,2) NOT NULL,
    ConcertImage VARBINARY(MAX) NULL,
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Concerts_Status DEFAULT (N'scheduled'),
    CONSTRAINT PK_Concerts PRIMARY KEY (ConcertID),
    CONSTRAINT FK_Concerts_Artists FOREIGN KEY (ArtistID) REFERENCES dbo.Artists(ArtistID),
    CONSTRAINT CK_Concerts_Status CHECK (Status IN (N'scheduled', N'cancelled'))
);

CREATE TABLE dbo.Tickets (
    TicketID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Tickets_TicketID DEFAULT NEWID(),
    ConcertID UNIQUEIDENTIFIER NOT NULL,
    UserID UNIQUEIDENTIFIER NOT NULL,
    PurchaseDate DATETIME2(0) NOT NULL CONSTRAINT DF_Tickets_PurchaseDate DEFAULT SYSDATETIME(),
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Tickets_Status DEFAULT (N'valid'),
    CONSTRAINT PK_Tickets PRIMARY KEY (TicketID),
    CONSTRAINT FK_Tickets_Concerts FOREIGN KEY (ConcertID) REFERENCES dbo.Concerts(ConcertID),
    CONSTRAINT FK_Tickets_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_Tickets_Status CHECK (Status IN (N'valid', N'used', N'refunded'))
);

CREATE TABLE dbo.UserComments (
    CommentID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_UserComments_CommentID DEFAULT NEWID(),
    UserID UNIQUEIDENTIFIER NOT NULL,
    ContentType NVARCHAR(20) NOT NULL,
    ContentID UNIQUEIDENTIFIER NOT NULL,
    CommentText NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserComments_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_UserComments PRIMARY KEY (CommentID),
    CONSTRAINT FK_UserComments_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_UserComments_ContentType CHECK (ContentType IN (N'track', N'album', N'playlist'))
);

CREATE TABLE dbo.TrackLyrics (
    TrackID UNIQUEIDENTIFIER NOT NULL,
    Lyrics NVARCHAR(MAX) NULL,
    CONSTRAINT PK_TrackLyrics PRIMARY KEY (TrackID),
    CONSTRAINT FK_TrackLyrics_Tracks FOREIGN KEY (TrackID) REFERENCES dbo.Tracks(TrackID)
);

CREATE TABLE dbo.UserMessages (
    MessageID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_UserMessages_MessageID DEFAULT NEWID(),
    SenderID UNIQUEIDENTIFIER NOT NULL,
    RecipientID UNIQUEIDENTIFIER NOT NULL,
    MessageText NVARCHAR(MAX) NOT NULL,
    SentAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserMessages_SentAt DEFAULT SYSDATETIME(),
    ReadAt DATETIME2(0) NULL,
    CONSTRAINT PK_UserMessages PRIMARY KEY (MessageID),
    CONSTRAINT FK_UserMessages_Sender FOREIGN KEY (SenderID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_UserMessages_Recipient FOREIGN KEY (RecipientID) REFERENCES dbo.Users(UserID)
);

CREATE TABLE dbo.AuditLog (
    AuditID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditLog PRIMARY KEY,
    EntityName NVARCHAR(100) NOT NULL,
    ActionName NVARCHAR(20) NOT NULL,
    Details NVARCHAR(MAX) NULL,
    ChangedAt DATETIME2(0) NOT NULL CONSTRAINT DF_AuditLog_ChangedAt DEFAULT SYSDATETIME(),
    ChangedBy SYSNAME NULL
);

CREATE TABLE dbo.SchemaChangeLog (
    LogID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SchemaChangeLog PRIMARY KEY,
    EventType NVARCHAR(100) NOT NULL,
    SchemaName NVARCHAR(100) NULL,
    ObjectName NVARCHAR(256) NULL,
    EventTime DATETIME2(0) NOT NULL CONSTRAINT DF_SchemaChangeLog_EventTime DEFAULT SYSDATETIME(),
    EventData XML NULL
);

CREATE TABLE dbo.PlaylistXmlArchive (
    ArchiveID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PlaylistXmlArchive PRIMARY KEY,
    PlaylistID UNIQUEIDENTIFIER NOT NULL,
    PlaylistData XML NOT NULL,
    ArchivedAt DATETIME2(0) NOT NULL CONSTRAINT DF_PlaylistXmlArchive_ArchivedAt DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.StageTrackImport (
    TrackName NVARCHAR(100) NULL,
    ArtistName NVARCHAR(100) NULL,
    AlbumName NVARCHAR(100) NULL,
    Genre NVARCHAR(50) NULL,
    Region NVARCHAR(50) NULL,
    DurationSeconds INT NULL
);
GO

-- ALTER TABLE — adding columns
ALTER TABLE dbo.Users ADD PhoneNumber NVARCHAR(25) NULL;
ALTER TABLE dbo.Users ADD TemporaryNote NVARCHAR(50) NULL;

-- ALTER TABLE — dropping columns
ALTER TABLE dbo.Users DROP COLUMN TemporaryNote;
GO

-- ALTER TABLE — modifying column data type
-- Widen PhoneNumber from NVARCHAR(25) to NVARCHAR(30) to demonstrate ALTER COLUMN
ALTER TABLE dbo.Users ALTER COLUMN PhoneNumber NVARCHAR(30) NULL;
GO

-- DDL: DROP TABLE — removing an entire table
-- Create a temporary demo table, then drop it to demonstrate DROP TABLE
CREATE TABLE dbo.DropTableDemo (
    DemoID INT NOT NULL PRIMARY KEY,
    DemoName NVARCHAR(50) NOT NULL
);
INSERT INTO dbo.DropTableDemo VALUES (1, N'Test row');
-- Verify it exists, then drop it
SELECT * FROM dbo.DropTableDemo;
DROP TABLE dbo.DropTableDemo;
GO
