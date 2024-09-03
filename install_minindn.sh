#!/bin/bash

set -eou pipefail

INSTALL_DIR="$HOME"
#INSTALL_DIR=/opt/ndn/

mkdir -p "$INSTALL_DIR"

# make sure your user has read/write access to the repo
git clone git@github.com:rit-ndn/mini-ndn.git "$INSTALL_DIR/mini-ndn"
cd "$INSTALL_DIR/mini-ndn"
./install.sh --source -y

# after mini-ndn installs, must go in and change the git repos for the sub-modules
git clone git@github.com:rit-ndn/NFD.git "$INSTALL_DIR/mini-ndn/dl/NFD"
git clone git@github.com:rit-ndn/ndn-cxx.git "$INSTALL_DIR/mini-ndn/dl/ndn-cxx"
git clone git@github.com:rit-ndn/NLSR.git "$INSTALL_DIR/mini-ndn/dl/NLSR"

# now we can compile the sub-modules
cd "$INSTALL_DIR/mini-ndn/dl/NFD"
git submodule update --init
./waf configure
./waf
sudo ./waf install

cd "$INSTALL_DIR/mini-ndn/dl/ndn-cxx"
./waf configure --with-examples
./waf
sudo ./waf install

cd "$INSTALL_DIR/mini-ndn/dl/NLSR"
./waf configure
./waf
sudo ./waf install

sudo ldconfig

# now we can run the emulator, if we want
cd "$INSTALL_DIR/mini-ndn"
#./dag_run.sh
