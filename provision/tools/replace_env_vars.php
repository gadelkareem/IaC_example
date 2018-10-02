#!/usr/bin/php
<?php
$confFile = '/etc/nginx/fastcgi_params';

// Update the fpm configuration to make the environment variables available
// NOTE: ONLY in the CLI will $_SERVER have environment variables in it.
$content = file_get_contents($confFile);
$line = false;
foreach ($_SERVER as $name => $val) {
    if ($val == '') {
        $val = "null";
    }
    $line = "fastcgi_param        {$name}        {$val};\n";
    # Either Add or Reset the variable
    if (strstr($content, $name) !== false) {
        $content = preg_replace('/fastcgi_param[\s\t]+' . $name . '[\s\t]+.*?\n/', $line, $content);
        echo "MODIFIED {$name} \n";
    } else {
        $content .= "\n{$line}";
        echo "ADDED    {$name}\n";
    }
}
if ($line) {
    file_put_contents($confFile, $content);
}

