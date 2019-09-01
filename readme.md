.. -*- mode: rst -*-
.. -*-  coding: utf-8 -*-

# A workspace manager for I3 wm


`i3_workspaces` allow you to configure your workspace easily. I use it for
setting a wallpaper to each workspace, or launch application on some
workspaces.

## Configuration


Create a configuration

```ini
[global]
image=~/wallpaper/default.jpg
on_focus=~feh --bg scale ${image}

[1]
image=~/wallpaper/1.jpg

[2]
image=~/wallpaper/2.jpg

[mail]
on_init=thunderbird

[web]
image=~/wallpaper/web.jpg
on_init=firefox

[music:]
on_init=gmpc
```

## Compilation

Require [opam](http://opam.ocaml.org/)

Download the project and compile it with `opam install .`
