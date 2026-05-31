#!/bin/bash
shutdown_opt=' Shutdown'
reboot_opt=' Reboot'
hibernate_opt=' Hibernate'

chosen=$(printf "%s
%s
%s" "$shutdown_opt" "$reboot_opt" "$hibernate_opt" | rofi -dmenu -p " Power" -theme-str '
window { width: 600px; }
listview { lines: 3; }
')

case "$chosen" in
    *Shutdown)  sudo systemctl poweroff ;;
    *Reboot)    sudo systemctl reboot ;;
    *Hibernate) sudo systemctl hibernate ;;
esac
