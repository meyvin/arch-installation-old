#!/bin/bash

# Variables
# Root password is the same as the user password
export USERNAME="meyvin"
export PASSWORD="password"
export TIMEZONE="Europe/Amsterdam"
export LANG="en_US.UTF-8"
export KEYMAP="us"
export HOSTNAME="arch"
export ROOTPARTITION="/dev/nvme0n1p2"

# EFI
mkfs.vfat /dev/nvme0n1p1

# Create encrypted root partition
cryptsetup luksFormat $ROOTPARTITION
cryptsetup luksOpen $ROOTPARTITION cryptroot

# BTRFS
mkfs.btrfs /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt && cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @var
cd && umount /mnt
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@ /dev/mapper/cryptroot /mnt
mkdir /mnt/home && mkdir /mnt/var
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@var /dev/mapper/cryptroot /mnt/var

# EFI Partition
mkdir /mnt/boot && mount /dev/nvme0n1p1 /mnt/boot

# Arch Base Packages
pacstrap /mnt base linux linux-firmware git vim amd-ucode btrfs-progs

# Filesystem table
genfstab -U /mnt >> /mnt/etc/fstab

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo "LANG=$LANG" >> /etc/locale.conf
echo "KEYMAP=$KEYMAP" >> /etc/vconsole.conf
echo "$HOSTNAME" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
echo root:$PASSWORD | chpasswd

pacman -S grub grub-btrfs efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call tlp virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat ebtables iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font smbclient
pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
#systemctl enable tlp
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

useradd -m $USERNAME
echo $USERNAME:$PASSWORD | chpasswd
usermod -aG libvirt $USERNAME

echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers.d/$USERNAME

# Chroot
arch-chroot /mnt
sed -i 's/^HOOKS=.*/HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck"/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Grub
export ENCRYPTEDPARTITION="cryptdevice=UUID=$(blkid -s UUID -o value "$ROOTPARTITION"):cryptroot root=/dev/mapper/cryptroot"
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="[^"]*|& '"$ENCRYPTEDPARTITION"'|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "Done installing basic Arch Linux"
