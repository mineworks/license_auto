#!/usr/bin/env bash
dpkg -l | grep -e "^ii.*" | awk '{ print $2","$3","$4 }' > dpkg_list.txt