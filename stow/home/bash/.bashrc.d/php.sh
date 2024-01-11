#!/bin/bash

command -v "php" >"/dev/null" 2>&1 && {
    export PHP_CS_FIXER_IGNORE_ENV=1

    # Make sure that XDebug is either not enabled or not in mode "debug" in the CLI configuration. If you wish to enable
    # debugging via XDebug while using PHP's CLI SAPI, use the command alias "xdebug" instead.
    alias xdebug='php -dzend_extension=xdebug.so -dxdebug.mode=debug,develop'

    # Vulcan Logic Disassembler
    # To install: `pecl install vld` (currently in beta only, so install vld-beta instead).
    alias vld='php -d vld.active=1 -d vld.execute=0 -d vld.dump_paths=1 -d vld.save_paths=1 -d vld.verbosity=1'

    command -v "composer" >"/dev/null" 2>&1 && {
        add_to_path "$(XDEBUG_MODE="off" composer global config bin-dir --absolute 2>/dev/null)"
    }
}
