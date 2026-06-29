-- Functions, views, and stored procedures section.
USE SpotifyAcademyDB;
GO

IF OBJECT_ID(N'dbo.fn_GetUserAge', N'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetUserAge;
GO
CREATE FUNCTION dbo.fn_GetUserAge (@DateOfBirth DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @DateOfBirth, CAST(GETDATE() AS DATE))
           - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @DateOfBirth, CAST(GETDATE() AS DATE)), @DateOfBirth) > CAST(GETDATE() AS DATE)
                  THEN 1 ELSE 0 END;
END;
GO

IF OBJECT_ID(N'dbo.fn_GetGenreInterest', N'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetGenreInterest;
GO
CREATE FUNCTION dbo.fn_GetGenreInterest (@UserID UNIQUEIDENTIFIER, @Genre NVARCHAR(50))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @LikeCount INT = 0;
    DECLARE @PlayCount INT = 0;

    SELECT @LikeCount = COUNT(*)
    FROM dbo.UserLikes ul
    INNER JOIN dbo.Tracks t ON ul.ContentID = t.TrackID AND ul.ContentType = N'track'
    INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
    INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
    WHERE ul.UserID = @UserID AND ar.Genre = @Genre;

    SELECT @PlayCount = COUNT(*)
    FROM dbo.UserPlayedSong ups
    INNER JOIN dbo.Tracks t ON ups.TrackID = t.TrackID
    INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
    INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
    WHERE ups.UserID = @UserID AND ar.Genre = @Genre;

    RETURN CAST((@LikeCount * 2.0 + @PlayCount) / 3.0 AS DECIMAL(10,2));
END;
GO

IF OBJECT_ID(N'dbo.fn_UserTopTracks', N'IF') IS NOT NULL DROP FUNCTION dbo.fn_UserTopTracks;
GO
CREATE FUNCTION dbo.fn_UserTopTracks (@UserID UNIQUEIDENTIFIER)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (10) t.TrackID, t.TrackName, COUNT(*) AS PlayCount
    FROM dbo.UserPlayedSong ups
    INNER JOIN dbo.Tracks t ON ups.TrackID = t.TrackID
    WHERE ups.UserID = @UserID
    GROUP BY t.TrackID, t.TrackName
    ORDER BY COUNT(*) DESC, t.TrackName ASC
);
GO

IF OBJECT_ID(N'dbo.fn_PlaylistSummary', N'TF') IS NOT NULL DROP FUNCTION dbo.fn_PlaylistSummary;
GO
CREATE FUNCTION dbo.fn_PlaylistSummary (@PlaylistID UNIQUEIDENTIFIER)
RETURNS @Summary TABLE
(
    PlaylistID UNIQUEIDENTIFIER,
    TrackCount INT,
    TotalDurationSeconds INT,
    AverageTrackLength DECIMAL(10,2)
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT pt.PlaylistID, COUNT(*), SUM(t.DurationSeconds), AVG(CAST(t.DurationSeconds AS DECIMAL(10,2)))
    FROM dbo.PlaylistTracks pt
    INNER JOIN dbo.Tracks t ON pt.TrackID = t.TrackID
    WHERE pt.PlaylistID = @PlaylistID
    GROUP BY pt.PlaylistID;
    RETURN;
END;
GO

CREATE OR ALTER VIEW dbo.vw_UserFriendActivity
AS
SELECT ur.UserID AS ViewingUserID, N'like' AS ActivityType, ul.UserID AS ActingUserID, ul.ContentType, ul.ContentID, ul.LikedOn AS ActivityTime
FROM dbo.UserRelationships ur
INNER JOIN dbo.UserLikes ul ON ur.RelatedUserID = ul.UserID
WHERE ur.RelationshipType = N'friendship' AND ur.Status = N'accepted'
UNION ALL
SELECT ur.UserID, N'comment', uc.UserID, uc.ContentType, uc.ContentID, uc.CreatedAt
FROM dbo.UserRelationships ur
INNER JOIN dbo.UserComments uc ON ur.RelatedUserID = uc.UserID
WHERE ur.RelationshipType = N'friendship' AND ur.Status = N'accepted';
GO

CREATE OR ALTER VIEW dbo.vw_UserPreferences
AS
WITH ContentDetails AS
(
    SELECT ul.UserID, ar.ArtistID, ar.Genre
    FROM dbo.UserLikes ul
    INNER JOIN dbo.Tracks t ON ul.ContentID = t.TrackID AND ul.ContentType = N'track'
    INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
    INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
    UNION ALL
    SELECT ul.UserID, ar.ArtistID, ar.Genre
    FROM dbo.UserLikes ul
    INNER JOIN dbo.Albums a ON ul.ContentID = a.AlbumID AND ul.ContentType = N'album'
    INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
)
SELECT UserID, ArtistID, Genre, COUNT(*) AS LikeCount
FROM ContentDetails
GROUP BY UserID, ArtistID, Genre;
GO

CREATE OR ALTER VIEW dbo.vw_TrackRecommendations
AS
SELECT u.UserID, t.TrackID, t.TrackName, ar.ArtistName, a.AlbumName,
       dbo.fn_GetGenreInterest(u.UserID, ar.Genre)
       * CASE WHEN EXISTS (SELECT 1 FROM dbo.UserLikes ul WHERE ul.UserID = u.UserID AND ul.ContentID = t.TrackID AND ul.ContentType = N'track') THEN 2 ELSE 1 END
       * CASE WHEN EXISTS (SELECT 1 FROM dbo.UserPlayedSong ups WHERE ups.UserID = u.UserID AND ups.TrackID = t.TrackID) THEN 1.5 ELSE 1 END AS RecommendationScore
FROM dbo.Users u
CROSS JOIN dbo.Tracks t
INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID;
GO

IF OBJECT_ID(N'dbo.usp_CreatePlaylist', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_CreatePlaylist;
GO
CREATE PROCEDURE dbo.usp_CreatePlaylist
    @UserID UNIQUEIDENTIFIER,
    @PlaylistName NVARCHAR(100),
    @Visibility NVARCHAR(10) = N'public',
    @PlaylistDescription NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Playlists (UserID, PlaylistName, Visibility, PlaylistDescription)
    VALUES (@UserID, @PlaylistName, @Visibility, @PlaylistDescription);
END;
GO

IF OBJECT_ID(N'dbo.usp_AddTrackToPlaylist', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_AddTrackToPlaylist;
GO
CREATE PROCEDURE dbo.usp_AddTrackToPlaylist
    @PlaylistID UNIQUEIDENTIFIER,
    @TrackID UNIQUEIDENTIFIER,
    @TrackOrder INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.PlaylistTracks (PlaylistID, TrackID, TrackOrder)
    VALUES (@PlaylistID, @TrackID, @TrackOrder);
END;
GO

IF OBJECT_ID(N'dbo.usp_SearchTracks', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_SearchTracks;
GO
CREATE PROCEDURE dbo.usp_SearchTracks
    @SearchTerm NVARCHAR(100),
    @ArtistName NVARCHAR(100) = NULL,
    @Genre NVARCHAR(50) = NULL,
    @Region NVARCHAR(50) = NULL,
    @AgeRating NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.TrackID, t.TrackName, ar.ArtistName, a.AlbumName, ar.Genre, t.Region, t.AgeRating
    FROM dbo.Tracks t
    INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
    INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
    WHERE (t.TrackName LIKE N'%' + @SearchTerm + N'%' OR ar.ArtistName LIKE N'%' + @SearchTerm + N'%' OR a.AlbumName LIKE N'%' + @SearchTerm + N'%')
      AND (@ArtistName IS NULL OR ar.ArtistName LIKE N'%' + @ArtistName + N'%')
      AND (@Genre IS NULL OR ar.Genre LIKE N'%' + @Genre + N'%')
      AND (@Region IS NULL OR t.Region LIKE N'%' + @Region + N'%')
      AND (@AgeRating IS NULL OR t.AgeRating = @AgeRating);
END;
GO

-- Transactional Stored Procedures 

-- Fund Transfer between user wallets
IF OBJECT_ID(N'dbo.usp_TransferFunds', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_TransferFunds;
GO
CREATE PROCEDURE dbo.usp_TransferFunds
    @SourceUserID UNIQUEIDENTIFIER,
    @DestUserID UNIQUEIDENTIFIER,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Deduct from sender
        UPDATE dbo.Wallets SET Balance = Balance - @Amount WHERE UserID = @SourceUserID;
        IF @@ROWCOUNT = 0 THROW 50002, N'Source wallet not found.', 1;

        -- Check if sender has enough balance
        IF (SELECT Balance FROM dbo.Wallets WHERE UserID = @SourceUserID) < 0
            THROW 50003, N'Insufficient funds.', 1;

        -- Add to receiver
        UPDATE dbo.Wallets SET Balance = Balance + @Amount WHERE UserID = @DestUserID;
        IF @@ROWCOUNT = 0 THROW 50004, N'Destination wallet not found.', 1;

        COMMIT TRANSACTION;
        PRINT N'Transfer successful.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Buy Concert Ticket (Transactional)
IF OBJECT_ID(N'dbo.usp_BuyConcertTicket', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_BuyConcertTicket;
GO
CREATE PROCEDURE dbo.usp_BuyConcertTicket
    @UserID UNIQUEIDENTIFIER,
    @ConcertID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Price DECIMAL(10,2);
    DECLARE @AdminUserID UNIQUEIDENTIFIER;

    SELECT @Price = TicketPrice FROM dbo.Concerts WHERE ConcertID = @ConcertID;
    
    -- Select destination admin wallet UserID
    SELECT TOP 1 @AdminUserID = UserID FROM dbo.Users WHERE Email LIKE '%admin%';
    
    -- Fallback to any other user if no admin exists
    IF @AdminUserID IS NULL
        SELECT TOP 1 @AdminUserID = UserID FROM dbo.Users WHERE UserID <> @UserID;

    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Pay for ticket
        EXEC dbo.usp_TransferFunds 
             @SourceUserID = @UserID, 
             @DestUserID = @AdminUserID, 
             @Amount = @Price;

        -- Issue ticket
        INSERT INTO dbo.Tickets (ConcertID, UserID, Status)
        VALUES (@ConcertID, @UserID, N'valid');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Demonstration of Calling Functions/Procedures 

--  Scalar Function
SELECT DisplayName, dbo.fn_GetUserAge(DateOfBirth) AS Age FROM dbo.Users;

--  Inline Table-Valued Function
SELECT * FROM dbo.fn_UserTopTracks((SELECT TOP 1 UserID FROM dbo.Users));

--  Multi-Statement Table-Valued Function
SELECT * FROM dbo.fn_PlaylistSummary((SELECT TOP 1 PlaylistID FROM dbo.Playlists));

-- Validating Views
SELECT * FROM dbo.vw_UserPreferences;
SELECT TOP 5 * FROM dbo.vw_TrackRecommendations ORDER BY RecommendationScore DESC;

GO

