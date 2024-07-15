-- Function to create a wallet for a user with an initial balance of 0
CREATE OR REPLACE FUNCTION create_wallet(user_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO wallets (user_id, balance)
    VALUES (user_id, 0)
    ON CONFLICT (user_id) DO NOTHING; -- Avoids creating duplicate wallets for the same user
END;
$$ LANGUAGE plpgsql;

-- Function to add funds to a user's wallet
CREATE OR REPLACE FUNCTION add_funds_to_wallet(user_id UUID, amount DECIMAL)
RETURNS VOID AS $$
BEGIN
    UPDATE wallets
    SET balance = balance + amount -- Increases the wallet balance by the specified amount
    WHERE user_id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to retrieve the current balance of a user's wallet
CREATE OR REPLACE FUNCTION get_wallet_balance(user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    balance DECIMAL;
BEGIN
    SELECT w.balance INTO balance
    FROM wallets w
    WHERE w.user_id = user_id;
    
    RETURN COALESCE(balance, 0); -- Returns 0 if no wallet is found
END;
$$ LANGUAGE plpgsql;

-- Function to make a payment from a user's wallet for a specific package
CREATE OR REPLACE FUNCTION make_payment(user_id UUID, amount DECIMAL, package_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_balance DECIMAL;
BEGIN
    SELECT balance INTO current_balance
    FROM wallets
    WHERE user_id = user_id;

    IF current_balance >= amount THEN
        UPDATE wallets
        SET balance = balance - amount -- Deducts the payment amount from the wallet
        WHERE user_id = user_id;

        INSERT INTO payments (user_id, payment_method, payment_date, amount)
        VALUES (user_id, 'wallet', CURRENT_TIMESTAMP, amount); -- Records the payment

        INSERT INTO user_packages (user_id, package_id, start_date, end_date)
        VALUES (user_id, package_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 month'); -- Subscribes the user to the package

        RETURN TRUE;
    ELSE
        RETURN FALSE; -- Returns false if the balance is insufficient
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to transfer funds between two users' wallets
CREATE OR REPLACE FUNCTION transfer_funds(from_user_id UUID, to_user_id UUID, amount DECIMAL)
RETURNS BOOLEAN AS $$
DECLARE
    sender_balance DECIMAL;
BEGIN
    SELECT balance INTO sender_balance
    FROM wallets
    WHERE user_id = from_user_id;

    IF sender_balance >= amount THEN
        UPDATE wallets
        SET balance = balance - amount -- Deducts the amount from the sender's wallet
        WHERE user_id = from_user_id;

        UPDATE wallets
        SET balance = balance + amount -- Adds the amount to the receiver's wallet
        WHERE user_id = to_user_id;

        INSERT INTO payments (user_id, payment_method, payment_date, amount)
        VALUES (from_user_id, 'transfer_out', CURRENT_TIMESTAMP, amount); -- Records the transfer out

        INSERT INTO payments (user_id, payment_method, payment_date, amount)
        VALUES (to_user_id, 'transfer_in', CURRENT_TIMESTAMP, amount); -- Records the transfer in

        RETURN TRUE;
    ELSE
        RETURN FALSE; -- Returns false if the sender's balance is insufficient
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to refund a payment back to a user's wallet
CREATE OR REPLACE FUNCTION refund_payment(payment_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    refund_amount DECIMAL;
    user_id_to_refund UUID;
BEGIN
    SELECT amount, user_id INTO refund_amount, user_id_to_refund
    FROM payments
    WHERE payment_id = payment_id;

    IF FOUND THEN
        UPDATE wallets
        SET balance = balance + refund_amount -- Adds the refund amount to the user's wallet
        WHERE user_id = user_id_to_refund;

        INSERT INTO payments (user_id, payment_method, payment_date, amount)
        VALUES (user_id_to_refund, 'refund', CURRENT_TIMESTAMP, refund_amount); -- Records the refund

        RETURN TRUE;
    ELSE
        RETURN FALSE; -- Returns false if the payment to refund is not found
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get the transaction history of a user
CREATE OR REPLACE FUNCTION get_transaction_history(user_id UUID)
RETURNS TABLE (
    payment_id UUID,
    payment_method VARCHAR(50),
    payment_date TIMESTAMP,
    amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.payment_id, p.payment_method, p.payment_date, p.amount
    FROM payments p
    WHERE p.user_id = user_id
    ORDER BY p.payment_date DESC; -- Returns the transactions in descending order of payment date
END;
$$ LANGUAGE plpgsql;