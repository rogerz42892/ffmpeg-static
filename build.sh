#!/bin/sh

set -e
set -u

jflag=
jval=4
nofetch=0
clean=0
spotless=0
notest=0
forceass=0
if [ `uname` = 'Darwin' ] ; then
    SED='sed -i "bak" -e'
else
    SED='sed -ibak -e'
fi

while getopts 'j:atncs\?h' OPTION ; do
  case $OPTION in
  a)    forceass=1
                ;;
  t)	notest=1
                ;;
  s)	spotless=1
                ;;
  c)	clean=1
                ;;
  n)	nofetch=1
	        ;;
  j)	jflag=1
        	jval="$OPTARG"
	        ;;
  h|?)	printf "Usage: %s: [-n(ofetch)] [-c(lean) [-s(potless)] [-t(notest)] [-a(forceass)] [-j concurrency_level]\n" $(basename $0) >&2
		exit 0
		;;
  esac
done
shift $(($OPTIND - 1))
cd `dirname $0`
ENV_ROOT=`pwd`
. ./env.source

if [ $clean -eq 1 ] ; then
    echo "clean: Removing $BUILD_DIR and $TARGET_DIR"
    rm -rf "$BUILD_DIR" "$TARGET_DIR"
fi
CACHE_DIR=${CACHE_DIR:-$HOME/.cache/fetchurl}
if [ $spotless -eq 1 ] ; then
    echo "spotless: Removing $CACHE_DIR"
    rm -rf "$CACHE_DIR"
fi
mkdir -p "$BUILD_DIR" "$TARGET_DIR" "$CACHE_DIR"

# NOTE: this is a fetchurl parameter, nothing to do with the current script
#export TARGET_DIR_DIR="$BUILD_DIR"
if [ $forceass -eq 1 ] ; then
    needass=1
else
    set +e
    pkg-config --exists libass
    needass=$?
    set -e
fi
echo "#### FFmpeg static build, by STVS SA ####"
cd $BUILD_DIR
if [ $nofetch -eq 0 ] ; then
    ../fetchurl "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz"
    ../fetchurl "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
    # Why ask why?
    gentoo_two=0
    if [ -e /etc/gentoo-release ] ; then
	set +e
	cat /etc/gentoo-release | egrep -q -i 'release 2'
	[ $? -eq 0 ] && gentoo_two=1
	set -e
    fi
    if [ $gentoo_two -eq 1 ] ; then
	../fetchurl "http://sourceforge.net/projects/libpng/files/zlib/1.2.7/zlib-1.2.7.tar.bz2"
    else
	../fetchurl "http://sourceforge.net/projects/libpng/files/zlib/1.2.3/zlib-1.2.3.tar.bz2"
    fi
    ../fetchurl "http://sourceforge.net/projects/libpng/files/libpng16/1.6.6/libpng-1.6.6.tar.gz"
    ../fetchurl "http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz"
    ../fetchurl "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz"
    ../fetchurl "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2"
    ../fetchurl "http://webm.googlecode.com/files/libvpx-v1.1.0.tar.bz2"
    ../fetchurl "http://downloads.sourceforge.net/project/faac/faac-src/faac-1.28/faac-1.28.tar.bz2"
    ../fetchurl "ftp://ftp.videolan.org/pub/x264/snapshots/last_x264.tar.bz2"
    ../fetchurl "http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.gz"
    ../fetchurl "http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz"
    ../fetchurl "http://ffmpeg.org/releases/ffmpeg-2.0.tar.bz2"
    if [ $needass -eq 1 ] ; then
	../fetchurl "http://sourceforge.net/projects/freetype/files/freetype2/2.5.0/freetype-2.5.0.1.tar.gz"
	../fetchurl "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz"
	../fetchurl "http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.8.0.tar.gz"
	../fetchurl "http://dl.cihar.com/enca/enca-1.13.tar.gz"
	../fetchurl "https://libass.googlecode.com/files/libass-0.9.13.tar.gz"
    fi
fi

echo "*** Building yasm ***"
cd $BUILD_DIR/yasm*
./configure --prefix=$TARGET_DIR
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: yasm ***"

echo "*** Building zlib ***"
cd $BUILD_DIR/zlib*
zlib_dir=`pwd`
./configure --prefix=$TARGET_DIR
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: zlib ***"

echo "*** Building bzip2 ***"
cd $BUILD_DIR/bzip2*
make
make install PREFIX=$TARGET_DIR
[ $? -eq 0 ] || echo "*** FAIL: bzip2 ***"

echo "*** Building libpng ***"
cd $BUILD_DIR/libpng*
./configure --prefix=$TARGET_DIR --with-zlib-prefix=$zlib_dir --enable-static --disable-shared 
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: libpng ***"

# Ogg before vorbis
echo "*** Building libogg ***"
cd $BUILD_DIR/libogg*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: libogg ***"

# Vorbis before theora
echo "*** Building libvorbis ***"
cd $BUILD_DIR/libvorbis*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: libvorbis ***"

echo "*** Building libtheora ***"
cd $BUILD_DIR/libtheora*
# http://www.linuxfromscratch.org/blfs/view/svn/multimedia/libtheora.html
$SED 's/png_\(sizeof\)/\1/g' examples/png2theora.c
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: libtheora ***"

echo "*** Building livpx ***"
cd $BUILD_DIR/libvpx*
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: libvpx ***"

echo "*** Building faac ***"
cd $BUILD_DIR/faac*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
# FIXME: gcc incompatibility, does not work with log()
$SED "s|^char \*strcasestr.*|//\0|" common/mp4v2/mpeg4ip.h
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: faac ***"

echo "*** Building x264 ***"
cd $BUILD_DIR/x264*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared --disable-opencl --enable-pic
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: x264 ***"

echo "*** Building xvidcore ***"
cd "$BUILD_DIR/xvidcore/build/generic"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: xvidcore ***"

echo "*** Building lame ***"
cd $BUILD_DIR/lame*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install
[ $? -eq 0 ] || echo "*** FAIL: lame ***"

if [ $needass -eq 1 ] ; then
    echo "*** Building libiconv ***"
    cd $BUILD_DIR/libiconv*
    ./configure --prefix=$TARGET_DIR --enable-static --disable-shared
    make $jval && make install
    [ $? -eq 0 ] || echo "*** FAIL: libiconv ***"
    echo "*** Building enca ***"
    cd $BUILD_DIR/enca*
    ./configure --prefix=$TARGET_DIR --enable-static --disable-shared
    make -j $jval && make install
    [ $? -eq 0 ] || echo "*** FAIL: enca ***"
    echo "*** Building freetype ***"
    cd $BUILD_DIR/freetype*
    ./configure --prefix=$TARGET_DIR --enable-static --disable-shared
    make -j $jval && make install
    [ $? -eq 0 ] || echo "*** FAIL: freetype ***"
    echo "*** Building fontconfig ***"
    cd $BUILD_DIR/fontconfig*
    ./configure --prefix=$TARGET_DIR --enable-static --disable-shared
    #sed -i -e 's/ iconv_open/ libiconv_open/g' src/fcfreetype.c
    #sed -i -e 's/ iconv_close/ libiconv_close/g' src/fcfreetype.c
    #sed -i -e 's/did = iconv/did = libiconv/g' src/fcfreetype.c
    make -j $jval && make install
    [ $? -eq 0 ] || echo "*** FAIL: fontconfig ***"
    cd $BUILD_DIR/libass*
    ./configure --prefix=$TARGET_DIR --enable-enca --enable-static --disable-shared
        make -j $jval && make install
    [ $? -eq 0 ] || echo "*** FAIL: libass ***"
    extra_libs="--extra-libs='-lfontconfig -lfreetype -lenca -lpng -lexpat -liconv'"
else
    extra_libs=""
fi


rm -f "$TARGET_DIR/lib/*.dylib"
rm -f "$TARGET_DIR/lib/*.so*"

# FFMpeg
echo "*** Building FFmpeg ***"
cd $BUILD_DIR/ffmpeg*
CFLAGS="-I$TARGET_DIR/include" LDFLAGS="-L$TARGET_DIR/lib -lm" PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig" ./configure --prefix=$TARGET_DIR --extra-version=static $extra_libs --disable-debug --disable-shared --enable-static --extra-cflags=--static --disable-ffplay --disable-ffserver --disable-doc --enable-gpl --enable-pthreads --enable-postproc --enable-gray --enable-runtime-cpudetect --enable-libfaac --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-bzlib --enable-zlib --enable-nonfree --enable-version3 --enable-libvpx --enable-libass --disable-devices
make -j $jval && make install
err=$?
[ $err -eq 0 ] || echo "*** FAIL: FFMPEG ***"
[ $notest -eq 1 ] && exit $err
cd $ENV_ROOT
./regress
