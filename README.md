# Arch linux - encrypted btrfs DWM installation
This is my personal repo to install Arch Linux. I am not an expert so take this guide with a grain of salt. It is still an exploration for me as well. Most of the information comes from [Arch Wiki](https://wiki.archlinux.org/), [EFLinux.com](https://eflinux.com/) and [Mutschler.eu](https://mutschler.eu/).

This guide assumes you are installing Arch on a nvme ssd (***nvme0n1***). Find your own designated installation device by first looking it up via `lsblk`

## Create and boot the Arch installer
1. Grab the latest Arch iso from [https://archlinux.org/](https://archlinux.org).
2. Write the image to a USB device: `sudo dd bs=4M if=arch.iso of=/dev/sdx conv=fdatasync status=progress`
3. Boot the Arch usb installer.

## Optional: setup wifi if ethernet is not available
1. Search the wlan interface name with: `ip link`
2. `ip link set {interface-name} up`
3. `iwctl` for an interactive prompt.
4. `wsc {device} push-button` to connect using WPS. To connecting using a passphrase: `iwctl --passphrase passphrase station device connect SSID`

## Optional: enable SSH if you want to install it through another device
1. Add a root password: `passwd`
2. The SSH server is enabled by default but if it's not: `systemctl enable sshd.service`

## Partitions
1. `gdisk /dev/nvme0n1`
2. If your drive still has partitions erase them with the `d` command first.
3. Efi Partition: `n > default > default > +512M > ef00`
4. Root Partition: `n > default > default > default > default`
5. Write all changes: `w`
6. Check to see if everything is ok: `lsblk`
7. `mkfs.vfat /dev/nvme0n1p1`
8. `mkswap /dev/nvme0n1p2`
9. `swapon /dev/nvme0n1p2`

## LUKS
1. `cryptsetup luksFormat /dev/nvme0n1p2`
2. `cryptsetup luksOpen /dev/nvme0n1p2 cryptroot`

## BTRFS
1. `mkfs.btrfs /dev/mapper/cryptroot`
2. `mount /dev/mapper/cryptroot /mnt && cd /mnt`
3. `btrfs subvolume create @`
4. `btrfs subvolume create @home`
5. `btrfs subvolume create @var`
6. `cd && umount /mnt`
7. `mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@ /dev/mapper/cryptroot /mnt`
8. `mkdir /mnt/home && mkdir  /mnt/var`
9. `mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@home /dev/mapper/cryptroot /mnt/home`
10. `mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@var /dev/mapper/cryptroot /mnt/var`

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
1. Add all the hooks to the `/etc/mkinitcpio.conf` file using: `sed -i 's/^HOOKS=.*/HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck"/' /etc/mkinitcpio.conf`
3. Regenerate it `mkinitcpio -p linux`

## Grub root decrypt configuration
1. Let's create a variable that contains the `/dev/nvme0n1p2` UUID and put it in something that GRUB can work with: `export ROOTPARTITION="cryptdevice=UUID=$(blkid -s UUID -o value /dev/nvme0n1p2):cryptroot root=/dev/mapper/cryptroot"`
2. Use `sed` to add this line to the `/etc/default/grub` configuration file using the following command: `sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="[^"]*|& '"$ROOTPARTITION"'|' /etc/default/grub`
3. Reconfigure grub: `grub-mkconfig -o /boot/grub/grub.cfg`
4. `exit`
5. Hopefully everything went right and you can `shutdown -r now` and boot into your Arch installation.

## ZRAM
1. Install Zramd aur package: `paru -S zramd`
2. Edit the config file at: `/etc/default/zramd`
3. Enable using: `sudo systemctl enable --now zramd.service`

## SWAY
1. If you didn't reboot or are still logged in as root, you should now switch to your user before executing the upcoming script.
2. Ready to install Sway: `sudo mv -R /arc-installation ~/; sudo chown $USER:$USER
   ~/arch-installation; chmod +x ~/arch-installation/sway-installation.sh;
./arch-installation/sway-installation.sh`
3. Reboot and after logging in, Sway should start automatically.

## Post-installation Paru, Timeshift, Timeshift-autosnap and other software
1. All my repo files are unnecesary at this stage. Since you probably entered a password in the `basic-installation.sh` script it would be wise to delete everything: `sudo rm -R ~/arch-installation`
2. If you have enabled ssh don't forget to disable it again: `sudo systemctl disable sshd.service`

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
