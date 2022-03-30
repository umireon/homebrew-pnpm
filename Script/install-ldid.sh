#!/bin/bash
set -euo pipefail
sudo apt-get update
sudo apt-get install git build-essential libplist-dev libssl-dev openssl qemu-user-binfmt
cd /tmp
git clone git://git.saurik.com/ldid.git
cd ldid
git submodule update --init
gcc -I. -c -o lookup2.o lookup2.c
g++ -std=c++11 -o ldid lookup2.o ldid.cpp -I. -lcrypto -lplist -lxml2
sudo mv ldid /usr/local/bin
