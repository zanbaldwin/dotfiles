#!/bin/bash

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f -- "$0")")"
if [ -f "${TOOLBOX_SCRIPT_DIRECTORY}/toolbox.sh" ]; then
    source "${TOOLBOX_SCRIPT_DIRECTORY}/toolbox.sh"
fi

sudo dnf install --assumeyes \
    "ansible" \
    "php" \
    "php-bcmath" \
    "php-devel" \
    "php-ffi" \
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
    "php-xml"

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

    COMPOSER_INSTALLER_HASH="dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6"
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
