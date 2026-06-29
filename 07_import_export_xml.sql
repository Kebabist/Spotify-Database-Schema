USE SpotifyAcademyDB;
GO

-- BULK INSERT from CSV
BULK INSERT dbo.StageTrackImport
FROM 'C:\Users\FFear\OneDrive\Desktop\40120453_Jafari Hombari\spotify_tracks.csv'
WITH (
    FORMAT           = 'CSV',
    FIELDQUOTE       = '"',
    FIRSTROW         = 2,            -- Skip header
    FIELDTERMINATOR  = ',',
    ROWTERMINATOR    = '\n',
    BATCHSIZE        = 100,
    CODEPAGE         = '65001'       -- UTF-8
);
GO

-- OPENROWSET
/*
 SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\Import\Tracks.xlsx',
    'SELECT * FROM [Sheet1$]');
*/
GO

-- Bulk Copy Program
--  Export command (DOS level):
-- bcp SpotifyAcademyDB.dbo.Tracks out "C:\Export\Tracks.dat" -c -T

--  enabling xp_cmdshell (Requires SysAdmin):
/*
 EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
 EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
*/
GO

-- XML Storage & Retrieval 

-- Insert XML data with attributes 
INSERT INTO dbo.PlaylistXmlArchive (PlaylistID, PlaylistData)
VALUES
(
    NEWID(),
    N'<playlist name="Morning Focus" genre="LoFi">
        <track name="City Lights" durationSeconds="214" />
        <track name="Harbor Rain" durationSeconds="197" />
      </playlist>'
),
(
    NEWID(),
    N'<playlist name="Gym Mix" genre="Rock">
        <track name="Broken Neon" durationSeconds="236" />
        <track name="Shadow Walk" durationSeconds="210" />
      </playlist>'
),
(
    NEWID(),
    N'<playlist name="Sleep Tight" genre="Ambient">
        <track name="Mist" durationSeconds="180" />
        <track name="Tide" durationSeconds="225" />
      </playlist>'
),
(
    NEWID(),
    N'<playlist name="Road Trip" genre="Pop">
        <track name="Sunrise Drive" durationSeconds="215" />
        <track name="Late Train" durationSeconds="188" />
      </playlist>'
),
(
    NEWID(),
    N'<playlist name="Classic Jazz" genre="Jazz">
        <track name="Blue Note Sessions" durationSeconds="300" />
      </playlist>'
);
GO

-- ── XQuery & FLWOR
-- Selecting attributes using .value() and .nodes()
SELECT
    PlaylistData.value('(/playlist/@name)[1]', 'NVARCHAR(100)') AS PlaylistName,
    T.c.value('@name', 'NVARCHAR(100)') AS TrackName,
    T.c.value('@durationSeconds', 'INT') AS Duration
FROM dbo.PlaylistXmlArchive
CROSS APPLY PlaylistData.nodes('/playlist/track') AS T(c);

-- FLWOR expression to filter within XML
SELECT
    PlaylistData.query('
        for $t in /playlist/track
        where xs:int($t/@durationSeconds) > 200
        return <long-track name="{data($t/@name)}" />
    ') AS FilteredXml
FROM dbo.PlaylistXmlArchive;

GO
