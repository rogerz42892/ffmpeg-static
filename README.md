Provenance
==========
stvs/ffmpeg-static -> rogerz42892/ffmpeg-static

To Install at Engineyard
========================
1) TGZ this repository.
2) scp to /home/deploy/wa on an engineyard resque worker.
3) ssh to the resque worker
4) Go to /home/deploy/wa directory and untar the directory.
5) Change to the ffmpeg-static directory
6) Follow the build instructions here.
7) Install the executables (ffmpeg and ffprobe) in /usr/local/bin
8) s3play put the executable (ffmpeg and ffprobe) in:
   s3://cloud-assets.3pmstaging.com
   s3://cloud-assets.3playmedia.com


FFmpeg static build
===================

Three scripts to make a static build of ffmpeg with all the latest codecs (webm + h264).

Just follow the instructions below. Once you have the build dependencies,
just run ./build.sh, wait and you should get the ffmpeg binary in target/bin

Build dependencies
------------------

    # Debian & Ubuntu
    $ apt-get install build-essential curl tar <FIXME???>

	# OS X
	# install XCode, it can be found at http://developer.apple.com/
	# (apple login needed)
	# <FIXME???>

Build & "install"
-----------------

    $ ./build.sh
    # ... wait ...
    # binaries can be found in ./target/bin/

NOTE: If you're going to use the h264 presets, make sure to copy them along the binaries. For ease, you can put them in your home folder like this:

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
    $ ldd build/bin/ffmpeg
	linux-gate.so.1 =>  (0xb78df000)
	libm.so.6 => /lib/tls/i686/cmov/libm.so.6 (0xb789f000)
	libz.so.1 => /lib/libz.so.1 (0xb788a000)
	libpthread.so.0 => /lib/tls/i686/cmov/libpthread.so.0 (0xb7870000)
	libc.so.6 => /lib/tls/i686/cmov/libc.so.6 (0xb7716000)
	/lib/ld-linux.so.2 (0xb78e0000)

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
 
