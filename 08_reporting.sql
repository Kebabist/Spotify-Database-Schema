-- Reporting section: joins, set operators, CASE, aggregates, grouping, ranking, PIVOT, and advanced grouping.
USE SpotifyAcademyDB;
GO

SELECT u.DisplayName, p.PlaylistName
FROM dbo.Users AS u
INNER JOIN dbo.Playlists AS p ON p.UserID = u.UserID;

SELECT u.DisplayName, p.PlaylistName
FROM dbo.Users AS u
LEFT JOIN dbo.Playlists AS p ON p.UserID = u.UserID;

SELECT u.DisplayName, p.PlaylistName
FROM dbo.Users AS u
RIGHT JOIN dbo.Playlists AS p ON p.UserID = u.UserID;

SELECT u.DisplayName, p.PlaylistName
FROM dbo.Users AS u
FULL OUTER JOIN dbo.Playlists AS p ON p.UserID = u.UserID;
GO

SELECT ArtistName AS ItemName FROM dbo.Artists
UNION
SELECT AlbumName FROM dbo.Albums;

SELECT Genre FROM dbo.Artists
UNION ALL
SELECT Genre FROM dbo.Artists;

SELECT UserID FROM dbo.UserLikes WHERE ContentType = N'track'
INTERSECT
SELECT UserID FROM dbo.UserLikes WHERE ContentType = N'playlist';

SELECT UserID FROM dbo.UserLikes WHERE ContentType = N'track'
EXCEPT
SELECT UserID FROM dbo.UserLikes WHERE ContentType = N'playlist';
GO

SELECT TrackName,
       CASE AgeRating
           WHEN N'PG' THEN N'Family friendly'
           WHEN N'PG-13' THEN N'Teen oriented'
           ELSE N'Other'
       END AS RatingLabel
FROM dbo.Tracks;

SELECT TrackName,
       CASE
           WHEN DurationSeconds < 180 THEN N'Short'
           WHEN DurationSeconds BETWEEN 180 AND 240 THEN N'Medium'
           ELSE N'Long'
       END AS DurationClass
FROM dbo.Tracks;
GO

SELECT
    AVG(CAST(DurationSeconds AS DECIMAL(10,2))) AS AvgDuration,
    COUNT(*) AS TrackCount,
    SUM(DurationSeconds) AS TotalDuration,
    MAX(DurationSeconds) AS MaxDuration,
    MIN(DurationSeconds) AS MinDuration,
    COUNT(DISTINCT AlbumID) AS DistinctAlbumCount
FROM dbo.Tracks;

SELECT a.Genre, COUNT(*) AS ArtistCount
FROM dbo.Artists AS a
GROUP BY a.Genre
HAVING COUNT(*) >= 1;
GO

SELECT
    UPPER(DisplayName) AS UpperName,
    LOWER(DisplayName) AS LowerName,
    LEN(DisplayName) AS NameLength,
    LTRIM(RTRIM(DisplayName)) AS TrimmedName,
    TRIM(DisplayName) AS ModernTrim,
    SUBSTRING(DisplayName, 1, 3) AS NamePrefix,
    CHARINDEX(N' ', DisplayName) AS SpacePosition,
    PATINDEX(N'%e%', DisplayName) AS FirstEPosition,
    REPLACE(DisplayName, N' ', N'_') AS UnderscoredName,
    REPLICATE(N'*', 5) AS MaskExample,
    LEFT(DisplayName, 4) AS LeftPart,
    RIGHT(DisplayName, 4) AS RightPart,
    CONCAT(DisplayName, N' <', Email, N'>') AS ContactLabel,
    CONVERT(NVARCHAR(19), GETDATE(), 120) AS CurrentDateTime
FROM dbo.Users;
GO

SELECT
    TrackName,
    DurationSeconds,
    ROW_NUMBER() OVER (ORDER BY DurationSeconds DESC) AS RowNumberRanking,
    RANK() OVER (ORDER BY DurationSeconds DESC) AS RankWithGaps,
    DENSE_RANK() OVER (ORDER BY DurationSeconds DESC) AS DenseRankNoGaps,
    NTILE(4) OVER (ORDER BY DurationSeconds DESC) AS QuartileBucket
FROM dbo.Tracks;
GO

WITH GenreMonthlyPlays AS
(
    SELECT ar.Genre, DATENAME(MONTH, ups.PlayDate) AS PlayMonth, COUNT(*) AS PlayCount
    FROM dbo.UserPlayedSong ups
    INNER JOIN dbo.Tracks t ON ups.TrackID = t.TrackID
    INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
    INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
    GROUP BY ar.Genre, DATENAME(MONTH, ups.PlayDate)
)
SELECT Genre, [January], [February], [March]
FROM GenreMonthlyPlays
PIVOT (SUM(PlayCount) FOR PlayMonth IN ([January], [February], [March])) AS p;
GO

SELECT
    u.DisplayName,
    ups.PlayDate,
    t.TrackName,
    ROW_NUMBER() OVER (PARTITION BY u.UserID ORDER BY ups.PlayDate DESC) AS UserPlayRowNumber,
    RANK() OVER (ORDER BY ups.PlayDate DESC) AS GlobalPlayRank,
    DENSE_RANK() OVER (ORDER BY ups.PlayDate DESC) AS GlobalPlayDenseRank,
    SUM(t.DurationSeconds) OVER (PARTITION BY u.UserID ORDER BY ups.PlayDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningDuration,
    AVG(CAST(t.DurationSeconds AS DECIMAL(10,2))) OVER (PARTITION BY t.AlbumID) AS AlbumAverageTrackLength
FROM dbo.UserPlayedSong ups
INNER JOIN dbo.Users u ON ups.UserID = u.UserID
INNER JOIN dbo.Tracks t ON ups.TrackID = t.TrackID;
GO

SELECT ar.Genre, SUM(t.DurationSeconds) AS TotalGenreDuration, COUNT(*) AS PlayRows, GROUPING(ar.Genre) AS GenreGroupingFlag
FROM dbo.UserPlayedSong ups
INNER JOIN dbo.Tracks t ON ups.TrackID = t.TrackID
INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
GROUP BY GROUPING SETS ((ar.Genre), ());

SELECT ar.Genre, t.Region, COUNT(*) AS PlayCount, GROUPING(ar.Genre) AS GenreGroupingFlag, GROUPING(t.Region) AS RegionGroupingFlag
FROM dbo.UserPlayedSong ups
INNER JOIN dbo.Tracks t ON ups.TrackID = t.TrackID
INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
GROUP BY ROLLUP (ar.Genre, t.Region);

SELECT ar.Genre, t.Region, COUNT(*) AS PlayCount
FROM dbo.UserPlayedSong ups
INNER JOIN dbo.Tracks t ON ups.TrackID = t.TrackID
INNER JOIN dbo.Albums a ON t.AlbumID = a.AlbumID
INNER JOIN dbo.Artists ar ON a.ArtistID = ar.ArtistID
GROUP BY CUBE (ar.Genre, t.Region);
GO






-- RANGE vs ROWS

SELECT 
    TrackName, 
    DurationSeconds,
    -- ROWS
    SUM(DurationSeconds) OVER (
        ORDER BY DurationSeconds 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS TwoRowRunningSum,
    -- RANGE
    SUM(DurationSeconds) OVER (
        ORDER BY DurationSeconds 
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RangeBasedRunningSum
FROM dbo.Tracks;
GO



