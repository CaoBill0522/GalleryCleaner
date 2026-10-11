<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/legal.php';

$page_title = '隐私政策';
$page_description = SITE_NAME . '隐私政策';

require __DIR__ . '/includes/header.php';
render_legal('隐私政策', LEGAL_PRIVACY);
require __DIR__ . '/includes/footer.php';
