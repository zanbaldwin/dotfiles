add_to_path "${HOME}/.phpenv/bin"
add_to_path "${HOME}/.phpenv/shims"

command -v "brew" >"/dev/null" 2>&1 && {
    # If we're on macOS, the dependencies would have been install via Homebrew.
    export PHP_BUILD_CONFIGURE_OPTS="--with-zlib-dir=$(brew --prefix zlib) --with-bz2=$(brew --prefix bzip2) --with-iconv=$(brew --prefix libiconv) --with-readline=$(brew --prefix readline) --with-libedit=$(brew --prefix libedit) --with-tidy=$(brew --prefix tidy-html5) --with-pdo-pgsql=$(brew --prefix postgresql@12) --with-pear"
}

if [ -f "${HOME}/.phpenv/completions/phpenv.bash" ]; then
    source "${HOME}/.phpenv/completions/phpenv.bash"
    phpenv rehash 2>/dev/null
fi

phpenv() {
    local command
    command="$1"
    if [ "$#" -gt 0 ]; then
      shift
    fi

    case "$command" in
    shell)
      eval `phpenv "sh-$command" "$@"`;;
    *)
      command phpenv "$command" "$@";;
    esac
}
