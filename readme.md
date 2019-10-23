# A workspace manager for I3 wm

## Goals

`i3_workspaces` allow you to configure your workspace easily. I use it for
setting a wallpaper to each workspace, or launch application on some
workspaces.

### Problem with `assign`

The [assign](https://i3wm.org/docs/userguide.html#assign_workspace) keyword in
the i3 configuration allow you to set a dedicated workspace for an application.
This solution as flaws, like moving ALL the windows on this workspace, even if
the parent has been moved to another one workspace.

We are answering the problem in a different way : instead of creating the
window, then moving it to a workspace, you run the application when the
workspace is created. You can then forget all the placement rules, and you can
move the application anywhere, without being annoyed by pop-up window created
on another workspace.

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
on_init_swallow_class=URxvt

[mail]
on_init=thunderbird

[web]
image=~/wallpaper/web.jpg
on_init=firefox
on_init_swallow_class=Firefox

[music]
on_init=gmpc
```

- the `on_focus` command will be launched on workspace change.
- the `on_init` will be launched on workspace creation.

Keys defined in `global` section will apply on any workspace, and can be
overriden in a dedicated workspace section.

The key `on_init_swallow_class` tells i3 that the window with the given class
shall be placed on the workspace. It create a container in the workspace,
and i3 will not destroy it if you leave the workspace right after creating it :
this prevent `on_init` event to be run a second time when the window is created.

### Layout

You can also let the application manage for you the window placement.
i3_workspaces provide a binary layout which automaticaly divide each container
following a binary space partionning :

![Layout example](layout.gif)

```ini
[global]
layout=binary
```

## Compilation

The application is coded in OCaml, a functionnal language, and uses
[i3ipc](https://github.com/Armael/ocaml-i3ipc/) to communicate with the i3.

Require [opam](http://opam.ocaml.org/)

Download the project and compile it with `opam pin add https://github.com/Chimrod/i3_workspaces.git`

Install with `sudo make install`
