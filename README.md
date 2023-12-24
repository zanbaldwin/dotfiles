# :book: Yet Another Dotfiles Repo

To setup a new environment:

```bash
$ cd ~
$ git clone "git://github.com/zanbaldwin/dotfiles.git" "~/.dotfiles"
$ ~/.dotfiles/install.sh
```

### Extras

#### Swapping Caps Lock with Escape

1. `sudo apt install dconf-tools`
2. `dconf write /org/gnome/desktop/input-sources/xkb-options "['caps:swapescape']"`

Alternatively, you can use the `dconf-editor` GUI once DConf tools are installed.

> Use `caps:escape` instead if you want to just set Caps Lock to Escape instead
> of swapping the functionality of the keys.

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

#### Default Audio Output

Using PulseAudio control, list the audio devices registered and set your chosen one as the default.

##### Output Devices

```shell
# List all audio output devices registered with system
pactl list short sinks
# Set an ID from the list as the default (eg, "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink")
pactl set-default-sink "${CHOSEN_SINK_ID}"
```

##### Input Devices

```shell
# List all audio input devices registered with system
pactl list short sources
# Set an ID from the list as the default (eg, "alsa_input.usb-Blue_Microphones_Yeti_X_2102SG013BE8_888-000316110306-00.analog-stereo")
pactl set-default-source "${CHOSEN_SOURCE_ID}"

```

#### Running a Local DNS Server

SystemD automatically runs a stub DNS server on port 53. To disable this:
1. Set `DNSStubListener` to `no` in `/etc/systemd/resolved.conf`
2. Symbolically link this config file to `/run/systemd/resolve/resolv.conf`:
   `sudo ln -s /run/systemd/resolve/resolv.conf /etc/systemd/resolved.conf`
