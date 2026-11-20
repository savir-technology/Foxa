<?php

function printingResolveVendorId(array $payload = []): int
{
    $actor = requireDashboardActor(['vendor', 'master']);
    $role = $actor['role'] ?? 'vendor';
    $vendor = $actor['vendor'] ?? [];

    if ($role === 'master') {
        return (int)($payload['vendor_id'] ?? $_GET['vendor_id'] ?? 0);
    }

    return (int)($vendor['vendor_id'] ?? 0);
}

function printingBool($value, bool $default = false): int
{
    if ($value === null) {
        return $default ? 1 : 0;
    }

    if (is_bool($value)) {
        return $value ? 1 : 0;
    }

    $normalized = strtolower(trim((string)$value));
    return in_array($normalized, ['1', 'true', 'yes', 'on'], true) ? 1 : 0;
}

function printingIntOrNull($value): ?int
{
    if ($value === null || $value === '') {
        return null;
    }

    if (!is_numeric($value)) {
        return null;
    }

    return (int)$value;
}

function printingNormalizeSections($value): string
{
    if (is_array($value)) {
        $sections = [];
        foreach ($value as $item) {
            $section = trim((string)$item);
            if ($section !== '') {
                $sections[] = $section;
            }
        }
        return json_encode($sections, JSON_UNESCAPED_UNICODE);
    }

    $text = trim((string)($value ?? ''));
    if ($text === '') {
        return json_encode([], JSON_UNESCAPED_UNICODE);
    }

    $decoded = json_decode($text, true);
    if (is_array($decoded)) {
        return printingNormalizeSections($decoded);
    }

    $sections = preg_split('/\r\n|\r|\n|,/', $text);
    return printingNormalizeSections($sections ?: []);
}

function printingEnsureSettingsRow(PDO $con, int $vendorId): array
{
    $stmt = $con->prepare("
        SELECT
            setting_id,
            vendor_id,
            default_direction,
            default_font_size,
            invoice_copies,
            print_logo,
            created_at,
            updated_at
        FROM vendor_print_settings
        WHERE vendor_id = :vendor_id
        LIMIT 1
    ");
    $stmt->execute([':vendor_id' => $vendorId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row) {
        return $row;
    }

    $insert = $con->prepare("
        INSERT INTO vendor_print_settings (
            vendor_id,
            default_direction,
            default_font_size,
            invoice_copies,
            print_logo
        ) VALUES (
            :vendor_id,
            'rtl_ar',
            'medium',
            1,
            1
        )
    ");
    $insert->execute([':vendor_id' => $vendorId]);

    $stmt->execute([':vendor_id' => $vendorId]);
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
}

function printingFetchDashboard(PDO $con, int $vendorId): array
{
    $printersStmt = $con->prepare("
        SELECT
            printer_id,
            vendor_id,
            printer_name,
            printer_model,
            printer_type,
            printer_location,
            printer_sections_json,
            printer_ip,
            printer_port,
            is_connected,
            is_active,
            last_print_at,
            created_at,
            updated_at
        FROM vendor_printers
        WHERE vendor_id = :vendor_id
          AND is_active = 1
        ORDER BY printer_id DESC
    ");
    $printersStmt->execute([':vendor_id' => $vendorId]);
    $printers = $printersStmt->fetchAll(PDO::FETCH_ASSOC);

    $templatesStmt = $con->prepare("
        SELECT
            template_id,
            vendor_id,
            template_name,
            template_type,
            paper_width_mm,
            paper_height_mm,
            template_usage,
            is_active,
            created_at,
            updated_at
        FROM vendor_invoice_templates
        WHERE vendor_id = :vendor_id
          AND is_active = 1
        ORDER BY template_id DESC
    ");
    $templatesStmt->execute([':vendor_id' => $vendorId]);
    $templates = $templatesStmt->fetchAll(PDO::FETCH_ASSOC);

    $settings = printingEnsureSettingsRow($con, $vendorId);

    $summaryStmt = $con->prepare("
        SELECT
            COUNT(*) AS total_printers,
            SUM(CASE WHEN is_connected = 1 THEN 1 ELSE 0 END) AS connected_printers,
            SUM(CASE WHEN is_connected = 0 THEN 1 ELSE 0 END) AS disconnected_printers
        FROM vendor_printers
        WHERE vendor_id = :vendor_id
          AND is_active = 1
    ");
    $summaryStmt->execute([':vendor_id' => $vendorId]);
    $printerSummary = $summaryStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $printedStmt = $con->prepare("
        SELECT COUNT(*) AS printed_today
        FROM vendor_print_jobs
        WHERE vendor_id = :vendor_id
          AND job_status = 'printed'
          AND job_type <> 'test'
          AND DATE(printed_at) = CURDATE()
    ");
    $printedStmt->execute([':vendor_id' => $vendorId]);
    $printedToday = (int)$printedStmt->fetchColumn();

    $templateTypesStmt = $con->prepare("
        SELECT COUNT(DISTINCT template_type) AS template_types
        FROM vendor_invoice_templates
        WHERE vendor_id = :vendor_id
          AND is_active = 1
    ");
    $templateTypesStmt->execute([':vendor_id' => $vendorId]);
    $templateTypes = (int)$templateTypesStmt->fetchColumn();

    return [
        'status' => 'success',
        'summary' => [
            'printed_today' => $printedToday,
            'template_types' => $templateTypes,
            'disconnected_printers' => (int)($printerSummary['disconnected_printers'] ?? 0),
            'connected_printers' => (int)($printerSummary['connected_printers'] ?? 0),
            'total_printers' => (int)($printerSummary['total_printers'] ?? 0),
        ],
        'printers' => $printers,
        'templates' => $templates,
        'settings' => $settings,
    ];
}

function printingRespondDashboard(PDO $con, int $vendorId): void
{
    respondJson(printingFetchDashboard($con, $vendorId));
}
