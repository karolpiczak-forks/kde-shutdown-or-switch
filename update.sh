#!/bin/bash

kpackagetool6 -t Plasma/Applet -u package
systemctl --user restart plasma-plasmashell.service
