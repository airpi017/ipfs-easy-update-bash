# ipfs-easy-update-bash
Bash script for installing IPFS on *nix - debian, darwin, 

**IPFS** is the **I**nter**P**lanetary **F**ile**S**ystem

Imagine `bit torrent` on a `blockchain`.

Files are accessed `bit torrent`-like using a `blockchain` file hash instead of a DNS based location.

Allows an IPFS based device to seed the IPFS when it's the nearest copy of the file hash.

This works great when you're on Mars with the family videos - no more 40min round-trip delays.

Also great for accessing recent content closer to you when sharing - IPFS devices around you hold the content. 

For more information see [ipfs.io](https://ipfs.io/)

## Initial install and bandwidth shaping
Installs `trickle` to shape bandwidth usage - `be vigilant`.

Modifies `~/.profile` so IPFS starts on reboot for your usual `user` account.

Requires a `directoryname` to install the IPFS under

`$ ipfs-easy-install.sh ipfs-project-dir`

## Modify bandwidth shaping after install
Re-run the script and change bandwidth to the level you choose

Script uses `sed` to update `~/.profile` to use the new level for you

New level is applied on your next reboot.

## Overview of the steps used in script
 0. Detect UID and then sudo with original `user` account if UID > 0
 1. Select OS 
 2. Select CPU instruction set
 3. Download `trickle` and specifc IPFS update `.gz` file for your system
 4. Run `ipfs-update` and get available versions
 5. Run `ipfs-update` and install latest version
 6. Shape bandwidth usage using `trickle` - `be vigilant`
 7. Initialise ipfs
 8. Show ipfs readme and then the quick-start pages
 9. Change permissions to the original `user` account
10. Launches WebUI using x-www-browser

`Only Ubuntu 18.04.1 tested so far.`

Separate `.bat` file written for installing on Windows.

