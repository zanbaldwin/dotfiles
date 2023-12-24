#!/bin/bash

sudo dnf install --assumeyes \
    "php" \
    "php-bcmath" \
    "php-devel" \
    "php-fpm" \
    "php-gd" \
    "php-intl" \
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
    "php-xml" \
    "wkhtmltopdf"

{ \
    echo "[XDebug]"; \
    echo "xdebug.mode = develop,debug"; \
    echo "xdebug.discover_client_host = true"; \
    echo "xdebug.start_with_request = yes"; \
    echo "xdebug.log_level = 0"; \
} | sudo tee "/etc/php.d/99-xdebug.ini"

# If you can deal with EVERY. SINGLE. DEPRECATION. NOTICE. EVER. in your PHPUnit output:
#{ \
#    echo "xdebug.force_error_reporting = -1"; \
#    echo "xdebug.force_display_errors = On"; \
#} | sudo tee -a "/etc/php.d/99-xdebug.ini"

{ \
    echo "[PHP]"; \
    echo "error_reporting = -1"; \
    echo "display_errors = On"; \
    echo "date.timezone = UTC"; \
} | sudo tee "/etc/php.d/99-php.ini"

if ! command -v "composer" >"/dev/null" 2>&1; then
    curl -fsSL "https://getcomposer.org/installer" >"/tmp/composer-setup.php"

    sudo dnf install --assumeyes "coreutils"

    COMPOSER_INSTALLER_HASH="e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02"
    echo "${COMPOSER_INSTALLER_HASH} /tmp/composer-setup.php" >"/tmp/composer-setup.sha384"
    if ! sha384sum --check "/tmp/composer-setup.sha384" --strict --status; then
        echo "Composer installer script has been either been upgraded or tampered with."
        exit 1
    fi

    mkdir -p "${HOME}/bin"
    php "/tmp/composer-setup.php" --install-dir="${HOME}/bin" --filename="composer"

    rm "/tmp/composer-setup.php";
    rm "/tmp/composer-setup.sha384"
fi
