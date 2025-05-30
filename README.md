# Spotify Database Schema

This project provides an educational PostgreSQL database schema inspired by Spotify, including tables, views, triggers, indexes, and stored procedures for user management, music content, payments, friendships, and more. No special PostgreSQL features or extensions are required beyond standard UUID support.

![Stupify](https://github.com/user-attachments/assets/47c18cdc-10f5-4933-8348-175ad6e9f9e3)
## Features

- Users, artists, albums, tracks, playlists, and user relationships
- Wallet system for payments and package subscriptions
- Friendship requests and social features
- Likes, comments, and user activity tracking
- Views to summarize user preferences and activity
- Triggers to enforce business rules and data consistency
- Indexes for query optimization

## Schema Overview

Key components (see code for full details):

- Tables: users, artists, albums, tracks, playlists, user_follows, user_likes, packages, features, wallets, payments, user_relationships, etc.
- Functions: Create wallets, manage payments, handle friendships, validate likes, etc.
- Views: Aggregate friend activity and user preferences.
- Triggers: Enforce relationship and content integrity.

## Getting Started

### Prerequisites

- PostgreSQL (with `uuid-ossp` extension enabled)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Kebabist/Spotify-Database-Schema.git
   cd Spotify-Database-Schema
   ```

2. Open a PostgreSQL session and run the schema creation script:
   ```sql
   -- Create all tables and enable UUID extension
   \i Stupify_Table_Creator.sql
   ```

3. (Optional) Create functions, triggers, and views:
   ```sql
   \i Stupify_functions.sql
   \i Stupify_Triggers.sql
   \i Stupify_views.sql
   \i Wallet.sql
   \i Stupify_Indexes.sql
   ```

## Example Usage

### Creating Tables

```sql
SELECT create_all_tables();
```

### Creating a User Wallet

```sql
SELECT create_wallet('user-uuid-here');
```

### Adding Funds

```sql
SELECT add_funds_to_wallet('user-uuid-here', 50.00);
```

### Making a Payment

```sql
SELECT make_payment('user-uuid-here', 9.99, 'package-uuid-here');
```

### Sending a Friendship Request

```sql
SELECT manage_friendship_request('sender-uuid', 'recipient-uuid', 'send');
```

### Accepting a Friendship

```sql
SELECT manage_friendship_request('recipient-uuid', 'sender-uuid', 'accept');
```

### Viewing Friend Activity

```sql
SELECT * FROM user_friend_activity WHERE viewing_user_id = 'user-uuid-here' LIMIT 50;
```

## Notes

- Triggers and constraints enforce integrity, e.g., only friends can message each other and likes must reference valid content.
- Functions and stored procedures use UUIDs for primary keys.
- You may customize or extend the schema for your own educational projects.

## File Reference (Partial)

- `Stupify_Table_Creator.sql`: Table definitions and setup
- `Stupify_functions.sql`: Business logic functions
- `Stupify_Triggers.sql`: Triggers for integrity
- `Stupify_views.sql`: Predefined views
- `Wallet.sql`: Wallet and payment functions
- `Stupify_Indexes.sql`: Indexes for performance

For the full list of files, visit the [repository code page](https://github.com/Kebabist/Spotify-Database-Schema).

## License

This project is for educational purposes only.
