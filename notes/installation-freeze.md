#### Graphics Crashes/Freezes During Installation

> For problems with nVidia drivers: `nomodeset` instructs the kernel to load the
> video/graphics drivers after the X display server is started. Disabling the graphics
> driver at boot time removes the conflict; after login / display server start, the
> graphics card is loaded again.

1. During GRUB, **e**dit the target entry and add `nomodeset` at the end of the list of parameters for `linux`.
2. Save and exit, booting with the modified config.
3. Proceed with installation as usual.
4. Install nVidia drivers as soon as possible:
   - Software & Updates &rarr; Additional Drivers on Ubuntu
   - `akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda` packages on Fedora
5. Alternatively, disable graphics drivers permanently (not recommended):
   - `sudo nano /etc/default/grub`
   - Add `nomodeset` to `GRUB_CMDLINE_LINUX_DEFAULT`
   - `sudo update-grub`
