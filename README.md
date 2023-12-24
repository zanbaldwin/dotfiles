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
