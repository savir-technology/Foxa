-- STAGING ONLY. Never run this file against production.
-- It creates disposable users and one open cart per user for checkout.js.
SET @seed_user_start = 50001;
SET @seed_user_count = 100;

SET @seed_item_id = (
    SELECT items_id
    FROM items
    WHERE items_active = 1
    ORDER BY items_id
    LIMIT 1
);
SET @seed_vendor_id = (
    SELECT vendor_id
    FROM items
    WHERE items_id = @seed_item_id
    LIMIT 1
);

DROP PROCEDURE IF EXISTS seed_checkout_users;
DELIMITER //
CREATE PROCEDURE seed_checkout_users(IN user_start INT, IN user_count INT, IN item_id INT, IN vendor_id INT)
BEGIN
    DECLARE n INT DEFAULT 0;
    DECLARE current_id INT;

    IF item_id IS NULL OR vendor_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No active staging item/vendor was found';
    END IF;

    WHILE n < user_count DO
        SET current_id = user_start + n;

        INSERT INTO users (
            users_email, users_phone, users_verfiycode, users_approve,
            users_password, users_id, users_name, password_hashed,
            user_role, auth_provider, profile_completed, session_version
        ) VALUES (
            CONCAT('loadtest+', current_id, '@staging.invalid'),
            CONCAT('010000', LPAD(current_id, 5, '0')),
            0, 1, 'load-test-only', current_id,
            CONCAT('Load Test User ', current_id), 0,
            'user', 'email', 1, 1
        )
        ON DUPLICATE KEY UPDATE
            users_approve = 1,
            users_name = VALUES(users_name),
            profile_completed = 1;

        DELETE FROM cart
        WHERE cart_usersid = current_id
          AND cart_orders = 0;

        INSERT INTO cart (
            cart_usersid, cart_itemsid, cart_orders, cart_quantity,
            cart_context_type, cart_vendor_id
        ) VALUES (
            current_id, item_id, 0, 1, 'food', vendor_id
        );

        SET n = n + 1;
    END WHILE;
END//
DELIMITER ;

CALL seed_checkout_users(@seed_user_start, @seed_user_count, @seed_item_id, @seed_vendor_id);
DROP PROCEDURE IF EXISTS seed_checkout_users;

SELECT @seed_user_start AS user_start,
       @seed_user_count AS user_count,
       @seed_item_id AS item_id,
       @seed_vendor_id AS vendor_id;
