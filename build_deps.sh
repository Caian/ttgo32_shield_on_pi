#!/bin/bash
set -euf -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DEPS_DIR=$SCRIPT_DIR/deps
DIST_DIR=$SCRIPT_DIR/dist

echo "##########################################################"
echo "#                                                        #"
echo "# Warning: You must set a LoRa region that is compatible #"
echo "# with your device before proceeding with the build!     #" 
echo "#                                                        #"
echo "# Please edit the following file:                        #"
echo "# deps/arduino-lmic/project_config/lmic_project_config.h #"
echo "#                                                        #"
echo "# For more information read:                             #"
echo "# deps/arduino-lmic/README.md                            #"
echo "#                                                        #"
echo "# INCOMPATIBLE REGION SETTINGS MAY DAMAGE YOUR DEVICE!   #"
echo "#                                                        #"
echo "# Proceeding with the build in 10 seconds...             #"
echo "#                                                        #"
echo "##########################################################"

sleep 10

BUILD_PIDUINO=1
BUILD_LMIC=1

mkdir -p $DIST_DIR

#################################################

PIDUINO_DIR=$DEPS_DIR/piduino
PIDUINO_BUILD=$PIDUINO_DIR/build

if [[ "$BUILD_PIDUINO" == "1" ]]
then
    echo "Building piduino..."

    rm -rf $PIDUINO_BUILD
    mkdir -p $PIDUINO_BUILD
    pushd $PIDUINO_BUILD >/dev/null

    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$DIST_DIR/usr/local \
      -DINSTALL_CODELITE_DIR=$DIST_DIR/usr/share/codelite \
      -DINSTALL_ETC_DIR=$DIST_DIR/etc \
      ..

    make
    make install

    popd >/dev/null
fi

#################################################

echo "Building LMIC..."

LMIC_DIR=$DEPS_DIR/arduino-lmic
LMIC_SRC=$LMIC_DIR/src
LMIC_DIST=$DIST_DIR/usr/local/lib
LMIC_INC=$DIST_DIR/usr/local/include/lmic
LMIC_C_FLAGS="-pthread -I$DIST_DIR/usr/local/include -I$DIST_DIR/usr/local/include/piduino/arduino"
LMID_LD_FLAGS="-L$DIST_DIR/usr/local/lib -lpiduino -lcppdb -ldl -ludev -lpthread"

if [[ "$BUILD_LMIC" == "1" ]]
then
    mkdir -p $LMIC_DIST
    pushd $LMIC_DIR >/dev/null

    for src in $(find ./src -name "*.c*")
    do
        echo $src
        src_dir=$(dirname "$src")
        src_file=$(basename "$src")

        pushd $src_dir >/dev/null

        if [[ "$(grep -e 'noInterrupts()' -e 'interrupts()' $src_file)" != "" ]]
        then
            echo "Patching interrupts..."
            name="${src_file%.*}"
            ext="${src_file##*.}"
            tmp_file=${name}_patched.$ext
            sed 's/\snoInterrupts()/\/*noInterrupts()*\//g; s/\sinterrupts()/\/*interrupts()*\//g' <$src_file >$tmp_file
            src_file=$tmp_file
        fi

        gcc -c $src_file -I$LMIC_SRC $LMIC_C_FLAGS

        if [[ -v tmp_file ]]
        then
            rm $tmp_file
            unset tmp_file
        fi

        popd >/dev/null
    done

    gcc -shared -fPIC -o $LMIC_DIST/liblmic.so $(find ./src -name "*.o") $LMID_LD_FLAGS

    mkdir -p $LMIC_INC

    cfg_file="./project_config/lmic_project_config.h"
    cfg_to="$LMIC_INC/../project_config"
    echo $cfg_file
    mkdir -p $cfg_to
    cp $cfg_file $cfg_to

    pushd src >/dev/null

    for hdr in $(find . -name "*.h*")
    do
        echo $hdr
        hdr_dir=$(dirname "$hdr")
        hdr_to=$LMIC_INC/$hdr_dir

        mkdir -p $hdr_to
        cp $hdr $hdr_to
    done

    popd >/dev/null

    popd >/dev/null
fi

