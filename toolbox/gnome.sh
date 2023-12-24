#!/bin/bash

# Eventually replace this with Stowed DConf settings.

dconf write "/org/gnome/desktop/input-sources/xkb-options" "['caps:swapescape']"
dconf write "/org/gnome/desktop/calendar/show-weekdate" "false"
dconf write "/org/gnome/desktop/interface/clock-show-weekday" "true"
dconf write "/org/gnome/desktop/wm/preferences/button-layout" "'appmenu:minimize,maximize,close'"
dconf write "/org/gnome/system/location/enabled" "false"
