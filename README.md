# Introduction
Procedures to set up NextCloudPi, Grocy and CalibreWeb on the RockPro64.
This is mainly intended as a log for myself so I can reproduce and debug more easily.
I am making this public in a hope that some of the things might help others with similar plans.

The goal is to have a private server that is available on the internet.
A static hostname is assigned using a dynamic DNS service (DuckDNS).
SSL termination is done by a reverse proxy (HAproxy) which directs traffic to individual web services.
Web services (including the reverse proxy) are run as docker containers.
This provides flexibility in the case of future additions of web services, more isolated configurations, easier upgrades and maybe increased security (not sure about the last part).
This flow chart should make this clearer:
![](https://mermaid.ink/img/eyJjb2RlIjoiZ3JhcGggTFJcblx0QVtCcm93c2VyXSA8LS0-fGh0dHBzfCBCW1wiSEFQcm94eVwiXVxuICAgIGNlcnRib3Q8LS0-TGV0c0VuY3J5cHRcbiAgICBBIC0tPnxodHRwfCBCXG4gICAgQiAtLT58cmVkaXJlY3QgaHR0cCB0byBodHRwc3wgQlxuICAgIHN1YmdyYXBoIHJvY2twcm9cbiAgICAgICAgQi0tLVNTTFxuICAgICAgICBjZXJ0Ym90LS0-U1NMKFwiY2VydGlmaWNhdGVzXCIpXG4gICAgICAgIHN1YmdyYXBoIFwiZm9vbmV0IChkb2NrZXIpXCJcbiAgICAgICAgICAgIEIgLS0-fGh0dHB8IEMoTmV4dENsb3VkUGkpXG4gICAgICAgICAgICBCIC0tPnxodHRwfCBEKGdyb2N5KVxuICAgICAgICAgICAgQiAtLT58aHR0cHwgRShjYWxpYnJlKVxuICAgICAgICBlbmRcbiAgICBlbmQiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlfQ)

# Basic configuration
## Operating system
Armbian seems to be the de-facto standard for these kinds of devices.
After downloading and verification it needs to be written to a microSD card.
I'm using a (lookthisup) 32 GB microSD card.
Currently, there are better options available but I haven't had issues with this one yet.

As of 20200404 the CLI version with the latest kernel is
![Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.7z](https://dl.armbian.com/rockpro64/Bionic_current)

Extract it
```
7z x Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.7z
```

Verify the image's signature
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

Verify download integrity using sha256sum
```
sha256sum -c Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.img.sha
Armbian_20.02.1_Rockpro64_bionic_current_5.4.20.img: OK
```

Format SD card
```
sudo mkdosfs -F 32 -I /dev/mmcblk0p1
```

Burn image using GUI program ![etcher](https://www.balena.io/etcher/)

## First boot: users and static IP
Insert microSD card into RockPro64 slot.
Connect power and ethernet cable (to network router).
Press power button.
Look up the device's IP in your router.
The hostname defaults to 'rockpro64'.

ssh into device
```
ssh root@192.168.178.55
```
Default PW is 1234.

You're prompted to immediately change the root PW.
Then you're prompted to add a sudo-enabled new user.

It's a good idea to then install updates
```
sudo apt update
sudo apt upgrade
```

Set a static IP (in router and/or in RockPro64) `armbian-config > network.
Reboot and ssh into RockPro using the new IP.
Since most of the web services will be run as containers, install docker from armbian-config > Software > Softy > Docker.

## USB flash drive prep
Right now this whole project is a little proof of principle, so I am just using a small USB 3.0 thumb drive with 64 GB capacity.
Eventually, this is going to be replaced by a bigger SSD drive.

### Format as BTRFS
B-tree FS (Btrfs) seems to be the newest coolest file system and NextCloud seems to be using some of its advanced features.

```
sudo mkfs.btrfs -L USBDRIVE -f /dev/sda
btrfs-progs v4.15.1
See http://btrfs.wiki.kernel.org for more information.

Label:              USBDRIVE
UUID:               abfdb7fb-bf06-433e-abad-7fc3437c7c51
Node size:          16384
Sector size:        4096
Filesystem size:    57.30GiB
Block group profiles:
  Data:             single            8.00MiB
    Metadata:         DUP               1.00GiB
      System:           DUP               8.00MiB
      SSD detected:       no
      Incompat features:  extref, skinny-metadata
      Number of devices:  1
      Devices:
         ID        SIZE  PATH
             1    57.30GiB  /dev/sda
```

### Mounting
Every web service that uses persistent data gets a subfolder under the USB flashdrive's mount point.
First create mount point:

```
sudo mkdir /media/usb0
```

Add entry to `/etc/fstab` so that flashdrive is automatically mounted on boot:

```
UUID=abfdb7fb-bf06-433e-abad-7fc3437c7c51 /media/usb0 btrfs users,rw,exec 0 0
```

Mount as user

```
mount /media/usb0
```

To avoid permission problems change the external drive's owner to local user.
```
sudo chown daniel:daniel /media/ncp
```

<details>
    <summary>Avoid permission problems! (Click to expand)</summary>

    Make sure that the user has execute rights in the folder that will be used for NextCloud, i.e. the drive must be mounted with `exec` and the 
    Local user must have write and execution rights, i.e. the drive must be mounted using the `exec,rw` options and the directory must have write and execution rights. Otherwise 'Permission denied' errors will pop up when trying to use the NextCloudPi docker (these are the logs of the container):

    ```
    sudo docker logs -f nextcloudpi
    Initializing empty volume..
    Making /usr/local/etc/ncp-config.d persistent ...
    Making /etc/services-enabled.d persistent ...
    Making /etc/letsencrypt persistent ...
    Making /etc/shadow persistent ...
    Making /etc/cron.d persistent ...
    Making /etc/cron.daily persistent ...
    Making /etc/cron.hourly persistent ...
    Making /etc/cron.weekly persistent ...
    Making /usr/local/bin persistent ...
    /run-parts.sh: line 47: /etc/services-enabled.d/010lamp: Permission denied
    /run-parts.sh: line 47: /etc/services-enabled.d/020nextcloud: Permission denied
    Init done
    /run-parts.sh: line 6: /etc/services-enabled.d/020nextcloud: Permission denied
    /run-parts.sh: line 6: /etc/services-enabled.d/010lamp: Permission denied
    /run-parts.sh: line 6: /etc/services-enabled.d/000ncp: Permission denied
    /run-parts.sh: line 42: /etc/services-enabled.d/000ncp: Permission denied
    /run-parts.sh: line 47: /etc/services-enabled.d/010lamp: Permission denied
    /run-parts.sh: line 47: /etc/services-enabled.d/020nextcloud: Permission denied
    Init done
    ```
</details>

## Network configuration
My internet provider uses DS-Lite which means that I can only use IP6 to access my server from the internet.
This setup is behind a FritzBox router, so other routers will require slightly different configurations than explained below.
I recommend using tiny webservers for testing the network configuration, like `hypriot/rpi-busybox-httpd` and `containous/whoami`.
### Forward ports in router
Expose the containers'  ports 80 to the host's ports 80 and 443 to test the port forwarding, like
```
sudo docker run --name web0 -p 80:80 hypriot/rpi-busybox-httpd
sudo docker run --name web1 -p 80:443 containous/whoami
```

Forward ports 80 and 443 in router and try to access the web servers under `http://[IP6]:80` and`http://[IP6]:443`.
Don't try https yet, since certificates haven't been setup yet.
Some browser don't support accessing port 443 without https.
#### FritzBox
Internet > Freigaben > rockpro64.
IPv6 Interface ID: last four groups of first ip6 address given by ip -6 addr

### Dynamic DNS: DuckDNS
A dynamic DNS service maps a (sub)domain to a dynamically changing IP.
With DuckDNS you get a subdomain like "subdomain.duckdns.org".
I chose this service because it supports IP6 and the modification of TXT records, which will be necessary for the type of certificate challenge that I am using.

Create a NetworkManager dispatcher script in `/etc/NetworkManager/dispatcher.d/30-upduckdns` that executes `/usr/local/bin/duckdns_update_ip6.sh` on every reconnect.
This script gets the current IP6 and updates the DNS entry using `/etc/duckdns.org/token` and `/etc/duckdns.org/domains`.
Make sure all of these scripts are executable.

#### DNS rebind protection
When I visited "mydomain.duckdns.org" from outside my network (mobile internet, VPN) I could access the web servers but not from inside the network.
To be able to access it via the name from within the network I needed to add an exception for the domain in the FritzBox: DNS Rebind exception.

### Let's Encrypt
Let's Encrypt provides free SSL certificates that are required for encrypted communication.
I want to be able to access different web services by my own subdomains, like "cloud.mydomain.duckdns.org" and "grocy.mydomain.duckdns.org".
For this, a wildcard certificate is needed, which requires the successful certification by DNS challenge.

Install `certbot` per their instructions and run this command.

```
sudo certbot certonly \
    --manual \
    --manual-public-ip-logging-ok \
    --non-interactive \
    --agree-tos \
    -m <name@email.com> \
    --preferred-challenges dns \
    --domains <single_domain> \
    --manual-auth-hook /usr/local/bin/certbot_authenticator.sh \
    --manual-cleanup-hook /usr/local/bin/certbot_cleanup.sh \
    --server https://acme-v02.api.letsencrypt.org/directory
```

This has to be done once each for `yourdomain.duckdns.org` and `\*.yourdomain.duckdns.org` because DuckDNS doesn't appear to support multiple TXT records.
The scripts `certbot_authenticator.sh` and `certbot_cleanup.sh` put the TXT record at `\_acme-challenge.yourdomain.duckdns.org` and clears them after authentication.
If authentication was successful, certbot should have created a cronjob for automatic renewal of the certificates.

### Reverse proxy using HAproxy
As stated above, I want to be able to access different web services by calling different subdomains.
This requires a reverse proxy that redirects traffic to different servers dependent of the source hostname.
In addition, a reverse proxy can be used for SSL termination, i.e. only one service has to be configured to use the certificates.

In my configuration HAProxy forwards requests to different docker containers in a common docker network.
The config file is found in at etc/haproxy/haproxy.cfg.
HAproxy expects SSL certificates in a slightly different way than provided by certbot.
Concretely, it needs `fullchain.pem` and `privkey.pem` concatenated to a single file with the name `domain.pem`.
Concatenate them into the folder /etc/haproxy/certs.
I have written a small script and systemd services that watches for newly created files in /etc/letsencrypt/archive/\*.
A more elegant solution would be to watch for changes of the symlink /etc/letsencrypt/live/\*, but the version of inotifytools doesn't support it.
Start the service:
```
systemctl enable letsencrypt_cat.service
```

Create a common docker network, re-run the test servers without exposing their ports and run haproxy (make sure that haproxy.cfg points to web0 and web1):
```
sudo docker network create foonet
sudo docker run --name web0 --net=foonet hypriot/rpi-busybox-httpd
sudo docker run --name web1 --net=foonet containous/whoami
sudo docker run \
    -d \
    --name hpx \
    -p 80:80 \
    -p 443:443 \
    --net=foonet \
    -v /etc/haproxy:/usr/local/etc/haproxy:ro \
    --restart unless-stopped
    haproxy:alpine \
    haproxy -f /usr/local/etc/haproxy/haproxy.cfg
```

HAProxy needs to be run as the last container!
If additional containers are added to `foonet` or if `haproxy.cfg` is changed, just restart the container:
```
sudo docker restart hpx
```

## NextCloudPi
Create and start new container
```
sudo docker run -d -v /media/usb0/ncp:/data --name nextcloudpi ownyourbits/nextcloudpi
sudo docker run \
    -d \
    --net=foonet \
    -v /media/usb0/ncp:/data \
    --name nextcloudpi \
    --restart unless-stopped \
    ownyourbits/nextcloudpi
```

This creates a detached (`-d`) container called 'nextcloudpi'.
Guest directory `/data` is mapped to host directory `/media/usb0/ncp`.

Wait for 'Init done' in `sudo docker logs -f nextcloudpi`. This will take a few minutes.

### Setup NextCloudpi
This might have to be done once without the reverse proxy running.

Access NCP admin panel through haproxy:
disable ssl stuff in etc/apache2/sites-available/ncp.conf

Access NextCloudPi instance by typing the RockPro's IP into the browser.
There will probably be a certificate error.
A website with the NextCloudPi user and password and the NextCloud user and password will appear.
Save the passwords and click 'activate'.
The page reloads and there is another certificate error.
Log in using the NCP user (the first password from the page before).

Forced HTTPS should be disabled because HAProxy handles SSL termination.

## Grocy
```
sudo docker run \
    -d \
    --name grocy \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=Europe/Berlin \
    -v /media/usb0/grocy/:/config \
    --net=foonet \
    --restart unless-stopped \
    linuxserver/grocy
```

## CalibreWeb
```
docker run \
    -d \
    --name=calibre-web \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=Europe/Berlin \
    -e DOCKER_MODS=linuxserver/calibre-web:calibre \
    -v /media/usb0/calibre-web:/config \
    -v /media/usb0/calibre-db:/books \
    --net=foonet
    --restart unless-stopped \
    linuxserver/calibre-web
```
