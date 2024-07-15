-- This function checks if users are friends before allowing a message to be sent
CREATE OR REPLACE FUNCTION check_friendship_before_message() RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM user_relationships
        WHERE (user_id = NEW.sender_id AND friend_id = NEW.recipient_id AND status = 'accepted')
        OR (user_id = NEW.recipient_id AND friend_id = NEW.sender_id AND status = 'accepted')
    ) THEN
        RAISE EXCEPTION 'Users must be friends to send messages';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- usage
--CREATE TRIGGER trigger_check_friendship_before_message
--BEFORE INSERT ON messages
--FOR EACH ROW
--EXECUTE FUNCTION check_friendship_before_message();

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

-- Create a trigger to enforce content reference checks before insert or update operations on user_likes
CREATE TRIGGER check_content_reference_trigger_likes
BEFORE INSERT OR UPDATE ON user_likes
FOR EACH ROW EXECUTE FUNCTION check_like_content_reference();
-- This trigger invokes the check_like_content_reference function for each row before it is inserted or updated,
-- ensuring that likes are only added for existing content.


