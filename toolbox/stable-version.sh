function local_stable_version {
    GIT_DIR="${1:-$(pwd)}"
    git -C "${GIT_DIR}" tag --list --sort="version:refname" \
        | \grep -P -e '\d+\.\d+' \
        | \grep -P -v 'alpha|ALPHA|beta|BETA|rc|RC|-' \
        | sort --version-sort \
        | tail -n1
}

function remote_stable_version {
    git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' "${1}" \
       | \grep -v '\^' \
       | \grep -P -e '\d+\.\d+' \
       | \grep -P -v 'alpha|ALPHA|beta|BETA|rc|RC|-' \
       | cut -d'/' -f3 \
       | sort --version-sort \
       | tail -n1
}