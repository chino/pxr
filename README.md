=Description=

Started as a little Ruby OpenGL experiment but quickly grew into a little game engine of it's own.

Very easy to create a custom scene of your liking and play around with different concepts.


=PX WEBGL=

https://github.com/chino/pxwgl-net

PXR and PXWGL are mostly ported between one another.  Each one though they live in a different architectures (native vs browser), languages (ruby vs js), and set of technologies (webgl vs opengl).  They serve as a good example of the differences between using each language/environment for writing games.  One of the biggest pain points I found was javascript's lack of operator overloading made physics.js a rather ugly in comparrison.


=Rendering=

Currently I use plain old immediate mode gl with display lists to speed things up.  The state of ruby-opengl support is in a state of multiple forks all of github at the moment so I never got back around to writing a shader backend.  In the end though it will most likely be better to write a c implementation for a fast rendering backend.

The level loaders build up a ruby object in a simple format that the renderer can iterate over and pipe the geometry into gl.  The files them selves (and like original Forsaken) are separated into opaque and transparent polys.  In the rendering loop opaque polys are drawn first then transparent polys second with zbuffer writes disabled.  Simple 2d orthogonal rendering is done last an overlay.


=Physics=

Initially we put together a simple pure ruby physics backend that provides simple sphere based collisions.  There is also some work done to port the level collisions to ruby using bounding-bsp tree which works but is a bit buggy.

A scene may also chose to use Bullet physics library bindings I wrote which tie back to a little c wrapper pulled in through Ruby FFI.  Bullet in this case also handles level collisions using a bounding-volume-heirarchy (BVH) tree which works rather nice and fast.

Both the pure ruby and Bullet backends are compatible interfaces allowing a scene to switch between either one.


=Networking=

Currently just a very simple implementation on top of Ruby's UdpSocket just to get something out the door.  In the future I would like to bind to Forsaken's p2p library that I wrote which uses Enet as a transport layer.  And potentionally would be nice to use Forsaken's packet formats as well so you could join a real Forsaken game.


=Directories=

Conf:

	Configure your settings here.

Lib:

	The main body of code that runs the engine.

	File parsers, renderer, physics, ui, networking etc..

	* physics.rb - Simple sphere based collisions in pure ruby.

	* physics_bullet.rb - Same interface but backed by custom c bindings to Bullet physics library.

	* mesh.rb and render.rb - Majority of the rendering code lives here.

	* vector.rb, quat.rb - Math routines used by the engine.

	* binreader.rb - Easy to use mixin for reading binary files.

	* d1rdl.rb, fskn_*.rb - Descent and Forsaken file parsers.

Data:

	The data directory contains models, textures and other resources.

Scenes:

	As the name implies defines what should be loaded up into any given scene.

	Over time I played around with many ideas from 3rd person view to fps style visible guns.

	As the engine evolved very quickly many of the scenes won't run without being updated.

	Two main files:

	* default.rb - Will currently load up Forsaken ship level with pickups and two player models.

	* dumper.rb  - Dumps Forsaken mx(va) files in json format (also used by blender.org importer).
