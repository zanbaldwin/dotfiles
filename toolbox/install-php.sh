#!/bin/bash

sudo dnf install --assumeyes \
    "php" \
    "php-bcmath" \
    "php-devel" \
    "php-fpm" \
    "php-gd" \
    "php-mbstring" \
    "php-mysqlnd" \
    "php-pdo" \
    "php-pear" \
    "php-pgsql" \
    "php-pecl-amqp" \
    "php-pecl-apcu" \
    "php-pecl-redis5" \
    "php-pecl-xdebug3" \
    "php-pecl-zip" \
    "php-pgsql" \
    "php-process" \
    "php-soap" \
    "php-xml"

{ \
    echo "[XDebug]"; \
    echo "xdebug.mode = develop,debug"; \
    echo "xdebug.discover_client_host = true"; \
    echo "xdebug.force_error_reporting = -1"; \
    echo "xdebug.start_with_request = yes"; \
    echo "xdebug.log_level = 0"; \
} | sudo tee "/etc/php.d/99-xdebug.ini"
