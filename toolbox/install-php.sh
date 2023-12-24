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

{ \
    echo "[PHP]"; \
    echo "error_reporting = -1"; \
    echo "display_errors = On"; \
    echo "date.timezone = UTC"; \
} | sudo tee "/etc/php.d/99-php.ini"

if ! command -v "composer" >"/dev/null" 2>&1; then
    curl -fsSL "https://getcomposer.org/installer" >"/tmp/composer-setup.php"

    sudo dnf install --assumeyes "coreutils"

    COMPOSER_INSTALLER_HASH="55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae"
    echo "${COMPOSER_INSTALLER_HASH} /tmp/composer-setup.php" >"/tmp/composer-setup.sha384"
    if ! sha384sum --check "/tmp/composer-setup.sha384" --strict --status; then
        echo "Composer installer script has been either been upgraded or tampered with."
        exit 1
    fi

    php "/tmp/composer-setup.php" --install-dir="${HOME}/bin" --filename="composer"

    rm "/tmp/composer-setup.php";
    rm "/tmp/composer-setup.sha384"
fi
