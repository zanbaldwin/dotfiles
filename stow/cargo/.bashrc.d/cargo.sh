#!/bin/bash

command -v 'cargo' >'/dev/null' 2>&1 && command -v 'kache' >'/dev/null' 2>&1 && {
    # Some crates, like `aws-lc-sys`, strip everything after the first word.
    export CC='kache-cc'
    export CXX='kache-cxx'
}
