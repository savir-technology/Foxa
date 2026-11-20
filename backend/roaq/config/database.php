<?php

/** Runtime database configuration. Credentials come from PHP-FPM/web-server environment. */
function roaqDatabaseConfig(string $role = 'write'): array
{
    $localConfig = [];
    $localConfigPath = __DIR__ . '/database.local.php';
    if (is_file($localConfigPath)) {
        $loadedConfig = require $localConfigPath;
        if (is_array($loadedConfig)) {
            $localConfig = $loadedConfig;
        }
    }

    $value = static function (string $key, string $default = '') use ($localConfig): string {
        $localValue = $localConfig[$key] ?? null;
        if (is_string($localValue) && trim($localValue) !== '') {
            return trim($localValue);
        }

        $environmentValue = getenv($key);
        if ($environmentValue !== false && trim((string)$environmentValue) !== '') {
            return trim((string)$environmentValue);
        }

        $serverValue = $_ENV[$key] ?? ($_SERVER[$key] ?? null);
        if (is_string($serverValue) && trim($serverValue) !== '') {
            return trim($serverValue);
        }

        return $default;
    };

    $readHost = $value('ROAQ_DB_READ_HOST');
    $readPort = $value('ROAQ_DB_READ_PORT');
    $useReadReplica = $role === 'read' && $readHost !== '';
    $host = $useReadReplica ? $readHost : $value('ROAQ_DB_HOST', 'localhost');
    $port = $useReadReplica
        ? ($readPort !== '' ? $readPort : $value('ROAQ_DB_PORT', '3306'))
        : $value('ROAQ_DB_PORT', '3306');
    $name = $value('ROAQ_DB_NAME', 'u932399374_roaqv2');
    // Empty credentials deliberately fall through to the caller's generic
    // connection error path; they must never be replaced with source defaults.
    $user = $value('ROAQ_DB_USER');
    $pass = $value('ROAQ_DB_PASSWORD');

    return [
        'dsn' => sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, $port, $name),
        'user' => $user,
        'pass' => $pass,
    ];
}
