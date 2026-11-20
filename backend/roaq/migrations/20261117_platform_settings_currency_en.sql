-- Add the English currency name used by the public customer settings API.
-- Safe for installations where platform_settings is created by functions.php.
ALTER TABLE platform_settings
    ADD COLUMN default_currency_name_en VARCHAR(80) NOT NULL DEFAULT 'Saudi Riyal';
