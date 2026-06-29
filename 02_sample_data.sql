-- Sample Data & DML (INSERT, SELECT, UPDATE, DELETE)
USE SpotifyAcademyDB;
GO

-- INSERT INTO — Single and Partial Records 

-- Users (Demonstrating partial insert and default values)
-- ID is NEWID() by default, CreatedAt is current time
INSERT INTO dbo.Users (DisplayName, Email, PasswordHash, DateOfBirth)
VALUES 
(N'Ava Reed', N'ava@music.test', N'hash-ava', '1998-04-21'),
(N'Ben Cruz', N'ben@music.test', N'hash-ben', '1997-08-10'),
(N'Cara Stone', N'cara@music.test', N'hash-cara', '2000-01-15'),
(N'Diego Lane', N'diego@music.test', N'hash-diego', '1996-11-30'),
(N'Elena Moss', N'elena@music.test', N'hash-elena', '1995-02-14'),
(N'Finn Ward', N'finn@music.test', N'hash-ward', '1999-12-05'),
(N'Gina Park', N'gina@music.test', N'hash-gina', '2001-07-22'),
(N'Hans Holt', N'hans@music.test', N'hash-hans', '1994-03-30'),
(N'Iris Bell', N'iris@music.test', N'hash-iris', '1992-10-18'),
(N'Jack Ross', N'jack@music.test', N'hash-jack', '1993-06-12');

-- Capture IDs for later use in relationships
DECLARE @User1 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'ava@music.test');
DECLARE @User2 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'ben@music.test');
DECLARE @User3 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'cara@music.test');
DECLARE @User4 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'diego@music.test');
DECLARE @User5 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'elena@music.test');
DECLARE @User6 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'finn@music.test');
DECLARE @User7 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'gina@music.test');
DECLARE @User8 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'hans@music.test');
DECLARE @User9 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'iris@music.test');
DECLARE @User10 UNIQUEIDENTIFIER = (SELECT TOP 1 UserID FROM dbo.Users WHERE Email = N'jack@music.test');

-- Artists
INSERT INTO dbo.Artists (ArtistName, Genre)
VALUES 
(N'Neon Pulse', N'Pop'),
(N'Midnight Echo', N'Rock'),
(N'LoFi Harbor', N'LoFi'),
(N'Velvet Jazz', N'Jazz'),
(N'Synth Atlas', N'Electronic'),
(N'Oceanic', N'Ambient'),
(N'Urban Beat', N'Hip-Hop'),
(N'Steel Strings', N'Country');

DECLARE @Art1 UNIQUEIDENTIFIER = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = N'Neon Pulse');
DECLARE @Art2 UNIQUEIDENTIFIER = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = N'Midnight Echo');
DECLARE @Art3 UNIQUEIDENTIFIER = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = N'LoFi Harbor');
DECLARE @Art4 UNIQUEIDENTIFIER = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = N'Velvet Jazz');
DECLARE @Art5 UNIQUEIDENTIFIER = (SELECT TOP 1 ArtistID FROM dbo.Artists WHERE ArtistName = N'Synth Atlas');

-- Albums
INSERT INTO dbo.Albums (ArtistID, AlbumName, ReleaseDate)
VALUES 
(@Art1, N'Starlight City', '2024-05-12'),
(@Art1, N'Neon Dreams', '2023-11-01'),
(@Art2, N'After Midnight', '2023-10-01'),
(@Art3, N'Quiet Waves', '2024-01-20'),
(@Art4, N'Blue Note Sessions', '2022-08-15'),
(@Art2, N'Echo Chambers', '2021-04-10'),
(@Art3, N'Harbor Morning', '2023-06-30'),
(@Art4, N'Velvet Night', '2024-02-14');

DECLARE @Alb1 UNIQUEIDENTIFIER = (SELECT TOP 1 AlbumID FROM dbo.Albums WHERE AlbumName = N'Starlight City');
DECLARE @Alb2 UNIQUEIDENTIFIER = (SELECT TOP 1 AlbumID FROM dbo.Albums WHERE AlbumName = N'After Midnight');
DECLARE @Alb3 UNIQUEIDENTIFIER = (SELECT TOP 1 AlbumID FROM dbo.Albums WHERE AlbumName = N'Quiet Waves');

-- Tracks
INSERT INTO dbo.Tracks (AlbumID, TrackName, DurationSeconds, Region, AgeRating)
VALUES 
(@Alb1, N'City Lights', 214, N'Global', N'PG'),
(@Alb1, N'Late Train', 188, N'Global', N'PG'),
(@Alb1, N'Neon Sky', 205, N'Global', N'PG'),
(@Alb2, N'Broken Neon', 236, N'EU', N'PG-13'),
(@Alb2, N'Shadow Walk', 210, N'EU', N'PG-13'),
(@Alb3, N'Harbor Rain', 197, N'US', N'PG'),
(@Alb3, N'Mist', 180, N'US', N'PG'),
(@Alb3, N'Tide', 225, N'US', N'PG'),
(@Alb2, N'Dark Alley', 195, N'Global', N'R'),
(@Alb1, N'Sunrise Drive', 215, N'US', N'PG');

DECLARE @Trk1 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'City Lights');
DECLARE @Trk2 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Harbor Rain');
DECLARE @Trk3 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Broken Neon');
DECLARE @Trk4 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Neon Sky');
DECLARE @Trk5 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Shadow Walk');
DECLARE @Trk6 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Mist');
DECLARE @Trk7 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Tide');
DECLARE @Trk8 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Dark Alley');
DECLARE @Trk9 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Sunrise Drive');
DECLARE @Trk10 UNIQUEIDENTIFIER = (SELECT TOP 1 TrackID FROM dbo.Tracks WHERE TrackName = N'Late Train');

-- Playlists
INSERT INTO dbo.Playlists (UserID, PlaylistName, PlaylistDescription, Visibility)
VALUES 
(@User1, N'Morning Focus', N'Calm tracks for study and work', N'public'),
(@User2, N'Private Road Trip', N'Offline playlist for long drives', N'private'),
(@User3, N'Gym Mix', N'Energetic rock and pop', N'public'),
(@User4, N'Sleep Tight', N'Ambient and LoFi for resting', N'public'),
(@User1, N'Throwback', N'My favorite oldies', N'private');

DECLARE @Pl1 UNIQUEIDENTIFIER = (SELECT TOP 1 PlaylistID FROM dbo.Playlists WHERE PlaylistName = N'Morning Focus');

-- PlaylistTracks
INSERT INTO dbo.PlaylistTracks (PlaylistID, TrackID, TrackOrder)
VALUES 
(@Pl1, @Trk2, 1),
(@Pl1, @Trk1, 2),
(@Pl1, @Trk3, 3),
(@Pl1, @Trk4, 4),
(@Pl1, @Trk5, 5),
(@Pl1, @Trk6, 6);

-- Features & Packages (System data)
INSERT INTO dbo.Features (FeatureName) VALUES 
(N'Offline Mode'), 
(N'High Quality Audio'), 
(N'Family Sharing'), 
(N'Ad-Free'),
(N'Karaoke Mode');

DECLARE @Feat1 UNIQUEIDENTIFIER = (SELECT FeatureID FROM dbo.Features WHERE FeatureName = N'Offline Mode');
DECLARE @Feat2 UNIQUEIDENTIFIER = (SELECT FeatureID FROM dbo.Features WHERE FeatureName = N'High Quality Audio');
DECLARE @Feat3 UNIQUEIDENTIFIER = (SELECT FeatureID FROM dbo.Features WHERE FeatureName = N'Family Sharing');
DECLARE @Feat4 UNIQUEIDENTIFIER = (SELECT FeatureID FROM dbo.Features WHERE FeatureName = N'Ad-Free');
DECLARE @Feat5 UNIQUEIDENTIFIER = (SELECT FeatureID FROM dbo.Features WHERE FeatureName = N'Karaoke Mode');

INSERT INTO dbo.Packages (PackageName, Price, NumberOfAccounts, PackageDescription)
VALUES 
(N'Free', 0.00, 1, N'Ad-supported listening'),
(N'Premium', 9.99, 1, N'Ad-free personal streaming'),
(N'Family', 14.99, 6, N'Academic family subscription plan'),
(N'Student', 4.99, 1, N'Discounted premium for students'),
(N'Duo', 12.99, 2, N'Premium for two accounts');

DECLARE @PkgFree UNIQUEIDENTIFIER = (SELECT PackageID FROM dbo.Packages WHERE PackageName = N'Free');
DECLARE @PkgPrem UNIQUEIDENTIFIER = (SELECT PackageID FROM dbo.Packages WHERE PackageName = N'Premium');
DECLARE @PkgFam UNIQUEIDENTIFIER = (SELECT PackageID FROM dbo.Packages WHERE PackageName = N'Family');
DECLARE @PkgStud UNIQUEIDENTIFIER = (SELECT PackageID FROM dbo.Packages WHERE PackageName = N'Student');
DECLARE @PkgDuo UNIQUEIDENTIFIER = (SELECT PackageID FROM dbo.Packages WHERE PackageName = N'Duo');

-- PackageFeatures
INSERT INTO dbo.PackageFeatures (PackageID, FeatureID) VALUES
(@PkgPrem, @Feat1),
(@PkgPrem, @Feat2),
(@PkgPrem, @Feat4),
(@PkgFam, @Feat1),
(@PkgFam, @Feat3),
(@PkgFam, @Feat4),
(@PkgStud, @Feat2),
(@PkgDuo, @Feat1);

-- UserPackages
INSERT INTO dbo.UserPackages (UserID, PackageID, StartDate, EndDate) VALUES
(@User1, @PkgPrem, '2026-01-01', '2026-12-31'),
(@User2, @PkgFam, '2026-02-01', '2026-08-01'),
(@User3, @PkgStud, '2026-03-01', '2026-06-01'),
(@User4, @PkgDuo, '2026-04-01', '2026-10-01'),
(@User5, @PkgPrem, '2026-05-01', '2026-11-01');

-- Wallets (Initial balances)
INSERT INTO dbo.Wallets (UserID, Balance)
SELECT UserID, 100.00 FROM dbo.Users;

-- Payments 
INSERT INTO dbo.Payments (UserID, PaymentMethod, PaymentDate, Amount) VALUES
(@User1, N'Credit Card', '2026-01-01 08:30:00', 9.99),
(@User2, N'PayPal', '2026-02-01 09:15:00', 14.99),
(@User3, N'Gift Card', '2026-03-01 14:00:00', 4.99),
(@User4, N'Direct Debit', '2026-04-01 11:22:00', 12.99),
(@User5, N'Credit Card', '2026-05-01 17:45:00', 9.99);

-- User Relationships
INSERT INTO dbo.UserRelationships (UserID, RelatedUserID, RelationshipType, Status)
VALUES 
(@User1, @User2, N'friendship', N'accepted'),
(@User2, @User1, N'friendship', N'accepted'),
(@User3, @User1, N'follower', N'accepted'),
(@User4, @User1, N'friendship', N'pending'),
(@User5, @User6, N'friendship', N'accepted'),
(@User6, @User5, N'friendship', N'accepted');

-- UserFollows
INSERT INTO dbo.UserFollows (UserID, ArtistID) VALUES
(@User1, @Art1),
(@User2, @Art2),
(@User3, @Art3),
(@User4, @Art4),
(@User5, @Art5);

-- UserLikes
INSERT INTO dbo.UserLikes (UserID, ContentID, ContentType) VALUES
(@User1, @Trk1, N'track'),
(@User1, @Alb1, N'album'),
(@User2, @Trk2, N'track'),
(@User2, @Pl1, N'playlist'),
(@User3, @Trk3, N'track'),
(@User4, @Trk4, N'track'),
(@User5, @Trk5, N'track');

-- Similarities
INSERT INTO dbo.Similarities (UserID, TrackID, SimilarityScore) VALUES
(@User1, @Trk1, 0.95),
(@User2, @Trk2, 0.88),
(@User3, @Trk3, 0.76),
(@User4, @Trk4, 0.91),
(@User5, @Trk5, 0.82);

-- Concerts
INSERT INTO dbo.Concerts (ArtistID, ConcertName, ConcertDate, Venue, TicketPrice, Status) VALUES
(@Art1, N'Neon Pulse Live!', '2026-08-15 20:00:00', N'Madison Square Garden', 75.00, N'scheduled'),
(@Art2, N'Midnight Echo Acoustic', '2026-09-10 19:30:00', N'Red Rocks Amphitheatre', 60.00, N'scheduled'),
(@Art3, N'LoFi Harbor Session', '2026-10-05 18:00:00', N'The Bluebird Cafe', 25.00, N'scheduled'),
(@Art4, N'Velvet Jazz Night', '2026-11-20 21:00:00', N'The Jazz Standard', 40.00, N'scheduled'),
(@Art5, N'Synth Atlas Electronic Expo', '2026-12-05 22:00:00', N'Wembley Arena', 90.00, N'scheduled');

-- Get Concert IDs
DECLARE @Con1 UNIQUEIDENTIFIER = (SELECT ConcertID FROM dbo.Concerts WHERE ConcertName = N'Neon Pulse Live!');
DECLARE @Con2 UNIQUEIDENTIFIER = (SELECT ConcertID FROM dbo.Concerts WHERE ConcertName = N'Midnight Echo Acoustic');
DECLARE @Con3 UNIQUEIDENTIFIER = (SELECT ConcertID FROM dbo.Concerts WHERE ConcertName = N'LoFi Harbor Session');
DECLARE @Con4 UNIQUEIDENTIFIER = (SELECT ConcertID FROM dbo.Concerts WHERE ConcertName = N'Velvet Jazz Night');
DECLARE @Con5 UNIQUEIDENTIFIER = (SELECT ConcertID FROM dbo.Concerts WHERE ConcertName = N'Synth Atlas Electronic Expo');

-- Tickets
INSERT INTO dbo.Tickets (ConcertID, UserID, Status) VALUES
(@Con1, @User1, N'valid'),
(@Con2, @User2, N'valid'),
(@Con3, @User3, N'used'),
(@Con4, @User4, N'valid'),
(@Con5, @User5, N'refunded');

-- UserComments
INSERT INTO dbo.UserComments (UserID, ContentType, ContentID, CommentText) VALUES
(@User1, N'track', @Trk1, N'This beat is amazing!'),
(@User2, N'album', @Alb1, N'Solid album from start to finish.'),
(@User3, N'playlist', @Pl1, N'Great morning vibes, thanks for sharing.'),
(@User4, N'track', @Trk2, N'Love the lyrics here.'),
(@User5, N'track', @Trk3, N'Synth work is outstanding.');

-- TrackLyrics
INSERT INTO dbo.TrackLyrics (TrackID, Lyrics) VALUES
(@Trk1, N'Driving down the neon streets, heart skipping beats...'),
(@Trk2, N'Late night train, heading in the rain...'),
(@Trk3, N'Look up at the sky, see the stars go by...'),
(@Trk4, N'Broken lights, long summer nights...'),
(@Trk5, N'Shadows follow me, where I want to be...');

-- UserMessages
INSERT INTO dbo.UserMessages (SenderID, RecipientID, MessageText) VALUES
(@User1, @User2, N'Hey Ben, check out this new playlist!'),
(@User2, @User1, N'Thanks Ava, I will listen to it now.'),
(@User1, @User2, N'Let me know what you think.'),
(@User5, @User6, N'Hey Finn, going to the concert tonight?'),
(@User6, @User5, N'Yes, see you there!');

-- AuditLog
INSERT INTO dbo.AuditLog (EntityName, ActionName, Details, ChangedBy) VALUES
(N'System', N'INIT', N'Database sample data initialization starts.', SUSER_SNAME()),
(N'System', N'USERS', N'Sample users successfully loaded.', SUSER_SNAME()),
(N'System', N'ARTISTS', N'Sample artists successfully loaded.', SUSER_SNAME()),
(N'System', N'ALBUMS', N'Sample albums successfully loaded.', SUSER_SNAME()),
(N'System', N'TRACKS', N'Sample tracks successfully loaded.', SUSER_SNAME());

-- SchemaChangeLog
INSERT INTO dbo.SchemaChangeLog (EventType, SchemaName, ObjectName, EventData) VALUES
(N'CREATE_TABLE', N'dbo', N'Users', N'<event>Created Users Table</event>'),
(N'CREATE_TABLE', N'dbo', N'Artists', N'<event>Created Artists Table</event>'),
(N'CREATE_TABLE', N'dbo', N'Albums', N'<event>Created Albums Table</event>'),
(N'CREATE_TABLE', N'dbo', N'Tracks', N'<event>Created Tracks Table</event>'),
(N'CREATE_TABLE', N'dbo', N'Playlists', N'<event>Created Playlists Table</event>');

-- UserPlayedSong
INSERT INTO dbo.UserPlayedSong (UserID, TrackID, PlayDate)
VALUES 
(@User1, @Trk1, '2026-01-15 10:00:00'),
(@User1, @Trk2, '2026-01-16 10:05:00'),
(@User2, @Trk3, '2026-02-14 11:00:00'),
(@User3, @Trk1, '2026-02-15 12:00:00'),
(@User4, @Trk2, '2026-03-10 13:00:00'),
(@User5, @Trk4, '2026-03-11 14:00:00'),
(@User6, @Trk5, '2026-01-20 15:00:00'),
(@User7, @Trk6, '2026-02-20 16:00:00'),
(@User8, @Trk7, '2026-03-20 17:00:00'),
(@User9, @Trk8, '2026-01-25 18:00:00'),
(@User10, @Trk9, '2026-02-25 19:00:00'),
(@User1, @Trk10, '2026-03-25 20:00:00'),
(@User2, @Trk1, '2026-01-05 09:00:00'),
(@User3, @Trk2, '2026-02-05 10:00:00'),
(@User4, @Trk3, '2026-03-05 11:00:00');

-- SELECT — Wildcard and Basic Queries
SELECT * FROM dbo.Users;

-- SELECT specific columns and filtering
SELECT DisplayName, Email 
FROM dbo.Users 
WHERE DateOfBirth < '2000-01-01';

-- WHERE Clause — Filters & NULL Checks

-- Finding tracks with specific age rating
SELECT TrackName, AgeRating 
FROM dbo.Tracks 
WHERE AgeRating = N'PG-13';

-- Checking for NULLs (if any existed, e.g. tracks without region)
SELECT TrackName 
FROM dbo.Tracks 
WHERE Region IS NULL;

-- ORDER BY — Sorting

-- Sort users by birth date (Descending)
SELECT DisplayName, DateOfBirth 
FROM dbo.Users 
ORDER BY DateOfBirth DESC;

-- Sort tracks by duration (Ascending)
SELECT TrackName, DurationSeconds 
FROM dbo.Tracks 
ORDER BY DurationSeconds ASC;

-- UPDATE — Modifying Records
-- Update a user's phone number
UPDATE dbo.Users
SET PhoneNumber = N'+1-555-0101'
WHERE Email = N'ava@music.test';

-- Update balance after a purchase
UPDATE dbo.Wallets
SET Balance = Balance - 9.99
WHERE UserID = @User1;

-- DELETE — Removing Records

-- Add a dummy user then delete it to demonstrate DELETE usage
INSERT INTO dbo.Users (DisplayName, Email, PasswordHash)
VALUES (N'Delete Me', N'temp@music.test', N'junk');

-- Verify its existence
SELECT * FROM dbo.Users WHERE Email = N'temp@music.test';

-- Perform deletion
DELETE FROM dbo.Users WHERE Email = N'temp@music.test';

-- Verify it is gone
SELECT * FROM dbo.Users WHERE Email = N'temp@music.test';

GO
PRINT 'Section 2: Sample Data and DML Demo Completed.';
