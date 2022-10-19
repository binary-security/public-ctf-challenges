<?php

$web_dir = '/var/www/html';

$files = scandir($web_dir);

echo "<b>This is our state-of-the-art sitemap:</b><ul></ul>";
print_r($files);

?>