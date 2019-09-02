# A workspace manager for I3 wm


`i3_workspaces` allow you to configure your workspace easily. I use it for
setting a wallpaper to each workspace, or launch application on some
workspaces.

## Configuration

Create a configuration in `~/{XDG_CONFIG_HOME}/i3_workspaces/config` with :

```ini
[global]
image=~/wallpaper/default.jpg
on_focus=feh --bg scale ${image}

[1]
image=~/wallpaper/1.jpg

[2]
image=~/wallpaper/2.jpg

[mail]
on_init=thunderbird

[web]
image=~/wallpaper/web.jpg
on_init=firefox

[music]
on_init=gmpc
```

- the `on_focus` command will be launched on workspace change.
- the `on_init` will be launched on workspace creation.

Keys defined in `global` section will apply on any workspace, and can be
overriden in a dedicated workspace section.

## Compilation

Require [opam](http://opam.ocaml.org/)

Download the project and compile it with `opam pin https://github.com/Chimrod/i3_workspaces.git`
