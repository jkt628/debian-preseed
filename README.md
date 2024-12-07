# Build a minimal Debian preseed.cfg from a host

especially when building or upgrading hosts it is useful to recreate a host from scratch but put back much
of its previous configuration.
[ansible-bakery](https://github.com/jkt628/ansible-bakery)
recreates the system **after** install but the harder part to get to is the initial install.  
[Debian](https://debian.org) allows a
[preseed.cfg](https://wiki.debian.org/DebianInstaller/Preseed) to answer known questions during install.  
this [Makefile](Makefile) creates a slim `preseed.cfg` with just differences to a
[well-known basis](https://preseed.debian.net/debian-preseed/), which can be further tweaked to
fine-tune a rebuild.
the easiest way to apply the `preseed.cfg` is to put it in the root directory of a USB installer.

## Secrets

note that passwords are not retrieved by this process, rather placeholders
`${ROOT_PASSWORD}` and `${USER_PASSWORD}` (two each) are inserted at the top of `preseed.cfg`.
they need to be replaced with **ACTUAL** values before installing.

## Usage

[Makefile](Makefile) sets `TARGET` to the base name of the current directory, this is the host to recreate.
the following script wants to recreate a host named `home-assistant`:

```bash
TARGET=home-assistant
mkdir $TARGET
cd $TARGET
make -f ../Makefile
make -f ../Makefile clean # intermediate files
make -f ../Makefile distclean # and preseed.cfg
```
