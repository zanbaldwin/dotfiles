add_to_path "${HOME}/.phpenv/bin"
add_to_path "${HOME}/.phpenv/shims"

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
