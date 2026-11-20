-- Run on the staging database after a load test.
-- Set the range to the users/orders created by that test before running.
SET @user_start = 50001;
SET @user_end = 50100;

SELECT 'orders_created' AS metric, COUNT(*) AS value
FROM orders
WHERE orders_usersid BETWEEN @user_start AND @user_end;

SELECT 'users_with_multiple_orders' AS metric, COUNT(*) AS value
FROM (
    SELECT orders_usersid
    FROM orders
    WHERE orders_usersid BETWEEN @user_start AND @user_end
    GROUP BY orders_usersid
    HAVING COUNT(*) > 1
) duplicates;

SELECT 'orders_without_items' AS metric, COUNT(*) AS value
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.orders_id
WHERE o.orders_usersid BETWEEN @user_start AND @user_end
  AND oi.order_item_id IS NULL;

SELECT 'orders_without_vendor_rows' AS metric, COUNT(*) AS value
FROM orders o
LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
WHERE o.orders_usersid BETWEEN @user_start AND @user_end
  AND vo.vendor_order_id IS NULL;

SELECT 'unconverted_test_carts' AS metric, COUNT(*) AS value
FROM cart
WHERE cart_usersid BETWEEN @user_start AND @user_end
  AND cart_orders = 0;

-- Every metric above must be zero except orders_created, which should equal
-- (@user_end - @user_start + 1) for a complete burst.
