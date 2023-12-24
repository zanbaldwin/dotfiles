# :book: Yet Another Dotfiles Repo

```bash
$ cd ~
$ git clone git://github.com/zanbaldwin/dotfiles.git
$ ln -s dotfiles/.bash_aliases .bash_aliases
$ ln -s dotfiles/.bash_prompt .bash_prompt
$ ln -s dotfiles/.gitconfig .gitconfig
$ ln -s dotfiles/.editorconfig .editorconfig
$ ln -s dotfiles/.gnupg .gnupg
$ ln -s dotfiles/.ignore .ignore
$ ln -s dotfiles/.tmux.conf .tmux.conf
```

### Extras

#### Swapping Caps Lock with Escape

1. `sudo apt install dconf-tools`
2. `dconf write /org/gnome/desktop/input-sources/xkb-options "['caps:swapescape']"`

Alternatively, you can use the `dconf-editor` GUI once DConf tools are installed.

> Use `caps:escape` instead if you want to just set Caps Lock to Escape instead
> of swapping the functionality of the keys.

#### Remapping Keyboard Keys

> :no_entry: Beware! :dragon_face: here be dragons!

Edit files found in `/usr/share/X11/xkb/keycodes/evdev`.

#### Changing Screenshot Save Directory

Change the screenshot save directory using either `dconf-editor` or one of the following commands:

```
gsettings set org.gnome.gnome-screenshot auto-save-directory "/home/${USER}/Pictures/Screenshots"
dconf write /org/gnome/gnome-screenshot/auto-save-directory "/home/${USER}/Pictures/Screenshots"
```

This will **not** change the behaviour of the PrtScr button:

1. Go to **Settings > Keyboard Shortcuts**.
2. Disable the keyboard shortcut for the current PrtScr action (_Save a screenshot to Pictures_).
3. Add a new keyboard shortcut for PrtScr with the command `gnome-screenshot`.
4. Optionall, do the same for _Save a screenshot of an area to Pictures_ with `gnome-screenshot -a`.
5. Optionall, do the same for _Save a screenshot of an window to Pictures_ with `gnome-screenshot -wb`.

<!-- See: https://blog.aamnah.com/ubuntu/change-default-screenshot-save-location -->

#### Ubuntu Crashes/Freezes During Installation

> For problems with nVidia drivers: `nomodeset` instructs the kernel to load the
> video/graphics drivers after the X display server is started. Disabling the graphics
> driver at boot time removes the conflict; after login / display server start, the
> graphics card is loaded again.

1. During GRUB, **e**dit the target entry and add `nomodeset` at the end of the list of parameters for `linux`.
2. Save and exit, booting with the modified config.
3. Proceed with installation as usual.
4. Install nVidia drivers as soon as possible:
   - Software & Updates &rarr; Additional Drivers
5. Alternatively, disable graphics drivers permanently (not recommended):
   - `sudo nano /etc/default/grub`
   - Add `nomodeset` to `GRUB_CMDLINE_LINUX_DEFAULT`
   - `sudo update-grub`
