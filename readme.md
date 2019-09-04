# A workspace manager for I3 wm


`i3_workspaces` allow you to configure your workspace easily. I use it for
setting a wallpaper to each workspace, or launch application on some
workspaces.

## Configuration

Create a configuration in `${XDG_CONFIG_HOME}/i3_workspaces/config` with :

```ini
[global]
image=~/wallpaper/default.jpg
on_focus=feh --bg-scale ${image}

[1]
image=~/wallpaper/1.jpg

[2]
image=~/wallpaper/2.jpg

[mail]
on_init=thunderbird
on_init_swallow_class=Thunderbird

[web]
image=~/wallpaper/web.jpg
on_init=firefox
on_init_swallow_class=Firefox # Ensure firefox will be launched on this workspace

[music]
on_init=gmpc
on_init_swallow_class=Gmpc
```

- the `on_focus` command will be launched on workspace change.
- the `on_init` will be launched on workspace creation.

Keys defined in `global` section will apply on any workspace, and can be
overriden in a dedicated workspace section.

The key `on_init_swallow_class` tell i3 that the window with the given class
shall be placed on the workspace. This allow to quickly change workspace after
creating it without seing firefox on the new workspace.

## Compilation

Require [opam](http://opam.ocaml.org/)

Download the project and compile it with `opam pin add https://github.com/Chimrod/i3_workspaces.git`

Install with `sudo make install`
