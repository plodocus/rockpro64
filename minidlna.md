MiniDLNA is a lightweight DLNA/UPnP server that can stream pictures, music and movies.
I set it up to stream movies that are stored in my Nextcloud account.
Installation is easy
```
sudo apt install minidlna
```
Only configuration is setting the media folder which in my case is the Movies folder of my Nextcloud.
The minidlna daemon runs under user `minidlna`.
To be able to stream the media in nextcloud folder the user has to be added to the `www-data` group:
```
sudo usermod -a -G www-data minidlna
```

That's it. The server runs as a systemd service.
