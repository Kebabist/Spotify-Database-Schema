--GOD mode "DO NOT TOUCH"
--DROP TABLE IF EXISTS user_messages, track_lyrics, user_comments, tickets, concerts, wallets, similarities,
	--user_played_song, payments, user_packages, package_features, features, packages, user_follows,
	--playlist_tracks, tracks, albums, artists, playlists, users;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Function to create all tables at the launch of the program
CREATE OR REPLACE FUNCTION create_all_tables()
RETURNS VOID AS $$
BEGIN
    -- Call each CREATE TABLE statement here
    -- Example: EXECUTE 'CREATE TABLE IF NOT EXISTS users (...);';
    EXECUTE 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";';
    EXECUTE 'CREATE TABLE IF NOT EXISTS users (user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT NOT NULL, email VARCHAR(50) NOT NULL UNIQUE, password VARCHAR(50) NOT NULL, date_of_birth DATE, profile_image BYTEA);';
    EXECUTE 'CREATE TABLE IF NOT EXISTS playlists (playlist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), user_id UUID, name VARCHAR(50) NOT NULL, duration INTERVAL NOT NULL, cover_image BYTEA, description TEXT, visibility VARCHAR(10) CHECK (visibility IN (''public'', ''private'')), FOREIGN KEY (user_id) REFERENCES users(user_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS artists (artist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT NOT NULL, genre TEXT NOT NULL, profile_image BYTEA);';
    EXECUTE 'CREATE TABLE IF NOT EXISTS albums (album_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), artist_id UUID, name VARCHAR(50) NOT NULL, release_date DATE, cover_image BYTEA, FOREIGN KEY (artist_id) REFERENCES artists(artist_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS tracks (track_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), album_id UUID, name VARCHAR(50) NOT NULL, duration INTERVAL NOT NULL, file_path VARCHAR(255), region VARCHAR(50), age_rating VARCHAR(10), playlist_restriction BOOLEAN DEFAULT FALSE, music_file BYTEA, FOREIGN KEY (album_id) REFERENCES albums(album_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS playlist_tracks (playlist_id UUID, track_id UUID, track_order INT, PRIMARY KEY (playlist_id, track_id), FOREIGN KEY (playlist_id) REFERENCES playlists(playlist_id), FOREIGN KEY (track_id) REFERENCES tracks(track_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS user_follows (user_id UUID, artist_id UUID, PRIMARY KEY (user_id, artist_id), FOREIGN KEY (user_id) REFERENCES users(user_id), FOREIGN KEY (artist_id) REFERENCES artists(artist_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS user_likes (user_id UUID, content_id UUID, content_type VARCHAR(20) CHECK (content_type IN (''track'', ''album'', ''playlist'')), liked_on TIMESTAMP, PRIMARY KEY (user_id, content_id, content_type), FOREIGN KEY (user_id) REFERENCES users(user_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS features (feature_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), name VARCHAR(50));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS packages (package_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), name VARCHAR(50) NOT NULL, price NUMERIC(4,2), number_of_accounts INT, description TEXT);';
    EXECUTE 'CREATE TABLE IF NOT EXISTS package_features (package_id UUID, feature_id UUID, PRIMARY KEY (package_id, feature_id), FOREIGN KEY (package_id) REFERENCES packages(package_id), FOREIGN KEY (feature_id) REFERENCES features(feature_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS user_packages (user_id UUID, package_id UUID, start_date TIMESTAMP, end_date TIMESTAMP, PRIMARY KEY (user_id, package_id), FOREIGN KEY (user_id) REFERENCES users(user_id), FOREIGN KEY (package_id) REFERENCES packages(package_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS payments (payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), user_id UUID, payment_method VARCHAR(50) NOT NULL, payment_date TIMESTAMP NOT NULL, amount DECIMAL(5, 2) NOT NULL, FOREIGN KEY (user_id) REFERENCES users(user_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS user_played_song (play_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), user_id UUID, track_id UUID, play_date TIMESTAMP NOT NULL, FOREIGN KEY (user_id) REFERENCES users(user_id), FOREIGN KEY (track_id) REFERENCES tracks(track_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS similarities (user_id UUID, track_id UUID, similarity_score FLOAT, PRIMARY KEY (user_id, track_id), FOREIGN KEY (user_id) REFERENCES users(user_id), FOREIGN KEY (track_id) REFERENCES tracks(track_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS user_relationships (user_id UUID NOT NULL, related_user_id UUID NOT NULL, relationship_type VARCHAR(10) CHECK (relationship_type IN (''friendship'', ''follower'')), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, status VARCHAR(10) DEFAULT ''pending'' CHECK (status IN (''pending'', ''accepted'', ''blocked'', ''rejected'')), FOREIGN KEY (user_id) REFERENCES users(user_id), FOREIGN KEY (related_user_id) REFERENCES users(user_id), PRIMARY KEY (user_id, related_user_id, relationship_type));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS wallets (wallet_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), user_id UUID UNIQUE, balance DECIMAL(10, 2) DEFAULT 0, FOREIGN KEY (user_id) REFERENCES users(user_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS concerts (concert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), artist_id UUID, name VARCHAR(100) NOT NULL, date TIMESTAMP NOT NULL, venue VARCHAR(100) NOT NULL, price DECIMAL(10, 2) NOT NULL, image BYTEA, status VARCHAR(20) CHECK (status IN (''scheduled'', ''cancelled'')), FOREIGN KEY (artist_id) REFERENCES artists(artist_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS tickets (ticket_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), concert_id UUID, user_id UUID, purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, status VARCHAR(20) CHECK (status IN (''valid'', ''used'', ''refunded'')), FOREIGN KEY (concert_id) REFERENCES concerts(concert_id), FOREIGN KEY (user_id) REFERENCES users(user_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS user_comments (comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), user_id UUID, content_type VARCHAR(20) CHECK (content_type IN (''track'', ''album'', ''playlist'')), content_id UUID, comment_text TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES users(user_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS track_lyrics (track_id UUID PRIMARY KEY, lyrics TEXT, FOREIGN KEY (track_id) REFERENCES tracks(track_id));';
    EXECUTE 'CREATE TABLE IF NOT EXISTS user_messages (message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), sender_id UUID NOT NULL, recipient_id UUID NOT NULL, message_text TEXT NOT NULL, sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, read_at TIMESTAMP, FOREIGN KEY (sender_id) REFERENCES users(user_id), FOREIGN KEY (recipient_id) REFERENCES users(user_id));';
END;
$$ LANGUAGE plpgsql;


-- Create a table for storing user information
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each user
    name TEXT NOT NULL, -- User's name
    email VARCHAR(50) NOT NULL UNIQUE, -- User's email, must be unique
    password VARCHAR(50) NOT NULL, -- User's password
    date_of_birth DATE, -- User's date of birth
    profile_image BYTEA -- User's profile image stored as binary data
);

-- Create a table for storing playlists created by users
CREATE TABLE IF NOT EXISTS playlists (
    playlist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each playlist
    user_id UUID, -- Identifier of the user who owns the playlist
    name VARCHAR(50) NOT NULL, -- Name of the playlist
    duration INTERVAL NOT NULL, -- Total duration of all tracks in the playlist
    cover_image BYTEA, -- Cover image for the playlist stored as binary data
    description TEXT, -- Description of the playlist
    visibility VARCHAR(10) CHECK (visibility IN ('public', 'private')), -- Visibility of the playlist
    FOREIGN KEY (user_id) REFERENCES users(user_id) -- Foreign key linking to the users table
);

-- Create a table for storing artist information
CREATE TABLE IF NOT EXISTS artists (
    artist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each artist
    name TEXT NOT NULL, -- Artist's name
    genre TEXT NOT NULL, -- Genre of music the artist performs
    profile_image BYTEA -- Artist's profile image stored as binary data
);

-- Create a table for storing album information
CREATE TABLE IF NOT EXISTS albums (
    album_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each album
    artist_id UUID, -- Identifier of the artist who released the album
    name VARCHAR(50) NOT NULL, -- Name of the album
    release_date DATE, -- Release date of the album
    cover_image BYTEA, -- Cover image of the album stored as binary data
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id) -- Foreign key linking to the artists table
);

-- Create a table for storing track information
CREATE TABLE IF NOT EXISTS tracks (
    track_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each track
    album_id UUID, -- Identifier of the album the track belongs to
    name VARCHAR(50) NOT NULL, -- Name of the track
    duration INTERVAL NOT NULL, -- Duration of the track
    file_path VARCHAR(255), -- File path where the track is stored
    region VARCHAR(50), -- Region
    age_rating VARCHAR(10), -- Age rating
    playlist_restriction BOOLEAN DEFAULT FALSE, -- Playlist restriction
    music_file BYTEA,
    FOREIGN KEY (album_id) REFERENCES albums(album_id) -- Foreign key linking to the albums table
);


-- Create a table for associating tracks with playlists
CREATE TABLE IF NOT EXISTS playlist_tracks (
    playlist_id UUID, -- Identifier of the playlist
    track_id UUID, -- Identifier of the track
    track_order INT, -- Order of the track within the playlist
    PRIMARY KEY (playlist_id, track_id), -- Composite primary key consisting of playlist_id and track_id
    FOREIGN KEY (playlist_id) REFERENCES playlists(playlist_id), -- Foreign key linking to the playlists table
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) -- Foreign key linking to the tracks table
);

-- Create a table for storing which artists a user follows
CREATE TABLE IF NOT EXISTS user_follows (
    user_id UUID, -- Identifier of the user
    artist_id UUID, -- Identifier of the artist
    PRIMARY KEY (user_id, artist_id), -- Composite primary key consisting of user_id and artist_id
    FOREIGN KEY (user_id) REFERENCES users(user_id), -- Foreign key linking to the users table
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id) -- Foreign key linking to the artists table
);

-- Create a table for storing which tracks a user likes
CREATE TABLE IF NOT EXISTS user_likes (
    user_id UUID, -- Identifier of the user
    content_id UUID, -- Identifier of the content (track, album, or playlist)
    content_type VARCHAR(20) CHECK (content_type IN ('track', 'album', 'playlist')), -- Type of content
    liked_on TIMESTAMP, -- Timestamp when the content was liked
    PRIMARY KEY (user_id, content_id, content_type), -- Composite primary key consisting of user_id, content_id, and content_type
    FOREIGN KEY (user_id) REFERENCES users(user_id) -- Foreign key linking to the users table
);

-- Create a table for storing features available in different packages
CREATE TABLE IF NOT EXISTS features (
    feature_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each feature
    name VARCHAR(50) -- Name of the feature
);

-- Create a table for storing package information
CREATE TABLE IF NOT EXISTS packages (
    package_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each package
    name VARCHAR(50) NOT NULL, -- Name of the package
    price NUMERIC(4,2), -- Price of the package
    number_of_accounts INT, -- Number of accounts supported by the package
    description TEXT -- Description of the package
);

-- Create a table for associating features with packages
CREATE TABLE IF NOT EXISTS package_features (
    package_id UUID, -- Identifier of the package
    feature_id UUID, -- Identifier of the feature
    PRIMARY KEY (package_id, feature_id), -- Composite primary key consisting of package_id and feature_id
    FOREIGN KEY (package_id) REFERENCES packages(package_id), -- Foreign key linking to the packages table
    FOREIGN KEY (feature_id) REFERENCES features(feature_id) -- Foreign key linking to the features table
);

-- Create a table for storing which packages a user has subscribed to
CREATE TABLE IF NOT EXISTS user_packages (
    user_id UUID, -- Identifier of the user
    package_id UUID, -- Identifier of the package
    start_date TIMESTAMP, -- Start date of the package subscription
    end_date TIMESTAMP, -- End date of the package subscription
    PRIMARY KEY (user_id, package_id), -- Composite primary key consisting of user_id and package_id
    FOREIGN KEY (user_id) REFERENCES users(user_id), -- Foreign key linking to the users table
    FOREIGN KEY (package_id) REFERENCES packages(package_id) -- Foreign key linking to the packages table
);

-- Create a table for storing payment information
CREATE TABLE IF NOT EXISTS payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each payment
    user_id UUID, -- Identifier of the user who made the payment
    payment_method VARCHAR(50) NOT NULL, -- Method of payment
    payment_date TIMESTAMP NOT NULL, -- Date of payment
    amount DECIMAL(5, 2) NOT NULL, -- Amount of payment
    FOREIGN KEY (user_id) REFERENCES users(user_id) -- Foreign key linking to the users table
);

-- Create a table for storing information about songs played by users
CREATE TABLE IF NOT EXISTS user_played_song (
    play_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Unique identifier for each play event
    user_id UUID, -- Identifier of the user
    track_id UUID, -- Identifier of the track
    play_date TIMESTAMP NOT NULL, -- Date and time when the song was played
    FOREIGN KEY (user_id) REFERENCES users(user_id), -- Foreign key linking to the users table
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) -- Foreign key linking to the tracks table
);

-- Create a table for storing similarity scores between users and tracks
CREATE TABLE IF NOT EXISTS similarities (
    user_id UUID, -- Identifier of the user
    track_id UUID, -- Identifier of the track
    similarity_score FLOAT, -- Similarity score between the user and the track
    PRIMARY KEY (user_id, track_id), -- Composite primary key consisting of user_id and track_id
    FOREIGN KEY (user_id) REFERENCES users(user_id), -- Foreign key linking to the users table
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) -- Foreign key linking to the tracks table
);

-- Create a table for storing user relationships
CREATE TABLE IF NOT EXISTS user_relationships (
    user_id UUID NOT NULL,
    related_user_id UUID NOT NULL,
    relationship_type VARCHAR(10) CHECK (relationship_type IN ('friendship', 'follower')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(10) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked', 'rejected')),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (related_user_id) REFERENCES users(user_id),
    PRIMARY KEY (user_id, related_user_id, relationship_type)
);

-- Create table for user wallets
CREATE TABLE IF NOT EXISTS wallets (
    wallet_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE,
    balance DECIMAL(10, 2) DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create table for concerts
CREATE TABLE IF NOT EXISTS concerts (
    concert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    artist_id UUID,
    name VARCHAR(100) NOT NULL,
    date TIMESTAMP NOT NULL,
    venue VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    image BYTEA,
    status VARCHAR(20) CHECK (status IN ('scheduled', 'cancelled')),
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
);

-- Create table for concert tickets
CREATE TABLE IF NOT EXISTS tickets (
    ticket_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    concert_id UUID,
    user_id UUID,
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('valid', 'used', 'refunded')),
    FOREIGN KEY (concert_id) REFERENCES concerts(concert_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create table for comments with proper foreign key references
CREATE TABLE IF NOT EXISTS user_comments (
    comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    content_type VARCHAR(20) CHECK (content_type IN ('track', 'album', 'playlist')),
    content_id UUID,
    comment_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create table for song lyrics
CREATE TABLE IF NOT EXISTS track_lyrics (
    track_id UUID PRIMARY KEY,
    lyrics TEXT,
    FOREIGN KEY (track_id) REFERENCES tracks(track_id)
);

-- Create table for user messages
CREATE TABLE IF NOT EXISTS user_messages (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL,
    recipient_id UUID NOT NULL,
    message_text TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (recipient_id) REFERENCES users(user_id)
);
