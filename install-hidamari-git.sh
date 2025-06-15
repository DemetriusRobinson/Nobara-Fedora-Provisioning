#!/bin/bash

cd ~/Applications/BuildProjects/
git clone https://github.com/jeffshee/hidamari.git
cd hidamari

# 1. Install Required Build Dependencies
sudo dnf install meson ninja-build python3-pip gtk4-devel libadwaita-devel python3-gobject-devel libappstream-glib
pip3 install -r requirements.txt

# 2. Create Build Directory and Compile
mkdir build
cd build
meson setup --prefix=/usr ..
ninja
sudo ninja install
# Or test run without installing
# ./src/io.github.jeffshee.Hidamari
