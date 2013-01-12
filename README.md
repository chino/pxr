# Description

PXR stand for ProjectX Ruby where ProjectX is the original code name of [Forsaken](https://github.com/ForsakenX/forsaken).

It started off as an experiment in using OpenGL with Ruby but quickly grew into a little game engine that can render Forsaken levels/models perfectly and some support for Descent levels as well.

It's very easy to create custom scenes and play around with different concepts.


# PXWGL (webgl)

https://github.com/chino/pxwgl-net

PXR and PXWGL are mostly ported between one another.  Each one though lives in different architectures (native vs browser), languages (ruby vs js), rendering apis (webgl vs opengl) etc..  They can serve as an example of the differences between using each language/environment for writing games.  One of the biggest pain points I found was javascript's lack of operator overloading made physics.js rather ugly in comparrison.


# Levels

Currently supports loading and rendering Forsaken levels perfectly.

There is support for Descent levels as well minus texturing.


# Pickups

It supports loading Forsaken level pickup lists.

The pickups spin in their location just like in Forsaken and can also be collected.

After a timeout they are added back to their original location.


# Rendering

Currently I use plain old immediate mode gl with display lists to speed things up.  The state of ruby-opengl at this point is multiple forks all over github (would be nice if we centralize on this effort) so I never got back around to writing a shader backend.  It would also be nice to provide a native backend to speed things up if required which could be made to use Forsaken's rendering system.

The level loaders build up a ruby object in a simple format that the renderer can iterate over and pipe the geometry into gl.  The files them selves (and like the original Forsaken) are separated into opaque and transparent polys.  In the rendering loop opaque polys are drawn first then transparent polys second with zbuffer writes disabled.  Simple 2d orthogonal rendering is done last an overlay.


# Physics

Initially we put together a pure ruby implementation that provides simple sphere based collisions but it can be rather slow.  There is also some work done to port the level collisions to ruby using bounding-bsp tree which works but is a bit buggy.

Later I put together a small Bullet physics library c-wrapper to make it easy to bind to Ruby via FFI (since Bullet is mainly written in c++ it can be much more complicated to bind).  Bullet in this case also handles level collisions using a bounding-volume-heirarchy (BVH) tree which works rather nice and fast without the requirement of building your own bsp tree.

Both the pure ruby and Bullet backends are compatible interfaces allowing a scene to switch between either one.


# Networking

Currently just a very simple implementation on top of Ruby's UdpSocket just to get something out the door.  In the future I would like to bind to Forsaken's p2p library that I wrote which uses Enet as a transport layer.  And potentionally use Forsaken's higher level protocol as well so you could join a real Forsaken game.


# Multiplayer

You can shoot sphers and hit others to register points.


# UI

It supports a basic user interface:

* player list with scores
* chat entry which doubles as a command line
* optional 3d inventory which renders using the real weapon models

# scenes/

When you run PXR it loads scenes/default.rb unless you specify another file.

A scene has full control over what happens since nothing is done for you.

You add and mix together what you want from the lib/* folder and implement new things.

The default scene loads up:

* one of the physics backends
* the renderer
* score
* chat
* networking 
* ship level
* 2 player models
* inputs
* allows you to shoot projectiles

Over time I played around with many ideas like:

* 3rd person view
* fps style on screen weapon
* random opengl experiments like a waving mesh

As the engine evolved very quickly many of the scenes need to be updated.


# conf/

Configure your settings here.


# lib/

The main body of code that runs the engine.

File parsers, renderer, physics, ui, networking etc..

* physics.rb - Simple sphere based collisions in pure ruby.

* physics_bullet.rb - Same interface but backed by custom c bindings to Bullet physics library.

* mesh.rb and render.rb - Majority of the rendering code lives here.

* vector.rb, quat.rb - Math routines used by the engine.

* binreader.rb - Easy to use mixin for reading binary files.

* d1rdl.rb, fskn_*.rb - Descent and Forsaken file parsers.


# data/

The data directory contains models, textures and other resources.

Two main files:

* default.rb - Will currently load up Forsaken ship level with pickups and two player models.

* dumper.rb  - Dumps Forsaken mx(va) files in json format (also used by blender.org importer).
