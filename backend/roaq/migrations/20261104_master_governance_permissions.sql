-- Adds permissions required by the Master governance workflows.
-- Safe to run more than once on an existing installation.

INSERT IGNORE INTO master_permissions
    (permission_key, permission_group, permission_label)
VALUES
    ('returns.view', 'Returns', 'View Supplier Returns'),
    ('returns.edit', 'Returns', 'Update Supplier Return Status');

INSERT IGNORE INTO master_role_permissions (role_id, permission_key)
VALUES
    (1, 'returns.view'),
    (1, 'returns.edit');

UPDATE master_role_profiles
SET permissions_json = JSON_ARRAY_APPEND(
    COALESCE(NULLIF(permissions_json, ''), JSON_ARRAY()),
    '$', 'returns.view'
)
WHERE role_id = 1
  AND JSON_VALID(COALESCE(NULLIF(permissions_json, ''), JSON_ARRAY()))
  AND JSON_SEARCH(permissions_json, 'one', 'returns.view') IS NULL;

UPDATE master_role_profiles
SET permissions_json = JSON_ARRAY_APPEND(
    COALESCE(NULLIF(permissions_json, ''), JSON_ARRAY()),
    '$', 'returns.edit'
)
WHERE role_id = 1
  AND JSON_VALID(COALESCE(NULLIF(permissions_json, ''), JSON_ARRAY()))
  AND JSON_SEARCH(permissions_json, 'one', 'returns.edit') IS NULL;
