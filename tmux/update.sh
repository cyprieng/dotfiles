#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

wget -O "$BASEDIR/tmux.conf" https://raw.githubusercontent.com/gpakosz/.tmux/refs/heads/master/.tmux.conf
