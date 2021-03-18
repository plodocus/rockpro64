ncp-config
nc-snapshot-auto: yes
Need to create subvolume `/media/usb1/ncp-snapshots`
nc-snapshot-rsync:
ACTIVE        yes
SNAPDIR       /media/usb0/ncp-snapshots
DESTINATION   /media/usb1/ncp-snapshots
COMPRESSION   no
SYNCDAYS      1
This sets up a cronjob that syncs `SNAPDIR` with `DESTINATION` every `SYNCDAYS` days at 4:30 (the latter values in `/usr/local/bin/ncp/BACKUPS/nc-snapshot-sync.sh`).
#Spin down the disk
#Since the hard drive is only really used once per day it makes sense to spin it down to save energy and decrease wear.
#Use hd-idle.
#/etc/default/hd-idle
#START_HD_IDLE=true
## don't spin down by default, only spin down this device after 60 secs
#HD_IDLE_OPTS="-i 0 -a disk/by-uuid/4a691dba-f79d-4254-ab24-516550c9b07b -i 60"
#"
#systemctl restart hd-idle
I got this before
sudo hdparm -I /dev/sdb

/dev/sdb:
SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0a 00 00 00 00 24 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


Seagate external hard drives have a bad history of not properly implementing the UAS protocol, so linux kernel disables some features by default using quirks.
My HDD seems to be new enough that it doesn't suffer from the problems, so the quirk can be disabled for this device.
lsusb
Bus 008 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 007 Device 013: ID 0bc2:ab21 Seagate RSS LLC Backup Plus Slim
Bus 007 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 006 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 005 Device 002: ID 152d:0580 JMicron Technology Corp. / JMicron USA Technology Corp. 
Bus 005 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 003 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
To this end, start armbian-config, go to system > bootenv.
At "usbstoragequirks" append `0x0bc2:0xab21:`.

I had to connect my external ssd case to USB 3.0, C-type didn't automatically power on after reboot.
And external HDD was connected to C-type via adapter because of weird sounds at the USB 2.0 ports.

Now /etc/hdparm.conf appended:

/dev/disk/by-uuid/4a691dba-f79d-4254-ab24-516550c9b07b {
	write_cache = on
	spindown_time = 24
}

This spins down the disk after 24 * 5 = 120 seconds of idle.


# rclone
installation like
```
echo "deb http://packages.azlux.fr/debian/ buster main" | sudo tee /etc/apt/sources.list.d/azlux.list
wget -qO - https://azlux.fr/repo.gpg.key | sudo apt-key add -
sudo apt update
sudo apt install rclone
```
https://github.com/rclone/rclone/issues/2153#issuecomment-583505201

set-up 1fichier like https://rclone.org/fichier/
do it as user restic (below, so that config is saved in correct home folder)
name "onefiji"

install restic
setup restic user for rootless backup 
https://restic.readthedocs.io/en/stable/080_examples.html#full-backup-without-root
add user 
```
sudo useradd -m restic
```
change group and permissions for restic binary
```
sudo chown root:restic /usr/bin/restic
sudo chmod 750 /usr/bin/restic
```
make folder `nc` in remote `onefiji`:
`rclone mkdir onefiji:nc`
initiate restic repo
```
sudo -u restic restic -r rclone:onefiji:nc init
```
this requires a password/phrase

and backup!
first add restic to group www-data so it can read contents of nc-data
sudo usermod -a -G www-data restic
sudo -u restic restic -r rclone:onefiji:nc --verbose backup /media/usb0/nc-data
