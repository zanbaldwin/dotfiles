export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"

if [ ! -s "${NVM_DIR}/nvm.sh" ] && command -v 'fnm' >'/dev/null' 2>&1; then
    alias nvm='fnm'
    eval "$(fnm env --use-on-cd --shell 'bash')"
fi
