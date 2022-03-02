#!/bin/bash
set -euf -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIST_DIR=$SCRIPT_DIR/dist

SRC_C_FLAGS="-pthread" 
SRC_C_FLAGS="$SRC_C_FLAGS -I$DIST_DIR/usr/local/include"
SRC_C_FLAGS="$SRC_C_FLAGS -I$DIST_DIR/usr/local/include/piduino/arduino"
SRC_C_FLAGS="$SRC_C_FLAGS -I$DIST_DIR/usr/local/include/lmic"
SRC_LD_FLAGS="-L$DIST_DIR/usr/local/lib -llmic -lpiduino"
SRC_LD_FLAGS="$SRC_LD_FLAGS -lcppdb -ldl -ludev -lpthread"

g++ $1 -o $2 $SRC_C_FLAGS $SRC_LD_FLAGS
