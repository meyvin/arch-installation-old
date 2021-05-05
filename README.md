# Arch linux - encrypted btrfs Gnome installation
This is my personal repo to install Arch Linux. I am not an expert so take this guide with a grain of salt. It is still an exploration for me as well. Most of the information comes from [Arch Wiki](https://wiki.archlinux.org/), [EFLinux.com](https://eflinux.com/) and [Mutschler.eu](https://mutschler.eu/).

This guide assumes you are installing Arch on a nvme ssd (***nvme0n1***). Find your own designated installation device by first looking it up via `lsblk`

## Create and boot the Arch installer
1. Grab the latest Arch iso from [https://archlinux.org/](https://archlinux.org).
2. Use [https://www.balena.io/etcher/](Etcher), `DD` or whatever floats your boat to create a bootable usb device.
3. Boot the Arch usb installer.

## Optional: setup wifi if ethernet is not available
1. Search the wlan interface link with: `ip link`
2. `ip link set {interface} up`
3. `wpa_supplicant -B -i interface -c <(wpa_passphrase MYSSID passphrase)`
4. `dhcpcd`.

## Optional: enable SSH if you want to install it through another device
1. Add a root password: `passwd`
2. Enable the ssh service: `systemctl enable sshd.service`

## Partitions
1. `gdisk /dev/nvme0n1`
2. If your drive still has partitions erase them with the `d` command first.
3. Efi Partition: `n > default > default > +512M > ef00`
4. Swap Partition: `n > default > default > +16G > 8200`
5. Root Partition: `n > default > default > default > default`
6. Write all changes: `w`
7. Check to see if everything is ok: `lsblk`
8. `mkfs.fat -F32 /dev/nvme0n1p1`
9. `mkswap /dev/nvme0n1p2`
10. `swapon /dev/nvme0n1p2`

## LUKS
1. `cryptsetup luksFormat /dev/nvme0n1p3`
2. `cryptsetup luksOpen /dev/nvme0n1p3 cryptroot`

## BTRFS
1. `mkfs.btrfs /dev/mapper/cryptroot`
2. `mount /dev/mapper/cryptroot /mnt && cd /mnt`
3. `btrfs subvolume create @`
4. `btrfs subvolume create @home`
5. `btrfs subvolume create @cache`
6. `cd && umount /mnt`
7. `mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@ /dev/mapper/cryptroot /mnt`
8. `mkdir /mnt/home && mkdir -p /mnt/var/cache`
9. `mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@home /dev/mapper/cryptroot /mnt/home`
10. `mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@cache /dev/mapper/cryptroot /mnt/var/cache`

## EFI Partition
1. `mkdir /mnt/boot && mount /dev/nvme0n1p1 /mnt/boot`

## Arch base packages
1. Install all the arch base packages using: `pacstrap /mnt base linux linux-firmware git vim amd-ucode btrfs-progs` Replace `amd-ucode` with `intel-ucode` if you have an Intel processor.

## Filesystem table
1. `genfstab -U /mnt >> /mnt/etc/fstab`

## Chroot into installation and clone repo
1. `arch-chroot /mnt`
2. `cd / && git clone https://github.com/meyvin/arch-installation && cd arch-installation`
3. Make changes to the `basic-installation.sh` script. In particular the user related variables.
4. `chmod +x ./basic-installation.sh && ./arch-installation/basic-installation.sh`

## Mkinitcpio configuration
1. add `btrfs` to the `/etc/mkinitcpio.conf` modules.
2. add `encrypt` to the `/etc/mkinitcpio.conf` hooks before the `filesystems` entry.
3. regenerate `mkinitcpio -p linux`

## Grub
1. Grab the UUID of the root partition (not the mapper) with `blkid` In my case it is the UUID of /dev/nvme0n1p3.
2. `vim /etc/default/grub` and add the following line to `GRUB_CMDLINE_LINUX_DEFAULT`: `cryptdevice=UUID={UUID}:cryptroot root=/dev/mapper/cryptroot`
3. `grub-mkconfig -o /boot/grub/grub.cfg`
4. `exit`
5. Hopefully everything went right and you can `shutdown -r now` and boot into your Arch installation.

## Gnome
1. Install the Gnome desktop environment through the `` script. Don't forget to `chmod +x` it first.
2. `cd /arch-installation && chmod +x ./gnome-installation.sh && ./gnome-installation.sh`
2. The system will automaticly reboot into the Gnome DE.

## Post-installation Paru, Timeshift, Timeshift-autosnap and other software
1. `sudo pacman -Syyu`
2. `sudo chown $USER:$USER -R /arch-installation && cd /arch-installation`. Otherwise we will run into issues later with the Paru AUR helper related packages.
3. Edit the `post-installation.sh` script to your liking.
4. `cd /arch-installation && chmod +x ./post-installation.sh && ./post-installation.sh`
5. I seperated all my development dependencies into `dev-environment.sh`. You can change and make this executable and run it if you want to. It's not a necessary step.
6. All my repo files are unnecesary at this stage. Since you probably entered a password in the `basic-installation.sh` script it would be wise to delete everything: `sudo rm -R /arch-installation`
7. If you have enabled ssh don't forget to disable it again: `sudo systemctl disable sshd.service`

## Timeshift settings
1. Select “BTRFS” as the “Snapshot Type”; continue with “Next”
2. Choose your BTRFS system partition as “Snapshot Location”; continue with “Next”
3. “Select Snapshot Levels” (type and number of snapshots that will be automatically created and managed/deleted by Timeshift), recommendations:
    - Keep “Daily” at 5
    - Activate “Boot”, but change to 3
    - Activate “Stop cron emails for scheduled tasks”
    - Continue with “Next”
    - I also include @home subvolume (which is not selected by default). Note that when you restore a snapshot Timeshift will ask you again whether or not to include @home in the restore process.
    - Click “Finish”
4. “Create” your first snapshot manually and exit Timeshift.

## Encrypted swap without hibernation or suspend-to-disk
The easy way out if you want to have an encrypted swap partition without all the fancy stuff.

1. `sudo -i`
2. `export SWAPUUID=$(blkid -s UUID -o value /dev/nvme0n1p2)`
3. `echo "cryptswap UUID=${SWAPUUID} /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512" >> /etc/crypttab`
4. Check to see if everything went well: `cat /etc/crypttab`
5. Make changes to fstab: `sed -i "s|UUID=${SWAPUUID}|/dev/mapper/cryptswap|" /etc/fstab`. The sed command replaces the UUID of your swap partition with the encrypted device `/dev/mapper/cryptroot`.
6. Another check to see if everything went well: `cat /etc/fstab`
