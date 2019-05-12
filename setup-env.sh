#!/bin/bash

set -ex

mkdir temp && cd temp

# Make sure the dependencies are installed
apt -y update
apt -y install libarchive-dev libssl-dev libcurl4-openssl-dev pkg-config

# Download pacman and patches
wget https://sources.archlinux.org/other/pacman/pacman-5.1.0.tar.gz
wget https://raw.githubusercontent.com/z3ntu/archhurd_packages/master/pacman/0001-Hurd-define-PATH_MAX.patch
wget https://raw.githubusercontent.com/z3ntu/archhurd_packages/master/pacman/0002-Hurd-define-PIPE_BUF.patch
wget https://raw.githubusercontent.com/z3ntu/archhurd_packages/master/pacman/0003-Hurd-use-FAKED_MODE-instead-of-FAKEROOTKEY-for-faker.patch
wget https://raw.githubusercontent.com/z3ntu/archhurd_packages/master/pacman/0004-Hurd-use-V-for-fakeroot-version-output.patch
wget https://raw.githubusercontent.com/z3ntu/archhurd_packages/master/pacman/0001-makepkg-Clear-ERR-trap-before-trying-to-restore-it.patch
wget https://raw.githubusercontent.com/z3ntu/archhurd_packages/master/pacman/0002-makepkg-Don-t-use-parameterless-return.patch

tar xvzf pacman-5.1.0.tar.gz
cd pacman-5.1.0

# Hurd-specific patches
patch -Np1 -i ../0001-Hurd-define-PATH_MAX.patch
patch -Np1 -i ../0002-Hurd-define-PIPE_BUF.patch
patch -Np1 -i ../0003-Hurd-use-FAKED_MODE-instead-of-FAKEROOTKEY-for-faker.patch
patch -Np1 -i ../0004-Hurd-use-V-for-fakeroot-version-output.patch
# Fix install_packages failure exit code, required by makechrootpkg
patch -Np1 -i ../0001-makepkg-Clear-ERR-trap-before-trying-to-restore-it.patch
patch -Np1 -i ../0002-makepkg-Don-t-use-parameterless-return.patch

# Compile and install pacman
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-doc --with-scriptlet-shell=/bin/bash --with-ldconfig=/sbin/ldconfig
make -j2
make DESTDIR=~/install install

cd ..

# Download and "install" pacstrap
wget https://github.com/z3ntu/archhurd_packages_binary/raw/master/archhurd-install-scripts-18-1-any.pkg.tar.xz
tar xJf archhurd-install-scripts-18-1-any.pkg.tar.xz
cp -v usr/bin/pacstrap ~/install/usr/bin/

wget https://raw.githubusercontent.com/z3ntu/archhurd_packages/master/pacman/pacman.conf
sed -i 's|^SigLevel|#SigLevel|' pacman.conf
sed -i 's|^LocalFileSigLevel|#LocalFileSigLevel|' pacman.conf
mkdir /etc/pacman.d
echo 'Server = https://files.archhurd.org/$repo/os/$arch' > /etc/pacman.d/mirrorlist
mv pacman.conf /etc/
mkdir /var/lib/pacman

