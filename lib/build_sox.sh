#!/bin/bash
# building a statically compiled version with extra echo capabilities
# https://web.archive.org/web/20160524223449/http://www.kryogenix.org/days/2014/11/18/making-a-static-build-of-sox/

sudo apt-get install build-essential libmad0-dev realpath autoconf-archive

mkdir -p deps
mkdir -p deps/unpacked
mkdir -p deps/built
mkdir -p deps/built/libmad
mkdir -p deps/built/sox
mkdir -p deps/built/lame
git clone --depth 1 https://github.com/schollz/libmad.git deps/libmad
git clone --depth 1 https://github.com/schollz/lame.git deps/lame
git clone --depth 1 https://github.com/schollz/sox.git deps/sox


cd deps/libmad
./configure --disable-shared --enable-static --prefix=$(realpath ../built/libmad)
# Patch makefile to remove -fforce-mem
sed s/-fforce-mem//g < Makefile > Makefile.patched
cp Makefile.patched Makefile
# make sure fforce-mem is removed!
make
make install


cd ../lame
./configure --disable-shared --enable-static --prefix=$(realpath ../built/lame)
make install

cd ../sox
autoreconf -i
./configure --disable-shared --enable-static --prefix=$(realpath ../built/sox) \
    LDFLAGS="-L$(realpath ../built/libmad/lib) -L$(realpath ../built/lame/lib)" \
    CPPFLAGS="-I$(realpath ../built/libmad/include) -I$(realpath ../built/lame/include)" \
    --with-mad --with-lame --without-oggvorbis --without-oss --without-sndfile --without-flac  --without-gomp
make -s
make install

# thats it!