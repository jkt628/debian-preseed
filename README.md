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

## Setup

the target requires some additional configuration, execute these on the host:

```bash
su - # enter root password
apt install -y debconf-utils openssh-server
echo '%users ALL=(root) NOPASSWD: /usr/bin/debconf-get-selections' > /etc/sudoers.d/debconf-get-selections
exit
```

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

## Serving preseed.cfg

i wasted a lot of time on this:

[Using preseed](https://wiki.debian.org/DebianInstaller/Preseed) talks about

> put the preconfiguration file in the toplevel directory of the USB stick

but these days the installer creates a read-only iso9660 filesystem on p1 and a very small EFI boot on p2
which is never mounted into the installer.  their docs really need fixing.

moving on....

the next easiest method is to serve the file over the network.  i chose atftpd because it implements a
[systemd socket](https://man7.org/linux/man-pages/man5/systemd.socket.5.html) service.
unfortunately, i also hit [this bug](https://bugs.launchpad.net/ubuntu/+source/atftp/+bug/2065463) so
implemented the workaround there.

```bash
sudo -i
install -d -o $SUDO_USER /srv/tftp
apt install -y atftpd
mkdir /etc/systemd/system/atftpd.socket.d
cat >/etc/systemd/system/atftpd.socket.d/workaround.conf <<'EOF'
[Socket]
ListenDatagram=
ListenDatagram=0.0.0.0:69
EOF
systemctl daemon-reload
exit
```

copy the `preseed.cfg` to `/srv/tftp`, maybe rename to $TARGET.cfg.

on the target boot the USB and choose `Advanced install options...`  / `Graphical Installer...` / `Automated install`.
when the installer asks for the preseed location, enter `tftp://$host/$path_to_file`.
