<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/legal.php';

$page_title = '用户协议';
$page_description = SITE_NAME . '用户协议';

require __DIR__ . '/includes/header.php';
render_legal('用户协议', LEGAL_TERMS);
require __DIR__ . '/includes/footer.php';
