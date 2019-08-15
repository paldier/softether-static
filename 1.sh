#!/bin/bash

set -e
set -x

mkdir -p ~/softether && cd ~/softether
export STAGING_DIR=~/K3C/staging_dir/target-mips_mips32_uClibc-0.9.33.2_grx350_1600_opensrc_71_sample
export PATH=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin:$PATH
CC=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-gcc
BASE=`pwd`
SRC=$BASE/src
WGET="wget --prefer-family=IPv4"
DEST=$BASE/opt
LDFLAGS="-L$DEST/lib -Wl,--gc-sections"
CPPFLAGS="-I$DEST/include"
CFLAGS="-Os -pipe -mips32r2 -mno-branch-likely -mtune=1004kc -ffunction-sections -fdata-sections"
CXXFLAGS=$CFLAGS
CONFIGURE="./configure --prefix=/opt --host=mips-openwrt-linux"
MAKE="make"

mkdir -p $SRC

######## ####################################################################
# ZLIB # ####################################################################
######## ####################################################################

mkdir -p $SRC/zlib && cd $SRC/zlib
[ ! -e "zlib-1.2.11.tar.gz" ] && $WGET https://zlib.net/zlib-1.2.11.tar.gz
tar zxvf zlib-1.2.11.tar.gz
cd zlib-1.2.11
CC=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-gcc \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
CROSS_PREFIX=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux- \
./configure \
--prefix=/opt \
--static

$MAKE
make install DESTDIR=$BASE

########### #################################################################
# OPENSSL # #################################################################
########### #################################################################

mkdir -p $SRC/openssl && cd $SRC/openssl
[ ! -e "openssl-1.0.2o.tar.gz" ] && $WGET https://www.openssl.org/source/openssl-1.0.2o.tar.gz
tar zxvf openssl-1.0.2o.tar.gz
cd openssl-1.0.2o

./Configure linux-mips32 \
-Os -pipe -mips32r2 -mno-branch-likely -mtune=1004kc -ffunction-sections -fdata-sections -Wl,--gc-sections \
--prefix=/opt zlib \
--with-zlib-lib=$DEST/lib \
--with-zlib-include=$DEST/include

make CC=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-gcc
make CC=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-gcc install INSTALLTOP=$DEST OPENSSLDIR=$DEST/ssl

########### #################################################################
# NCURSES # #################################################################
########### #################################################################

mkdir -p $SRC/curses && cd $SRC/curses
[ ! -e "ncurses-6.1.tar.gz" ] && $WGET http://ftp.gnu.org/gnu/ncurses/ncurses-6.1.tar.gz
tar zxvf ncurses-6.1.tar.gz
cd ncurses-6.1
CC=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-gcc \
CROSS_PREFIX=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux- \
LDFLAGS=$LDFLAGS \
CPPFLAGS="-P $CPPFLAGS" \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
--enable-widec \
--enable-overwrite \
--with-normal \
--with-shared \
--enable-rpath \
--with-fallbacks=xterm \
--without-progs

$MAKE
make install DESTDIR=$BASE

############### #############################################################
# LIBREADLINE # #############################################################
############### #############################################################

mkdir -p $SRC/libreadline && cd $SRC/libreadline
[ ! -e "readline-7.0.tar.gz" ] && $WGET http://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz
tar zxvf readline-7.0.tar.gz
cd readline-7.0

[ ! -e "readline.patch" ] && $WGET https://raw.githubusercontent.com/lancethepants/tomatoware/master/patches/readline/readline.patch
patch < readline.patch

LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
--disable-shared \
bash_cv_wcwidth_broken=no \
bash_cv_func_sigsetjmp=yes

$MAKE
make install DESTDIR=$BASE

############ ################################################################
# LIBICONV # ################################################################
############ ################################################################

mkdir -p $SRC/libiconv && cd $SRC/libiconv
[ ! -e "libiconv-1.15.tar.gz" ] && $WGET http://ftp.gnu.org/gnu/libiconv/libiconv-1.15.tar.gz
tar zxvf libiconv-1.15.tar.gz
cd libiconv-1.15

LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
--enable-static \
--disable-shared

$MAKE
make install DESTDIR=$BASE

############# ###############################################################
# SOFTETHER # ###############################################################
############# ###############################################################

mkdir -p $SRC/softether && cd $SRC/softether
[ ! -d "SoftEtherVPN_Stable" ] && git clone https://github.com/SoftEtherVPN/SoftEtherVPN_Stable.git

cp -r SoftEtherVPN_Stable SoftEtherVPN_Stable_host
cd SoftEtherVPN_Stable_host

if [ "`uname -m`" == "x86_64" ];then
	cp ./src/makefiles/linux_64bit.mak ./Makefile
else
	cp ./src/makefiles/linux_32bit.mak ./Makefile
fi

$MAKE

cd ../SoftEtherVPN_Stable

[ ! -e "100-ccldflags.patch" ] && $WGET https://raw.githubusercontent.com/lancethepants/SoftEtherVPN-arm-static/master/patches/100-ccldflags.patch
[ ! -e "iconv.patch" ] && $WGET https://raw.githubusercontent.com/lancethepants/SoftEtherVPN-arm-static/master/patches/iconv.patch
patch -p1 < 100-ccldflags.patch
patch -p1 < iconv.patch

cp ./src/makefiles/linux_32bit.mak ./Makefile
sed -i 's,#CC=gcc,CC=~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-gcc,g' Makefile
sed -i 's,-lncurses -lz,-lncursesw -lz -liconv,g' Makefile
sed -i 's,ranlib,~/K3C/staging_dir/toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-gcc-ranlib,g' Makefile

CCFLAGS="$CPPFLAGS $CFLAGS" \
LDFLAGS="-static $LDFLAGS" \
$MAKE \
|| true

cp ../SoftEtherVPN_Stable_host/tmp/hamcorebuilder ./tmp/

CCFLAGS="$CPPFLAGS $CFLAGS" \
LDFLAGS="-static $LDFLAGS" \
$MAKE
