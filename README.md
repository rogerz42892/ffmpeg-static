Provenance
==========
stvs/ffmpeg-static -> rogerz42892/ffmpeg-static

To Build/Deploy at Engineyard
------------------------------

	$ cd ~/wa 
	$ git clone https://github.com/rogerz42892/ffmpeg-static
	$ cd ffmpeg-static
	# -a means FORCE libass rebuild.
	# On gentoo release 2, do NOT provide the -a flag
	$ ./build.sh -c -s -a 2>&1 | tee build.log	
	$ sudo cp -pvf target/bin/ff* /usr/local/bin
	# Then copy the executables to the appropriate cloud-assets directory:
	$ s3play put target/bin/ffmpeg s3://cloud-assets.3pmstaging.com # e.g.

Note: These steps work on Mac OS X, as well, without the -a flag.
Also, be sure to (re)link /opt/local/bin/{ffmpeg,ffprobe} to the 
/usr/local/bin versions, if necessary.

FFmpeg static build (original instructions from STVS)
------------------------------------------------------

Three scripts to make a static build of ffmpeg with all the latest codecs (webm + h264).

Just follow the instructions below. Once you have the build dependencies,
just run ./build.sh, wait and you should get the ffmpeg binary in target/bin

Optionally, you may need to rm -rf ~/.cache/fetchurl/* to make sure you get
the latest version of each of the components.

Build dependencies
------------------

    # Debian & Ubuntu
    $ apt-get install build-essential curl tar

	# OS X
	# install XCode, it can be found at http://developer.apple.com/
	# (apple login needed)
	# <FIXME???>

Build & "install"
-----------------

    $ ./build.sh or build-ubuntu.sh
    # ... wait ...
    # binaries can be found in ./target/bin/

NOTE: If you're going to use the h264 presets, make sure to copy them along the binaries. 
For ease, you can put them in your home folder like this:

    $ mkdir ~/.ffmpeg
    $ cp ./target/share/ffmpeg/*.ffpreset ~/.ffmpeg

Debug
-----

On the top-level of the project, run:

	$ . env.source
	
You can then enter the source folders and make the compilation yourself

	$ cd build/ffmpeg-*
	$ ./configure --prefix=$TARGET_DIR #...
	# ...

Remaining links
---------------

I'm not sure it's a good idea to statically link those, but it probably
means the executable won't work across distributions or even across releases.

    # On Ubuntu 10.04:
    $ ldd ./target/bin/ffmpeg 
	not a dynamic executable

    # on OSX 10.6.4:
    $ otool -L ffmpeg 
	ffmpeg:
		/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 125.2.0)

TODO
----

 * Add some tests to check that video output is correctly generated
   this would help upgrading the package without too much work
 * OSX's xvidcore does not detect yasm correctly
 * remove remaining libs
 
