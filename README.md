# rockpro64
A log of installation procedures for Armbian, Nextcloudpi and Grocy on the RockPro64

## Download Armbian image and verify
### Download
Link: https://dl.armbian.com/rockpro64/Bionic_current

As of 20200404 this is `Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.7z`

I chose this version because I don't need a desktop and I wanted the latest kernel.

### Extract

`7z x Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.7z`

### Verify the image's signature

```
#download public key from the database
gpg --keyserver ha.pool.sks-keyservers.net --recv-key DF00FAF1C577104B50BF1D0093D6889F9F0E78D5
#
gpg --verify Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.img.asc
gpg: assuming signed data in 'Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.img'
gpg: Signature made Mo 17 Feb 2020 13:39:05 CET
gpg:                using RSA key DF00FAF1C577104B50BF1D0093D6889F9F0E78D5
gpg: Good signature from "Igor Pecovnik <igor@armbian.com>" [unknown]
gpg:                 aka "Igor Pecovnik (Ljubljana, Slovenia) <igor.pecovnik@gmail.com>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: DF00 FAF1 C577 104B 50BF  1D00 93D6 889F 9F0E 78D5
```

Apparently, the warning can be ignored (source: https://docs.armbian.com/User-Guide_Getting-Started/)

### Verify download integrity using sha256sum
```
sha256sum -c Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.img.sha
Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.img: OK
```

### Format SD card
```
sudo mkdosfs -F 32 -I /dev/mmcblk0p1
```
### Burn image using 'etcher'
https://www.balena.io/etcher/

## First boot
Insert SD card into RockPro64 slot.
Connect power and ethernet cable.
Press power button.
Look up IP in FritzBox: device is simply called 'rockpro64'

ssh into device

ssh root@192.168.178.55

PW is 1234

You're prompted to immediately change the root PW.
Then you're prompted to add a sudo-enabled new user.

It's a good idea to then install updates
sudo apt update
sudo apt upgrade

Set a static IP (in FritzBox and/or in RockPro64)
armbian-config > network

Install docker from armbian-config > Software > Softy > Docker


