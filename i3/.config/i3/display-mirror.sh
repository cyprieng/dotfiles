#!/bin/bash
xrandr --output HDMI-0 --mode 3840x2160 --rate 60 --primary \
       --output HDMI-1 --mode 3840x2160 --rate 60 --same-as HDMI-0
