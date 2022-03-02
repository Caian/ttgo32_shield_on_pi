#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIST_DIR=$SCRIPT_DIR/dist

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$DIST_DIR/usr/local/lib"

$1
