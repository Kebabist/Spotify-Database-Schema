-- Create an index to improve query performance on user relationships
CREATE INDEX idx_user_relationships_on_users ON user_relationships(user_id, related_user_id);
CREATE INDEX idx_user_relationships_on_type ON user_relationships(relationship_type);

-- Create an index on the user_likes table to improve query performance for operations involving user_id, content_type, and content_id
CREATE INDEX idx_user_likes_user_content ON user_likes(user_id, content_type, content_id);