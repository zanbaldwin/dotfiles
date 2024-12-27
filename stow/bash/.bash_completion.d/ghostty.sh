_ghostty() {

  # -o nospace requires we add back a space when a completion is finished
  # and not part of a --key= completion
  _add_spaces() {
    for idx in "${!COMPREPLY[@]}"; do
      [ -n "${COMPREPLY[idx]}" ] && COMPREPLY[idx]="${COMPREPLY[idx]} ";
    done
  }

  _fonts() {
    local IFS=$'\n'
    mapfile -t COMPREPLY < <( compgen -P '"' -S '"' -W "$($ghostty +list-fonts | grep '^[A-Z]' )" -- "$cur")
  }

  _themes() {
    local IFS=$'\n'
    mapfile -t COMPREPLY < <( compgen -P '"' -S '"' -W "$($ghostty +list-themes | sed -E 's/^(.*) \(.*$/\1/')" -- "$cur")
  }

  _files() {
    mapfile -t COMPREPLY < <( compgen -o filenames -f -- "$cur" )
    for i in "${!COMPREPLY[@]}"; do
      if [[ -d "${COMPREPLY[i]}" ]]; then
        COMPREPLY[i]="${COMPREPLY[i]}/";
      fi
      if [[ -f "${COMPREPLY[i]}" ]]; then
        COMPREPLY[i]="${COMPREPLY[i]} ";
      fi
    done
  }

  _dirs() {
    mapfile -t COMPREPLY < <( compgen -o dirnames -d -- "$cur" )
    for i in "${!COMPREPLY[@]}"; do
      if [[ -d "${COMPREPLY[i]}" ]]; then
        COMPREPLY[i]="${COMPREPLY[i]}/";
      fi
    done
    if [[ "${#COMPREPLY[@]}" == 0 && -d "$cur" ]]; then
      COMPREPLY=( "$cur " )
    fi
  }

  _handle_config() {
    local config="--help"
    config+=" --version"
    config+=" --font-family="
    config+=" --font-family-bold="
    config+=" --font-family-italic="
    config+=" --font-family-bold-italic="
    config+=" --font-style="
    config+=" --font-style-bold="
    config+=" --font-style-italic="
    config+=" --font-style-bold-italic="
    config+=" --font-synthetic-style="
    config+=" --font-feature="
    config+=" --font-size="
    config+=" --font-variation="
    config+=" --font-variation-bold="
    config+=" --font-variation-italic="
    config+=" --font-variation-bold-italic="
    config+=" --font-codepoint-map="
    config+=" '--font-thicken '"
    config+=" --adjust-cell-width="
    config+=" --adjust-cell-height="
    config+=" --adjust-font-baseline="
    config+=" --adjust-underline-position="
    config+=" --adjust-underline-thickness="
    config+=" --adjust-strikethrough-position="
    config+=" --adjust-strikethrough-thickness="
    config+=" --adjust-overline-position="
    config+=" --adjust-overline-thickness="
    config+=" --adjust-cursor-thickness="
    config+=" --adjust-cursor-height="
    config+=" --adjust-box-thickness="
    config+=" --grapheme-width-method="
    config+=" --freetype-load-flags="
    config+=" --theme="
    config+=" --background="
    config+=" --foreground="
    config+=" --selection-foreground="
    config+=" --selection-background="
    config+=" '--selection-invert-fg-bg '"
    config+=" --minimum-contrast="
    config+=" --palette="
    config+=" --cursor-color="
    config+=" '--cursor-invert-fg-bg '"
    config+=" --cursor-opacity="
    config+=" --cursor-style="
    config+=" '--cursor-style-blink '"
    config+=" --cursor-text="
    config+=" '--cursor-click-to-move '"
    config+=" '--mouse-hide-while-typing '"
    config+=" --mouse-shift-capture="
    config+=" --mouse-scroll-multiplier="
    config+=" --background-opacity="
    config+=" --background-blur-radius="
    config+=" --unfocused-split-opacity="
    config+=" --unfocused-split-fill="
    config+=" --command="
    config+=" --initial-command="
    config+=" '--wait-after-command '"
    config+=" --abnormal-command-exit-runtime="
    config+=" --scrollback-limit="
    config+=" --link="
    config+=" '--link-url '"
    config+=" '--fullscreen '"
    config+=" --title="
    config+=" --class="
    config+=" --x11-instance-name="
    config+=" --working-directory="
    config+=" --keybind="
    config+=" --window-padding-x="
    config+=" --window-padding-y="
    config+=" '--window-padding-balance '"
    config+=" --window-padding-color="
    config+=" '--window-vsync '"
    config+=" '--window-inherit-working-directory '"
    config+=" '--window-inherit-font-size '"
    config+=" '--window-decoration '"
    config+=" --window-title-font-family="
    config+=" --window-theme="
    config+=" --window-colorspace="
    config+=" --window-height="
    config+=" --window-width="
    config+=" --window-save-state="
    config+=" '--window-step-resize '"
    config+=" --window-new-tab-position="
    config+=" --resize-overlay="
    config+=" --resize-overlay-position="
    config+=" --resize-overlay-duration="
    config+=" '--focus-follows-mouse '"
    config+=" --clipboard-read="
    config+=" --clipboard-write="
    config+=" '--clipboard-trim-trailing-spaces '"
    config+=" '--clipboard-paste-protection '"
    config+=" '--clipboard-paste-bracketed-safe '"
    config+=" --image-storage-limit="
    config+=" --copy-on-select="
    config+=" --click-repeat-interval="
    config+=" --config-file="
    config+=" '--config-default-files '"
    config+=" '--confirm-close-surface '"
    config+=" '--quit-after-last-window-closed '"
    config+=" --quit-after-last-window-closed-delay="
    config+=" '--initial-window '"
    config+=" --quick-terminal-position="
    config+=" --quick-terminal-screen="
    config+=" --quick-terminal-animation-duration="
    config+=" '--quick-terminal-autohide '"
    config+=" --shell-integration="
    config+=" --shell-integration-features="
    config+=" --osc-color-report-format="
    config+=" '--vt-kam-allowed '"
    config+=" --custom-shader="
    config+=" --custom-shader-animation="
    config+=" --macos-non-native-fullscreen="
    config+=" --macos-titlebar-style="
    config+=" --macos-titlebar-proxy-icon="
    config+=" --macos-option-as-alt="
    config+=" '--macos-window-shadow '"
    config+=" '--macos-auto-secure-input '"
    config+=" '--macos-secure-input-indication '"
    config+=" --macos-icon="
    config+=" --macos-icon-frame="
    config+=" --macos-icon-ghost-color="
    config+=" --macos-icon-screen-color="
    config+=" --linux-cgroup="
    config+=" --linux-cgroup-memory-limit="
    config+=" --linux-cgroup-processes-limit="
    config+=" '--linux-cgroup-hard-fail '"
    config+=" --gtk-single-instance="
    config+=" '--gtk-titlebar '"
    config+=" --gtk-tabs-location="
    config+=" --adw-toolbar-style="
    config+=" '--gtk-wide-tabs '"
    config+=" '--gtk-adwaita '"
    config+=" '--desktop-notifications '"
    config+=" '--bold-is-bright '"
    config+=" --term="
    config+=" --enquiry-response="
    config+=" --auto-update="
    config+=" --auto-update-channel="

    case "$prev" in
      --font-family) _fonts ;;
      --font-family-bold) _fonts ;;
      --font-family-italic) _fonts ;;
      --font-family-bold-italic) _fonts ;;
      --font-style) return ;;
      --font-style-bold) return ;;
      --font-style-italic) return ;;
      --font-style-bold-italic) return ;;
      --font-synthetic-style) mapfile -t COMPREPLY < <( compgen -W "bold no-bold italic no-italic bold-italic no-bold-italic" -- "$cur" ); _add_spaces ;;
      --font-feature) return ;;
      --font-size) return ;;
      --font-variation) return ;;
      --font-variation-bold) return ;;
      --font-variation-italic) return ;;
      --font-variation-bold-italic) return ;;
      --font-codepoint-map) return ;;
      --font-thicken) return ;;
      --adjust-cell-width) return ;;
      --adjust-cell-height) return ;;
      --adjust-font-baseline) return ;;
      --adjust-underline-position) return ;;
      --adjust-underline-thickness) return ;;
      --adjust-strikethrough-position) return ;;
      --adjust-strikethrough-thickness) return ;;
      --adjust-overline-position) return ;;
      --adjust-overline-thickness) return ;;
      --adjust-cursor-thickness) return ;;
      --adjust-cursor-height) return ;;
      --adjust-box-thickness) return ;;
      --grapheme-width-method) mapfile -t COMPREPLY < <( compgen -W "legacy unicode" -- "$cur" ); _add_spaces ;;
      --freetype-load-flags) mapfile -t COMPREPLY < <( compgen -W "hinting no-hinting force-autohint no-force-autohint monochrome no-monochrome autohint no-autohint" -- "$cur" ); _add_spaces ;;
      --theme) _themes ;;
      --background) return ;;
      --foreground) return ;;
      --selection-foreground) return ;;
      --selection-background) return ;;
      --selection-invert-fg-bg) return ;;
      --minimum-contrast) return ;;
      --palette) return ;;
      --cursor-color) return ;;
      --cursor-invert-fg-bg) return ;;
      --cursor-opacity) return ;;
      --cursor-style) mapfile -t COMPREPLY < <( compgen -W "bar block underline block_hollow" -- "$cur" ); _add_spaces ;;
      --cursor-style-blink) return ;;
      --cursor-text) return ;;
      --cursor-click-to-move) return ;;
      --mouse-hide-while-typing) return ;;
      --mouse-shift-capture) mapfile -t COMPREPLY < <( compgen -W "false true always never" -- "$cur" ); _add_spaces ;;
      --mouse-scroll-multiplier) return ;;
      --background-opacity) return ;;
      --background-blur-radius) return ;;
      --unfocused-split-opacity) return ;;
      --unfocused-split-fill) return ;;
      --command) return ;;
      --initial-command) return ;;
      --wait-after-command) return ;;
      --abnormal-command-exit-runtime) return ;;
      --scrollback-limit) return ;;
      --link) return ;;
      --link-url) return ;;
      --fullscreen) return ;;
      --title) return ;;
      --class) return ;;
      --x11-instance-name) return ;;
      --working-directory) _dirs ;;
      --keybind) return ;;
      --window-padding-x) return ;;
      --window-padding-y) return ;;
      --window-padding-balance) return ;;
      --window-padding-color) mapfile -t COMPREPLY < <( compgen -W "background extend extend-always" -- "$cur" ); _add_spaces ;;
      --window-vsync) return ;;
      --window-inherit-working-directory) return ;;
      --window-inherit-font-size) return ;;
      --window-decoration) return ;;
      --window-title-font-family) return ;;
      --window-theme) mapfile -t COMPREPLY < <( compgen -W "auto system light dark ghostty" -- "$cur" ); _add_spaces ;;
      --window-colorspace) mapfile -t COMPREPLY < <( compgen -W "srgb display-p3" -- "$cur" ); _add_spaces ;;
      --window-height) return ;;
      --window-width) return ;;
      --window-save-state) mapfile -t COMPREPLY < <( compgen -W "default never always" -- "$cur" ); _add_spaces ;;
      --window-step-resize) return ;;
      --window-new-tab-position) mapfile -t COMPREPLY < <( compgen -W "current end" -- "$cur" ); _add_spaces ;;
      --resize-overlay) mapfile -t COMPREPLY < <( compgen -W "always never after-first" -- "$cur" ); _add_spaces ;;
      --resize-overlay-position) mapfile -t COMPREPLY < <( compgen -W "center top-left top-center top-right bottom-left bottom-center bottom-right" -- "$cur" ); _add_spaces ;;
      --resize-overlay-duration) return ;;
      --focus-follows-mouse) return ;;
      --clipboard-read) mapfile -t COMPREPLY < <( compgen -W "allow deny ask" -- "$cur" ); _add_spaces ;;
      --clipboard-write) mapfile -t COMPREPLY < <( compgen -W "allow deny ask" -- "$cur" ); _add_spaces ;;
      --clipboard-trim-trailing-spaces) return ;;
      --clipboard-paste-protection) return ;;
      --clipboard-paste-bracketed-safe) return ;;
      --image-storage-limit) return ;;
      --copy-on-select) mapfile -t COMPREPLY < <( compgen -W "false true clipboard" -- "$cur" ); _add_spaces ;;
      --click-repeat-interval) return ;;
      --config-file) _files ;;
      --config-default-files) return ;;
      --confirm-close-surface) return ;;
      --quit-after-last-window-closed) return ;;
      --quit-after-last-window-closed-delay) return ;;
      --initial-window) return ;;
      --quick-terminal-position) mapfile -t COMPREPLY < <( compgen -W "top bottom left right center" -- "$cur" ); _add_spaces ;;
      --quick-terminal-screen) mapfile -t COMPREPLY < <( compgen -W "main mouse macos-menu-bar" -- "$cur" ); _add_spaces ;;
      --quick-terminal-animation-duration) return ;;
      --quick-terminal-autohide) return ;;
      --shell-integration) mapfile -t COMPREPLY < <( compgen -W "none detect bash elvish fish zsh" -- "$cur" ); _add_spaces ;;
      --shell-integration-features) mapfile -t COMPREPLY < <( compgen -W "cursor no-cursor sudo no-sudo title no-title" -- "$cur" ); _add_spaces ;;
      --osc-color-report-format) mapfile -t COMPREPLY < <( compgen -W "none 8-bit 16-bit" -- "$cur" ); _add_spaces ;;
      --vt-kam-allowed) return ;;
      --custom-shader) _files ;;
      --custom-shader-animation) mapfile -t COMPREPLY < <( compgen -W "false true always" -- "$cur" ); _add_spaces ;;
      --macos-non-native-fullscreen) mapfile -t COMPREPLY < <( compgen -W "false true visible-menu" -- "$cur" ); _add_spaces ;;
      --macos-titlebar-style) mapfile -t COMPREPLY < <( compgen -W "native transparent tabs hidden" -- "$cur" ); _add_spaces ;;
      --macos-titlebar-proxy-icon) mapfile -t COMPREPLY < <( compgen -W "visible hidden" -- "$cur" ); _add_spaces ;;
      --macos-option-as-alt) return ;;
      --macos-window-shadow) return ;;
      --macos-auto-secure-input) return ;;
      --macos-secure-input-indication) return ;;
      --macos-icon) mapfile -t COMPREPLY < <( compgen -W "official custom-style" -- "$cur" ); _add_spaces ;;
      --macos-icon-frame) mapfile -t COMPREPLY < <( compgen -W "aluminum beige plastic chrome" -- "$cur" ); _add_spaces ;;
      --macos-icon-ghost-color) return ;;
      --macos-icon-screen-color) return ;;
      --linux-cgroup) mapfile -t COMPREPLY < <( compgen -W "never always single-instance" -- "$cur" ); _add_spaces ;;
      --linux-cgroup-memory-limit) return ;;
      --linux-cgroup-processes-limit) return ;;
      --linux-cgroup-hard-fail) return ;;
      --gtk-single-instance) mapfile -t COMPREPLY < <( compgen -W "desktop false true" -- "$cur" ); _add_spaces ;;
      --gtk-titlebar) return ;;
      --gtk-tabs-location) mapfile -t COMPREPLY < <( compgen -W "top bottom left right hidden" -- "$cur" ); _add_spaces ;;
      --adw-toolbar-style) mapfile -t COMPREPLY < <( compgen -W "flat raised raised-border" -- "$cur" ); _add_spaces ;;
      --gtk-wide-tabs) return ;;
      --gtk-adwaita) return ;;
      --desktop-notifications) return ;;
      --bold-is-bright) return ;;
      --term) return ;;
      --enquiry-response) return ;;
      --auto-update) mapfile -t COMPREPLY < <( compgen -W "off check download" -- "$cur" ); _add_spaces ;;
      --auto-update-channel) return ;;
      *) mapfile -t COMPREPLY < <( compgen -W "$config" -- "$cur" ) ;;
    esac

    return 0
  }

  _handle_actions() {
    local list_fonts="--family= --style= '--bold ' '--italic ' --help"
    local list_keybinds="'--default ' '--docs ' '--plain ' --help"
    local list_themes="'--path ' '--plain ' --help"
    local list_actions="'--docs ' --help"
    local show_config="'--default ' '--changes-only ' '--docs ' --help"
    local validate_config="--config-file= --help"
    local show_face="--cp= --string= --style= --presentation= --help"

    case "${COMP_WORDS[1]}" in
      +list-fonts)
        case $prev in
          --family) return;;
          --style) return;;
          --bold) return ;;
          --italic) return ;;
          *) mapfile -t COMPREPLY < <( compgen -W "$list_fonts" -- "$cur" ) ;;
        esac
      ;;
      +list-keybinds)
        case $prev in
          --default) return ;;
          --docs) return ;;
          --plain) return ;;
          *) mapfile -t COMPREPLY < <( compgen -W "$list_keybinds" -- "$cur" ) ;;
        esac
      ;;
      +list-themes)
        case $prev in
          --path) return ;;
          --plain) return ;;
          *) mapfile -t COMPREPLY < <( compgen -W "$list_themes" -- "$cur" ) ;;
        esac
      ;;
      +list-actions)
        case $prev in
          --docs) return ;;
          *) mapfile -t COMPREPLY < <( compgen -W "$list_actions" -- "$cur" ) ;;
        esac
      ;;
      +show-config)
        case $prev in
          --default) return ;;
          --changes-only) return ;;
          --docs) return ;;
          *) mapfile -t COMPREPLY < <( compgen -W "$show_config" -- "$cur" ) ;;
        esac
      ;;
      +validate-config)
        case $prev in
          --config-file) return ;;
          *) mapfile -t COMPREPLY < <( compgen -W "$validate_config" -- "$cur" ) ;;
        esac
      ;;
      +show-face)
        case $prev in
          --cp) return;;
          --string) return;;
          --style) mapfile -t COMPREPLY < <( compgen -W "regular bold italic bold_italic" -- "$cur" ); _add_spaces ;;
          --presentation) mapfile -t COMPREPLY < <( compgen -W "text emoji" -- "$cur" ); _add_spaces ;;
          *) mapfile -t COMPREPLY < <( compgen -W "$show_face" -- "$cur" ) ;;
        esac
      ;;
      *) mapfile -t COMPREPLY < <( compgen -W "--help" -- "$cur" ) ;;
    esac

    return 0
  }

  # begin main logic
  local topLevel="-e"
  topLevel+=" --help"
  topLevel+=" --version"
  topLevel+=" +list-fonts"
  topLevel+=" +list-keybinds"
  topLevel+=" +list-themes"
  topLevel+=" +list-colors"
  topLevel+=" +list-actions"
  topLevel+=" +show-config"
  topLevel+=" +validate-config"
  topLevel+=" +crash-report"
  topLevel+=" +show-face"

  local cur=""; local prev=""; local prevWasEq=false; COMPREPLY=()
  local ghostty="$1"

  # script assumes default COMP_WORDBREAKS of roughly $' \t\n"\'><=;|&(:'
  # if = is missing this script will degrade to matching on keys only.
  # eg: --key=
  # this can be improved if needed see: https://github.com/ghostty-org/ghostty/discussions/2994

  if [ "$2" = "=" ]; then cur=""
  else                    cur="$2"
  fi

  if [ "$3" = "=" ]; then prev="${COMP_WORDS[COMP_CWORD-2]}"; prevWasEq=true;
  else                    prev="${COMP_WORDS[COMP_CWORD-1]}"
  fi

  # current completion is double quoted add a space so the curor progresses
  if [[ "$2" == \"*\" ]]; then
    COMPREPLY=( "$cur " );
    return;
  fi

  case "$COMP_CWORD" in
    1)
      case "${COMP_WORDS[1]}" in
        -e | --help | --version) return 0 ;;
        --*) _handle_config ;;
        *) mapfile -t COMPREPLY < <( compgen -W "${topLevel}" -- "$cur" ); _add_spaces ;;
      esac
      ;;
    *)
      case "$prev" in
        -e | --help | --version) return 0 ;;
        *)
          if [[ "=" != "${COMP_WORDS[COMP_CWORD]}" && $prevWasEq != true ]]; then
            # must be completing with a space after the key eg: '--<key> '
            # clear out prev so we don't run any of the key specific completions
            prev=""
          fi
        
          case "${COMP_WORDS[1]}" in
            --*) _handle_config ;;
            +*) _handle_actions ;;
          esac
          ;;
      esac
      ;;
  esac

  return 0
}

complete -o nospace -o bashdefault -F _ghostty ghostty
