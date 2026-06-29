-- Transactions & Concurrency
USE SpotifyAcademyDB;
GO



-- Transaction Modes
-- AUTOCOMMIT (Default SQL Server Behavior)
-- Every individual statement is its own transaction.
INSERT INTO dbo.AuditLog (EntityName, ActionName, Details) 
VALUES ('System', 'ModeDemo', 'AutoCommit individual insert');

-- IMPLICIT Transactions
SET IMPLICIT_TRANSACTIONS ON; 
-- No BEGIN TRAN is needed, but COMMIT/ROLLBACK MUST be explicitly called.
UPDATE dbo.Wallets SET Balance = Balance + 1.00 WHERE Balance < 10;
PRINT 'Current nesting level (should be 1): ' + CAST(@@TRANCOUNT AS VARCHAR);
COMMIT TRANSACTION; -- Ends the implicit transaction
SET IMPLICIT_TRANSACTIONS OFF;

-- EXPLICIT Transactions
-- Manual control using BEGIN, COMMIT, ROLLBACK.
BEGIN TRANSACTION;
    UPDATE dbo.Wallets SET Balance = Balance - 0.50 WHERE Balance > 100;
COMMIT;

-- Process & State Management

BEGIN TRY
    BEGIN TRANSACTION; -- @@TRANCOUNT = 1
    PRINT 'Inner Transaction Count: ' + CAST(@@TRANCOUNT AS VARCHAR);

    -- Demonstration of Savepoints
    SAVE TRANSACTION UpdatePoints; 
    
    UPDATE dbo.Wallets SET Balance = Balance + 5.00 
    WHERE UserID = (SELECT TOP 1 UserID FROM dbo.Users);

    -- XACT_STATE() check: 1 = Committable, -1 = Uncommittable, 0 = No transaction
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION;
        PRINT 'Transaction Committed Successfully';
    END
END TRY
BEGIN CATCH
    PRINT 'Error occurred: ' + ERROR_MESSAGE();
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;
GO

--Isolation Levels & Concurrency Problems

-- setting various isolation levels
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Allows Dirty Reads
SELECT * FROM dbo.Wallets WHERE Balance > 0;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;   -- Default (Prevents Dirty Reads)
SELECT * FROM dbo.Wallets;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- Prevents Dirty & Non-Repeatable
SELECT * FROM dbo.Wallets;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;    -- Prevents all (Highest Isolation)
SELECT * FROM dbo.Wallets;

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        -- Uses row versioning
SELECT * FROM dbo.Playlists;
GO

