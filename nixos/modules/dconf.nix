{ pkgs, lib, ... }: {
    environment = {
        systemPackages = with pkgs.gnome; [
            nautilus
        ] ++ (with pkgs.gnomeExtensions; [
            alphabetical-app-grid
            blur-my-shell
            gsnap
            notification-timeout
        ]);

    };
    programs.dconf = {
        enable = true;
        settings = with lib.gvariant; {
            "org/gnome/desktop/calendar" = {
                show-weekdate = false;
            };
            "org/gnome/desktop/default-applications/terminal" = {
                exec = "alacritty";
                exec-arg = [];
            };
            "org/gnome/desktop/background" = {
                show-desktop-icons = false;
            };
            "org/gnome/desktop/input-sources" = {
                sources = [(mkTuple [ "xkb" "us" ])];
                xkb-options = [
                    "compose:ralt"
                    "caps:swapescape"
                    "terminate:ctrl_alt_bksp"
                    "mod_led:compose"
                ];
            };
            "org/gnome/desktop/interface" = {
                color-scheme = "prefer-dark";
                show-batter-percentage = true;
                clock-format = "24h";
                clock-show-date = true;
                clock-show-seconds = false;
                clock-show-weekday = true;
                enable-hot-corners = false;
                show-battery-percentage = true;
            };
            "org/gnome/desktop/peripherals/keyboard" = {
                numlock-state = true;
            };
            "org/gnome/system/location" = {
                enabled = false;
            };
            "org/gnome/desktop/peripherals/touchpad" = {
                tap-to-click = true;
                two-finger-scrolling-enabled = true;
            };
            "org/gnome/desktop/privacy" = {
                remember-recent-files = false;
            };
            "org/gnome/desktop/session" = {
                idle-delay = mkUint32 900;
            };
            "org/gnome/desktop/wm/keybindings" = {
                close = ["<Alt>F4"];
                maximize = ["<Super>Up"];
                minimize = ["<Super>Down"];
                move-to-workspace-left = ["<Control><Shift><Alt>Left" ];
                move-to-workspace-right = ["<Control><Shift><Alt>Right"];
                panel-run-dialog = ["<Alt>F2"];
                show-desktop = ["<Super>d"];
                switch-applications = ["<Super>Tab"];
                switch-applications-backwards = ["<Shift><Super>Tab"];
                switch-to-workspace-left = ["<Control><Alt>Left"];
                switch-to-workspace-right = ["<Control><Alt>Right"];
                switch-to-workspace-1 = ["<Super>1"];
                switch-to-workspace-2 = ["<Super>2"];
                switch-to-workspace-3 = ["<Super>3"];
                switch-to-workspace-4 = ["<Super>4"];
                switch-windows = ["<Alt>Tab"];
                switch-windows-backwards = ["<Shift><Alt>Tab"];
                toggle-fullscreen = ["F11"];
            };
            "org/gnome/desktop/wm/preferences" = {
                button-layout = "appmenu:minimize,maximize,close";
            };
            "org/gnome/mutter" = {
                workspaces-only-on-primary = false;
                edge-tiling = false;
            };
            "org/gtk/gtk4/settings/file-chooser" = {
                date-format = "regular";
                location-mode = "path-bar";
                show-size-column = true;
                sort-column = "name";
                sort-order = "ascending";
                sort-directories-first = true;
                show-hidden = true;
                view-type = "list";
            };

            # Keyboard Shortcuts for the Muscle Memory
            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            binding = "<Control><Alt>t";
            command = "alacritty";
            name = "Terminal";
            };
            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
            binding = "<Control><Alt>f";
            command = "/usr/bin/env nautilus";
            name = "File Manager";
            };
            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
            binding = "<Control><Alt>b";
            command = "flatpak run com.bitwarden.desktop";
            name = "Password Manager";
            };
            "org/gnome/settings-daemon/plugins/media-keys" = {
                custom-keybindings = [
                    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
                    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
                    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
                ];
            };

            # Extensions
            "org/gnome/shell" = {
                enabled-extensions = [
                    "blur-my-shell@aunetx"
                    "gSnap@micahosborne"
                    "AlphabeticalAppGrid@stuarthayhurst"
                    "notification-timeout@chlumskyvaclav.gmail.com"
                ];
            };
            # Extension Configuration
            "org/gnome/shell/extensions/alphabetical-app-grid" = {
                folder-order-position = "end";
                sort-folder-contents = true;
            };
            "org/gnome/shell/extensions/blur-my-shell" = {};
            "org/gnome/shell/extensions/gsnap" = {
                use-modifier = true;
                span-multiple-zones = true;
                window-margin = mkUint32 5;
            };
            "org/gnome/shell/extensions/notification-timeout" = {
                ignore-idle = false;
                always-normal = true;
                timeout = mkUint32 5000;
            };

        };
        locks = [];
    };
}
