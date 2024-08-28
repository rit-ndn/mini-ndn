#! /bin/bash


INSTALL_DIR=~
#INSTALL_DIR=/opt/ndn/

cd $INSTALL_DIR

git clone git@github.com:rit-ndn/mini-ndn.git
cd mini-ndn
./install.sh --source

# after mini-ndn installs, must go in and change the git repos for the sub-modules
cd dl
git clone git@github.com:rit-ndn/NFD.git
git clone git@github.com:rit-ndn/ndn-cxx.git
git clone git@github.com:rit-ndn/NLSR.git

# now we can compile the sub-modules
cd NFD
git submodule update --init
./waf configure
./waf
sudo .waf install

cd ../ndn-cxx
./waf configure --with-examples
./waf
sudo ./waf install

cd ../NLSR
./waf configure
./waf
sudo ./waf install

sudo ldconfig

# now we can run the emulator
cd ../../
#./dag_run.sh





