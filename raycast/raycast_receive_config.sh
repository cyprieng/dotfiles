#!/bin/bash

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# Receive config from croc
(cd "$BASEDIR" && croc --overwrite)

# Open config
open "$BASEDIR"/config.rayconfig
