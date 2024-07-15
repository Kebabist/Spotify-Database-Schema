-- Creating a view named user_friend_activity to consolidate activities (likes and comments) of friends
CREATE VIEW user_friend_activity AS
SELECT 
    ur.user_id AS viewing_user_id, -- The ID of the user viewing the activity
    'like' AS activity_type, -- Static value to indicate the type of activity is a 'like'
    ul.user_id AS acting_user_id, -- The ID of the user who performed the 'like' activity
    ul.content_type, -- The type of content that was liked (e.g., post, photo)
    ul.content_id, -- The ID of the content that was liked
    ul.liked_on AS activity_time -- The timestamp when the 'like' activity occurred
FROM 
    user_relationships ur -- Joining with the user_relationships table to filter activities among friends
JOIN user_likes ul ON ur.related_user_id = ul.user_id -- Joining with the user_likes table to get like activities
WHERE 
    ur.relationship_type = 'friendship'  -- Filtering for relationships that are friendships
    AND ur.status = 'accepted' -- Ensuring only accepted friendships are considered

UNION ALL -- Combining results with another set of activities (comments)

SELECT 
    ur.user_id AS viewing_user_id, -- The ID of the user viewing the activity
    'comment' AS activity_type, -- Static value to indicate the type of activity is a 'comment'
    uc.user_id AS acting_user_id, -- The ID of the user who made the comment
    uc.content_type, -- The type of content that was commented on
    uc.content_id, -- The ID of the content that received the comment
    uc.created_at AS activity_time -- The timestamp when the comment was made
FROM 
    user_relationships ur -- Joining with the user_relationships table to filter activities among friends
JOIN user_comments uc ON ur.related_user_id = uc.user_id -- Joining with the user_comments table to get comment activities
WHERE 
    ur.relationship_type = 'friendship'  -- Filtering for relationships that are friendships
    AND ur.status = 'accepted' -- Ensuring only accepted friendships are considered

ORDER BY 
    activity_time DESC; -- Ordering the results by activity time in descending order, showing the most recent first

-- Usage example: Retrieve the latest 50 activities (likes and comments) of friends for a specific user
--SELECT * FROM user_friend_activity 
--WHERE viewing_user_id = 'specific_user_uuid_here' 
--LIMIT 50;



-- Create a view named user_preferences to summarize user preferences based on their likes
CREATE VIEW user_preferences AS
WITH ContentDetails AS (
    -- The CTE ContentDetails aggregates information about user likes, artist IDs, and genres
    SELECT 
        ul.user_id, -- Select the user ID from user_likes
        ul.content_type, -- Include the content type to differentiate between tracks and albums
        -- Determine the artist ID based on whether the liked content is a track or an album
        CASE 
            WHEN ul.content_type = 'track' THEN al.artist_id -- For tracks, link through the albums table
            WHEN ul.content_type = 'album' THEN al.artist_id -- Directly use album's artist ID for albums
        END as artist_id,
        -- Determine the genre based on the artist of the track or album
        CASE 
            WHEN ul.content_type = 'track' THEN ar.genre
            WHEN ul.content_type = 'album' THEN ar.genre
        END as genre
    FROM 
        user_likes ul -- Start with the user_likes table to get user preferences
    LEFT JOIN tracks t ON ul.content_type = 'track' AND ul.content_id = t.track_id -- Join with tracks if the content type is a track
    LEFT JOIN albums al ON (ul.content_type = 'album' AND ul.content_id = al.album_id) 
        OR (ul.content_type = 'track' AND t.album_id = al.album_id) -- Join with albums for both tracks and albums
    LEFT JOIN artists ar ON ar.artist_id = al.artist_id -- Join with artists to get the genre and artist ID
    WHERE 
        ul.content_type IN ('track', 'album') -- Filter likes to only include tracks and albums
)
-- Select from the CTE to aggregate likes by user, artist, and genre
SELECT 
    user_id,
    artist_id,
    genre,
    COUNT(*) as like_count -- Count the number of likes for each combination of user, artist, and genre
FROM 
    ContentDetails
GROUP BY 
    user_id, artist_id, genre; -- Group the results by user, artist, and genre to ensure unique rows

--recommendation system
CREATE OR REPLACE VIEW track_recommendations AS
WITH user_genre_interests AS (
    SELECT DISTINCT
        u.user_id,
        ar.genre,
        calculate_genre_interest(u.user_id, ar.genre) AS interest_score
    FROM 
        users u
        CROSS JOIN artists ar
    -- Calculate interest scores for each user and genre
)
SELECT 
    u.user_id,
    t.track_id,
    t.name AS track_name,
    ar.name AS artist_name,
    al.name AS album_name,
    ugi.interest_score * 
    (CASE 
        WHEN ul.user_id IS NOT NULL THEN 2  -- Double score if the user has liked the track
        ELSE 1
    END) *
    (CASE
        WHEN ups.user_id IS NOT NULL THEN 1.5  -- Increase score by 50% if the user has previously played the track
        ELSE 1
    END) AS recommendation_score
FROM 
    users u
    CROSS JOIN tracks t
    JOIN albums al ON t.album_id = al.album_id
    JOIN artists ar ON al.artist_id = ar.artist_id
    JOIN user_genre_interests ugi ON u.user_id = ugi.user_id AND ar.genre = ugi.genre
    LEFT JOIN user_likes ul ON u.user_id = ul.user_id AND t.track_id = ul.content_id AND ul.content_type = 'track'
    LEFT JOIN user_played_song ups ON u.user_id = ups.user_id AND t.track_id = ups.track_id
-- Generate recommendations based on user genre interests, likes, and play history
ORDER BY 
    u.user_id, recommendation_score DESC;