..
    Section headers are created by underlining (and optionally overlining) the section title with a punctuation character, at least as long as the text:

    =================
    This is a heading
    =================

    Normally, there are no heading levels assigned to certain characters as the structure is determined from the succession of headings. However, for the Python documentation, here is a suggested convention:

        # with overline, for parts
        * with overline, for chapters
        =, for sections
        -, for subsections
        ^, for subsubsections
        ", for paragraphs

#######
Backups
#######

**************
On-site backup
**************

Preparing the HDD
=================

Done on a 2 TB HDD connected to rockpro via USB 2.0, under ``/media/usb1``.
BTRFS snapshots are to be stored in a subvolume

.. code-block:: console

    sudo btrfs subvolume create /media/usb1/ncp-snapshots


Configuring NextcloudPi
=======================

In ``ncp-config``, go to ``BACKUP``.

Automatic btrfs snapshots (same drive)
--------------------------------------

``nc-snapshot-auto: yes``

Automatic sync of btrfs snapshots to backup drive
-------------------------------------------------

At ``nc-snapshot-rsync``

.. code-block:: console

   ACTIVE        yes
   SNAPDIR       /media/usb0/ncp-snapshots
   DESTINATION   /media/usb1/ncp-snapshots
   COMPRESSION   no
   SYNCDAYS      1


This sets up a cronjob that syncs ``SNAPDIR`` with ``DESTINATION`` every ``SYNCDAYS`` days at 4:30 (time can be found in ``/usr/local/bin/ncp/BACKUPS/nc-snapshot-sync.sh``).

Spinning down the disk of the backup drive
------------------------------------------

Since the hard drive is only really used once per day it makes sense to spin it down to save energy and decrease wear.
I use ``hdparm``.
Didn't work out of the box:

.. code-block:: console

   $ sudo hdparm -I /dev/sdb
   
   /dev/sdb:
   SG_IO: bad/missing sense data, sb[]:  70 00 05 00 00 00 00 0a 00 00 00 00 24 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


This was due to a safeguard default in the linux kernel.
Seagate external hard drives have a bad history of not properly implementing the UAS protocol, so linux kernel disables some features by default using quirks.
My HDD seems to be new enough that it doesn't suffer from the problems, so the quirk can be disabled for this device.

Get the ID for the drive
""""""""""""""""""""""""


.. code-block:: console
   
   $ lsusb
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


Disable the usb-storage quirk
"""""""""""""""""""""""""""""

In ``armbian-config``, go to ``system > bootenv``.
At ``usbstoragequirks`` append ``0x0bc2:0xab21:``.
   

Activate spinning down 
""""""""""""""""""""""

In ``/etc/hdparm.conf`` append:
   
.. code-block:: console

   /dev/disk/by-uuid/4a691dba-f79d-4254-ab24-516550c9b07b {
   	write_cache = on
   	spindown_time = 24
   }
   
This spins down the disk after 24 * 5 = 120 seconds of idle.

..
    I tried ``hd-idle``.
    Set the configuration in ``/etc/default/hd-idle``

    .. code-block:: console

       START_HD_IDLE=true
       # don't spin down by default, only spin down this device after 60 secs
       HD_IDLE_OPTS="-i 0 -a disk/by-uuid/4a691dba-f79d-4254-ab24-516550c9b07b -i 60"


    After saving the file, restart service: ``systemctl restart hd-idle``.



    I had to connect my external ssd case to USB 3.0, C-type didn't automatically power on after reboot.
    And external HDD was connected to C-type via adapter because of weird sounds at the USB 2.0 ports.



***************
Off-site backup
***************

rclone
======

installation like

echo "deb http://packages.azlux.fr/debian/ buster main" | sudo tee /etc/apt/sources.list.d/azlux.list
wget -qO - https://azlux.fr/repo.gpg.key | sudo apt-key add -
sudo apt update
sudo apt install rclone

https://github.com/rclone/rclone/issues/2153#issuecomment-583505201

restic
======
set-up 1fichier like https://rclone.org/fichier/
do it as user restic (below, so that config is saved in correct home folder)
name "onefiji"

install restic,
setup restic user for rootless backup 
https://restic.readthedocs.io/en/stable/080_examples.html#full-backup-without-root
add user 
sudo useradd -m restic
change group and permissions for restic binary
sudo chown root:restic ~restic/bin/restic
sudo chmod 750 ~restic/bin/restic
make folder `nc` in remote `onefiji`:
`rclone mkdir onefiji:nc`
initiate restic repo
sudo -u restic ~restic/bin/restic -r rclone:onefiji:nc init
this requires a password/phrase

and backup!
first add restic to group www-data so it can read contents of nc-data
sudo usermod -a -G www-data restic
sudo -u restic ~restic/bin/restic -r rclone:onefiji:nc --password-file=/home/restic/.config/restic/onefiji_nc --verbose backup /media/usb0/nc-data
sudo -u restic ~restic/bin/restic -r rclone:onefiji:nc check --read-data-subset=1/20
sudo -u restic ~restic/bin/restic -r rclone:onefiji:nc --verbose prune
sudo -u restic ~restic/bin/restic --password-file=/home/restic/.config/restic/onefiji_nc -r rclone:onefiji:nc forget --keep-hourly=36 --keep-daily=14 --keep-monthly=12 --keep-yearly=10

install mailutils to get mails if something fails
sudo dpkg-reconfigure postfix
