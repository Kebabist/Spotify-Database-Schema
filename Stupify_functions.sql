-- Define a function to manage friendship requests between users
CREATE OR REPLACE FUNCTION manage_friendship_request(
    sender_id UUID, -- The ID of the user sending the request
    recipient_id UUID, -- The ID of the user receiving the request
    action VARCHAR -- The action to be performed ('send', 'accept', or 'reject')
) RETURNS VOID AS $$
BEGIN
    -- Use a CASE statement to handle different actions
    CASE action
        WHEN 'send' THEN
            -- Insert a new friendship request with a status of 'pending'
            INSERT INTO user_relationships (user_id, related_user_id, relationship_type, status)
            VALUES (sender_id, recipient_id, 'friendship', 'pending');
        
        WHEN 'accept' THEN
            -- Update the status of a friendship request to 'accepted'
            UPDATE user_relationships
            SET status = 'accepted'
            WHERE user_id = recipient_id AND related_user_id = sender_id 
                AND relationship_type = 'friendship' AND status = 'pending';
        
        WHEN 'reject' THEN
            -- Update the status of a friendship request to 'rejected'
            UPDATE user_relationships
            SET status = 'rejected'
            WHERE user_id = recipient_id AND related_user_id = sender_id 
                AND relationship_type = 'friendship' AND status = 'pending';
        
        ELSE
            -- Raise an exception if an invalid action is provided
            RAISE EXCEPTION 'Invalid action: %', action;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Define a function to retrieve the list of friends for a given user based on accepted friendship status
CREATE OR REPLACE FUNCTION get_user_friends(
    current_user_id UUID -- The ID of the user whose friends list is being requested
) RETURNS TABLE (
    friend_id UUID -- The ID of the friend
) AS $$
BEGIN
    -- Return a table of friend IDs for the current user where the friendship status is 'accepted'
    RETURN QUERY
    SELECT related_user_id
    FROM user_relationships
    WHERE user_id = current_user_id 
        AND relationship_type = 'friendship' -- Ensure the relationship is of type 'friendship'
        AND status = 'accepted'; -- Only consider relationships with an 'accepted' status
END;
$$ LANGUAGE plpgsql;

-- Define a function to check content references before inserting or updating likes
CREATE OR REPLACE FUNCTION check_like_content_reference()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the content type is 'track' and verify its existence
    IF NEW.content_type = 'track' THEN
        IF NOT EXISTS (SELECT 1 FROM tracks WHERE track_id = NEW.content_id) THEN
            RAISE EXCEPTION 'Invalid track_id'; -- Raise an exception if the track does not exist
        END IF;
    -- Check if the content type is 'album' and verify its existence
    ELSIF NEW.content_type = 'album' THEN
        IF NOT EXISTS (SELECT 1 FROM albums WHERE album_id = NEW.content_id) THEN
            RAISE EXCEPTION 'Invalid album_id'; -- Raise an exception if the album does not exist
        END IF;
    -- Check if the content type is 'playlist' and verify its existence
    ELSIF NEW.content_type = 'playlist' THEN
        IF NOT EXISTS (SELECT 1 FROM playlists WHERE playlist_id = NEW.content_id) THEN
            RAISE EXCEPTION 'Invalid playlist_id'; -- Raise an exception if the playlist does not exist
        END IF;
    END IF;
    RETURN NEW; -- Return the new record to proceed with the insert or update operation
END;
$$ LANGUAGE plpgsql;

-- Define a function to view friendship requests based on their status for a given user
CREATE OR REPLACE FUNCTION view_friendship_requests(
    current_user_id UUID, -- The ID of the user whose friendship requests are being queried
    request_status VARCHAR -- The status of the friendship requests to filter by ('accepted', 'rejected', etc.)
) RETURNS TABLE (
    friend_name TEXT, -- The name of the friend related to the request
    request_date TIMESTAMP -- The date when the friendship request was made
) AS $$
BEGIN
    -- Return a table of friend names and request dates based on the specified status
    RETURN QUERY
    SELECT u.name, ur.created_at
    FROM user_relationships ur
    JOIN users u ON ur.related_user_id = u.user_id -- Join with the users table to get the friend's name
    WHERE ur.user_id = current_user_id 
        AND ur.relationship_type = 'friendship' -- Filter by friendship type requests
        AND ur.status = request_status; -- Filter by the specified status (accepted, rejected, etc.)
END;
$$ LANGUAGE plpgsql;

-- Define a function to follow a user
CREATE OR REPLACE FUNCTION follow_user(follower_id UUID, followed_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Insert a new relationship with the 'follower' type and 'accepted' status
    INSERT INTO user_relationships (user_id, related_user_id, relationship_type, status)
    VALUES (follower_id, followed_id, 'follower', 'accepted')
    ON CONFLICT (user_id, related_user_id, relationship_type) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Define a function to follow an artist
CREATE OR REPLACE FUNCTION follow_artist(user_id UUID, artist_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Insert a new record in the user_follows table to indicate the user is following the artist
    INSERT INTO user_follows (user_id, artist_id)
    VALUES (user_id, artist_id)
    ON CONFLICT (user_id, artist_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Define a function to create a wallet for a user
CREATE OR REPLACE FUNCTION create_wallet(user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Insert a new wallet record for the user with an initial balance of 0
    INSERT INTO wallets (user_id, balance)
    VALUES (user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Define a function to add funds to a user's wallet
CREATE OR REPLACE FUNCTION add_funds_to_wallet(user_id UUID, amount DECIMAL)
RETURNS VOID AS $$
BEGIN
    -- Update the balance of the user's wallet by adding the specified amount
    UPDATE wallets
    SET balance = balance + amount
    WHERE user_id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Define a function to withdraw funds from a user's wallet
CREATE OR REPLACE FUNCTION withdraw_funds_from_wallet(user_id UUID, amount DECIMAL)
RETURNS BOOLEAN AS $$
DECLARE
    current_balance DECIMAL;
BEGIN
    -- Retrieve the current balance of the user's wallet
    SELECT balance INTO current_balance
    FROM wallets
    WHERE user_id = user_id;
    
    -- Check if the user has sufficient funds to withdraw the requested amount
    IF current_balance >= amount THEN
        -- Update the balance of the user's wallet by subtracting the requested amount
        UPDATE wallets
        SET balance = balance - amount
        WHERE user_id = user_id;
        RETURN TRUE; -- Return true to indicate the withdrawal was successful
    ELSE
        RETURN FALSE; -- Return false to indicate the withdrawal failed due to insufficient funds
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Define a function to buy a concert ticket
CREATE OR REPLACE FUNCTION buy_concert_ticket(user_id UUID, concert_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    ticket_price DECIMAL;
BEGIN
    -- Retrieve the price of the concert ticket
    SELECT price INTO ticket_price
    FROM concerts
    WHERE concert_id = concert_id;
    
    -- Try to withdraw the ticket price from the user's wallet
    IF withdraw_funds_from_wallet(user_id, ticket_price) THEN
        -- If the withdrawal is successful, insert a new valid ticket for the user
        INSERT INTO tickets (concert_id, user_id, status)
        VALUES (concert_id, user_id, 'valid');
        RETURN TRUE; -- Return true to indicate the ticket purchase was successful
    ELSE
        RETURN FALSE; -- Return false to indicate the ticket purchase failed due to insufficient funds
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Define a function to retrieve the user's valid (not expired) tickets
CREATE OR REPLACE FUNCTION get_valid_tickets(user_id UUID)
RETURNS TABLE (
    ticket_id UUID,
    concert_name VARCHAR,
    concert_date TIMESTAMP,
    venue VARCHAR
) AS $$
BEGIN
    -- Return a table of valid ticket information for the user, including the concert details
    RETURN QUERY
    SELECT t.ticket_id, c.name, c.date, c.venue
    FROM tickets t
    JOIN concerts c ON t.concert_id = c.concert_id
    WHERE t.user_id = user_id AND t.status = 'valid' AND c.date > CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Define a function to retrieve the user's expired tickets
CREATE OR REPLACE FUNCTION get_expired_tickets(user_id UUID)
RETURNS TABLE (
    ticket_id UUID,
    concert_name VARCHAR,
    concert_date TIMESTAMP,
    venue VARCHAR
) AS $$
BEGIN
    -- Return a table of expired ticket information for the user, including the concert details
    RETURN QUERY
    SELECT t.ticket_id, c.name, c.date, c.venue
    FROM tickets t
    JOIN concerts c ON t.concert_id = c.concert_id
    WHERE t.user_id = user_id AND (t.status = 'used' OR c.date <= CURRENT_TIMESTAMP);
END;
$$ LANGUAGE plpgsql;

-- Define a function to add a content item (track, album, playlist) to a user's favorites
CREATE OR REPLACE FUNCTION add_to_favorites(user_id UUID, content_id UUID, content_type VARCHAR)
RETURNS VOID AS $$
BEGIN
    -- Insert a new record in the user_likes table to indicate the user has liked the content
    INSERT INTO user_likes (user_id, content_id, content_type, liked_on)
    VALUES (user_id, content_id, content_type, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id, content_id, content_type) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Define a function to remove a content item (track, album, playlist) from a user's favorites
CREATE OR REPLACE FUNCTION remove_from_favorites(user_id UUID, content_id UUID, content_type VARCHAR)
RETURNS VOID AS $$
BEGIN
    -- Delete the record from the user_likes table to remove the user's like for the content
    DELETE FROM user_likes
    WHERE user_id = user_id AND content_id = content_id AND content_type = content_type;
END;
$$ LANGUAGE plpgsql;

-- Define a function to search for tracks based on various criteria
CREATE OR REPLACE FUNCTION search_tracks(
    search_term TEXT,
    artist_name TEXT DEFAULT NULL,
    genre TEXT DEFAULT NULL,
    region TEXT DEFAULT NULL,
    age_rating TEXT DEFAULT NULL
)
RETURNS TABLE (
    track_id UUID,
    track_name VARCHAR,
    artist_name TEXT,
    album_name VARCHAR,
    genre TEXT,
    region VARCHAR,
    age_rating VARCHAR
) AS $$
BEGIN
    -- Return a table of track information matching the provided search criteria
    RETURN QUERY
    SELECT t.track_id, t.name AS track_name, ar.name AS artist_name, 
           al.name AS album_name, ar.genre, t.region, t.age_rating
    FROM tracks t
    JOIN albums al ON t.album_id = al.album_id
    JOIN artists ar ON al.artist_id = ar.artist_id
    WHERE (t.name ILIKE '%' || search_term || '%'
           OR ar.name ILIKE '%' || search_term || '%'
           OR al.name ILIKE '%' || search_term || '%')
    AND (artist_name IS NULL OR ar.name ILIKE '%' || artist_name || '%')
    AND (genre IS NULL OR ar.genre ILIKE '%' || genre || '%')
    AND (region IS NULL OR t.region ILIKE '%' || region || '%')
    AND (age_rating IS NULL OR t.age_rating = age_rating);
END;
$$ LANGUAGE plpgsql;

-- Define a function to create a new playlist
CREATE OR REPLACE FUNCTION create_playlist(
    p_user_id UUID,
    p_name VARCHAR(50),
    p_visibility VARCHAR(10)
) RETURNS UUID AS $$
DECLARE
    new_playlist_id UUID;
BEGIN
    -- Insert a new playlist and return the generated playlist_id
    INSERT INTO playlists (user_id, name, visibility)
    VALUES (p_user_id, p_name, p_visibility)
    RETURNING playlist_id INTO new_playlist_id;
    
    RETURN new_playlist_id;
END;
$$ LANGUAGE plpgsql;

-- Define a function to add a track to a playlist
CREATE OR REPLACE FUNCTION add_track_to_playlist(
    p_playlist_id UUID,
    p_track_id UUID
) RETURNS VOID AS $$
BEGIN
    -- Insert a new record in the playlist_tracks table to associate the track with the playlist
    INSERT INTO playlist_tracks (playlist_id, track_id)
    VALUES (p_playlist_id, p_track_id);
END;
$$ LANGUAGE plpgsql;

-- Define a function to retrieve the visible playlists for a given user
CREATE OR REPLACE FUNCTION get_visible_playlists(p_user_id UUID)
RETURNS TABLE (
    playlist_id UUID,
    playlist_name VARCHAR(50),
    owner_name TEXT,
    visibility VARCHAR(10)
) AS $$
BEGIN
    -- Return a table of playlist information that are visible to the given user
    RETURN QUERY
    SELECT p.playlist_id, p.name, u.name AS owner_name, p.visibility
    FROM playlists p
    JOIN users u ON p.user_id = u.user_id
    WHERE p.visibility = 'public'
    OR (p.visibility = 'private' AND EXISTS (
        SELECT 1 FROM user_relationships
        WHERE (user_id = p_user_id AND related_user_id = p.user_id)
        OR (user_id = p.user_id AND related_user_id = p_user_id)
        AND relationship_type = 'friendship' AND status = 'accepted'
    ))
    OR p.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_track_lyrics(p_track_id UUID)
RETURNS TEXT AS $$
DECLARE
    track_lyrics TEXT; -- Variable to hold the lyrics of the track
BEGIN
    -- Select the lyrics from the track_lyrics table for the given track ID
    SELECT lyrics INTO track_lyrics
    FROM track_lyrics
    WHERE track_id = p_track_id;
    
    -- Return the lyrics of the track
    RETURN track_lyrics;
END;
$$ LANGUAGE plpgsql;
-- This function retrieves the lyrics for a given track identified by p_track_id

CREATE OR REPLACE FUNCTION add_album(
    p_artist_id UUID,
    p_name VARCHAR(50),
    p_release_date DATE
) RETURNS UUID AS $$
DECLARE
    new_album_id UUID; -- Variable to store the newly created album's ID
BEGIN
    -- Insert a new album into the albums table and return its ID
    INSERT INTO albums (artist_id, name, release_date)
    VALUES (p_artist_id, p_name, p_release_date)
    RETURNING album_id INTO new_album_id;
    
    -- Return the new album's ID
    RETURN new_album_id;
END;
$$ LANGUAGE plpgsql;
-- This function adds a new album for a given artist and returns the new album's ID

CREATE OR REPLACE FUNCTION add_track(
    p_album_id UUID,
    p_name VARCHAR(50),
    p_duration INTERVAL,
    p_lyrics TEXT,
    p_playlist_restriction BOOLEAN
) RETURNS UUID AS $$
DECLARE
    new_track_id UUID; -- Variable to store the newly created track's ID
BEGIN
    -- Insert a new track into the tracks table and return its ID
    INSERT INTO tracks (album_id, name, duration, playlist_restriction)
    VALUES (p_album_id, p_name, p_duration, p_playlist_restriction)
    RETURNING track_id INTO new_track_id;
    
    -- Insert the track's lyrics into the track_lyrics table
    INSERT INTO track_lyrics (track_id, lyrics)
    VALUES (new_track_id, p_lyrics);
    
    -- Return the new track's ID
    RETURN new_track_id;
END;
$$ LANGUAGE plpgsql;
-- This function adds a new track to an album, including lyrics, and returns the new track's ID

CREATE OR REPLACE FUNCTION set_track_playlist_restriction(
    p_track_id UUID,
    p_restriction BOOLEAN
) RETURNS VOID AS $$
BEGIN
    -- Update the playlist_restriction flag for a specific track
    UPDATE tracks
    SET playlist_restriction = p_restriction
    WHERE track_id = p_track_id;
END;
$$ LANGUAGE plpgsql;
-- This function updates the playlist restriction status of a specific track

CREATE OR REPLACE FUNCTION add_concert(
    p_artist_id UUID,
    p_name VARCHAR(100),
    p_date TIMESTAMP,
    p_venue VARCHAR(100),
    p_price DECIMAL(10, 2)
) RETURNS UUID AS $$
DECLARE
    new_concert_id UUID; -- Variable to store the newly created concert's ID
BEGIN
    -- Insert a new concert into the concerts table with a status of 'scheduled'
    INSERT INTO concerts (artist_id, name, date, venue, price, status)
    VALUES (p_artist_id, p_name, p_date, p_venue, p_price, 'scheduled')
    RETURNING concert_id INTO new_concert_id;
    
    -- Return the new concert's ID
    RETURN new_concert_id;
END;
$$ LANGUAGE plpgsql;
-- This function adds a new concert and returns the new concert's ID

CREATE OR REPLACE FUNCTION cancel_concert(p_concert_id UUID)
RETURNS VOID AS $$
DECLARE
    refund_amount DECIMAL(10, 2); -- Variable to store the refund amount
    user_id_var UUID; -- Variable to store the user ID for refund processing
BEGIN
    -- Update the concert's status to 'cancelled'
    UPDATE concerts
    SET status = 'cancelled'
    WHERE concert_id = p_concert_id;
    
    -- Loop through all valid tickets for the concert, refunding each ticket
    FOR refund_amount, user_id_var IN
        SELECT c.price, t.user_id
        FROM tickets t
        JOIN concerts c ON t.concert_id = c.concert_id
        WHERE t.concert_id = p_concert_id AND t.status = 'valid'
    LOOP
        -- Perform the refund by adding funds to the user's wallet
        PERFORM add_funds_to_wallet(user_id_var, refund_amount);
        
        -- Update the ticket's status to 'refunded'
        UPDATE tickets
        SET status = 'refunded'
        WHERE concert_id = p_concert_id AND user_id = user_id_var;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- This function cancels a concert and processes refunds for all valid tickets

CREATE OR REPLACE FUNCTION calculate_genre_interest(
    p_user_id UUID,
    p_genre TEXT
) RETURNS FLOAT AS $$
DECLARE
    like_score FLOAT;
    play_score FLOAT;
BEGIN
    -- Calculate score based on likes
    SELECT COALESCE(COUNT(*), 0) INTO like_score
    FROM user_likes ul
    JOIN tracks t ON ul.content_id = t.track_id
    JOIN albums a ON t.album_id = a.album_id
    JOIN artists ar ON a.artist_id = ar.artist_id
    WHERE ul.user_id = p_user_id AND ar.genre = p_genre AND ul.content_type = 'track';

    -- Calculate score based on play history
    SELECT COALESCE(COUNT(*), 0) INTO play_score
    FROM user_played_song ups
    JOIN tracks t ON ups.track_id = t.track_id
    JOIN albums a ON t.album_id = a.album_id
    JOIN artists ar ON a.artist_id = ar.artist_id
    WHERE ups.user_id = p_user_id AND ar.genre = p_genre;

    -- Combine scores (you can adjust the weights as needed)
    RETURN (like_score * 2 + play_score) / 3;
END;
$$ LANGUAGE plpgsql;