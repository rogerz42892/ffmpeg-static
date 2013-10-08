#!/bin/sh

set -e
set -u

jflag=
jval=4
nofetch=0
clean=0
spotless=0
notest=0
while getopts 'j:tncs\?h' OPTION ; do
  case $OPTION in
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
  h|?)	printf "Usage: %s: [-n(ofetch)] [-c(lean) [-s(potless)] [-t(notest)] [-j concurrency_level]\n" $(basename $0) >&2
		exit 0
		;;
  esac
done
shift $(($OPTIND - 1))

if [ "$jflag" ]; then
  if [ "$jval" ] ; then
    printf "Option -j specified (%d)\n" $jval
  fi
fi

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

echo "#### FFmpeg static build, by STVS SA ####"
cd $BUILD_DIR
if [ $nofetch -eq 0 ] ;then
../fetchurl "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz"
../fetchurl "http://zlib.net/zlib-1.2.8.tar.gz"
../fetchurl "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
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
if [ -s /etc/gentoo-release ] ; then
    ../fetchurl "https://libass.googlecode.com/files/libass-0.9.13.tar.gz"
fi
fi

echo "*** Building yasm ***"
cd $BUILD_DIR/yasm*
./configure --prefix=$TARGET_DIR
make -j $jval && make install

echo "*** Building zlib ***"
cd $BUILD_DIR/zlib*
./configure --prefix=$TARGET_DIR
make -j $jval && make install

echo "*** Building bzip2 ***"
cd $BUILD_DIR/bzip2*
make
make install PREFIX=$TARGET_DIR

echo "*** Building libpng ***"
cd $BUILD_DIR/libpng*
./configure --prefix=$TARGET_DIR --with-zlib-prefix=$BUILD_DIR/zlib-1.2.8 --enable-static --disable-shared 
make -j $jval && make install

# Ogg before vorbis
echo "*** Building libogg ***"
cd $BUILD_DIR/libogg*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install

# Vorbis before theora
echo "*** Building libvorbis ***"
cd $BUILD_DIR/libvorbis*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install

echo "*** Building libtheora ***"
cd $BUILD_DIR/libtheora*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install

echo "*** Building livpx ***"
cd $BUILD_DIR/libvpx*
./configure --prefix=$TARGET_DIR --disable-shared
make -j $jval && make install

echo "*** Building faac ***"
cd $BUILD_DIR/faac*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
# FIXME: gcc incompatibility, does not work with log()

sed -i -e "s|^char \*strcasestr.*|//\0|" common/mp4v2/mpeg4ip.h
make -j $jval && make install

echo "*** Building x264 ***"
cd $BUILD_DIR/x264*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared --disable-opencl
make -j $jval && make install

echo "*** Building xvidcore ***"
cd "$BUILD_DIR/xvidcore/build/generic"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install
#rm $TARGET_DIR/lib/libxvidcore.so.*

echo "*** Building lame ***"
cd $BUILD_DIR/lame*
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j $jval && make install

if [ -s /etc/gentoo-release ] ; then
    echo "*** Building libass ***"
    cd $BUILD_DIR/libass*
    ./configure --prefix=$TARGET_DIR --enable-static --disable-shared
    make -j $jval && make install
fi

# FIXME: only OS-specific
rm -f "$TARGET_DIR/lib/*.dylib"
rm -f "$TARGET_DIR/lib/*.so"

# FFMpeg
echo "*** Building FFmpeg ***"
cd $BUILD_DIR/ffmpeg*
CFLAGS="-I$TARGET_DIR/include" LDFLAGS="-L$TARGET_DIR/lib -lm" ./configure --prefix=${OUTPUT_DIR:-$TARGET_DIR} --extra-version=static --disable-debug --disable-shared --enable-static --extra-cflags=--static --disable-ffplay --disable-ffserver --disable-doc --enable-gpl --enable-pthreads --enable-postproc --enable-gray --enable-runtime-cpudetect --enable-libfaac --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-bzlib --enable-zlib --enable-nonfree --enable-version3 --enable-libvpx --enable-libass --disable-devices
make -j $jval && make install
[ $notest -eq 1 ] && exit $?
cd ..
./regress
