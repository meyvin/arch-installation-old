#!/bin/bash

################################################################################
#### Dialog function                                                        ####
################################################################################
installer_dialog() {
    DIALOG_RESULT=$(whiptail --clear --backtitle "Meyvin's Arch Installer" "$@" 3>&1 1>&2 2>&3)
    DIALOG_CODE=$?
}

installer_cancel() {
if [[ $DIALOG_CODE -eq 1 ]]; then
    installer_dialog --title "Cancelled" --msgbox "\nScript was cancelled at your request." 10 60
    exit 0
fi
}

install_disk=/dev/nvme0n1


################################################################################
#### Welcome                                                                ####
################################################################################
clear
installer_dialog --title "Welcome" --msgbox "\nWelcome to Meyvin's Arch Linux Installer." 10 60

################################################################################
#### Prompts                                                                ####
################################################################################
installer_dialog --title "Hostname" --inputbox "\nPlease enter a hostname for this device.\n" 10 60
hostname="$DIALOG_RESULT"
installer_cancel

################################################################################
#### User account Prompts                                                   ####
################################################################################
installer_dialog --title "Root password" --passwordbox "\nEnter a strong password for the root user.\n" 10 60
root_password="$DIALOG_RESULT"
installer_cancel

installer_dialog --title "username" --inputbox "\nPlease enter a username for your personal account.\n" 10 60
user_name="$DIALOG_RESULT"
installer_cancel

installer_dialog --title "user password" --passwordbox "\nEnter a strong password for ${user_name}'s account.\n" 10 60
user_password="$DIALOG_RESULT"
installer_cancel
################################################################################
#### Password prompts                                                       ####
################################################################################
installer_dialog --title "Disk encryption" --passwordbox "\nEnter a strong passphrase for the disk encryption." 10 60
encryption_passphrase="$DIALOG_RESULT"
installer_cancel
################################################################################
#### Warning                                                                ####
################################################################################
installer_dialog --title "WARNING" --yesno "\nThis script will NUKE ${install_disk}.\nPress <Enter> to continue or <Esc> to cancel.\n" 10 60
clear
installer_cancel

################################################################################
#### reset the screen                                                       ####
################################################################################
reset

################################################################################
#### Nuke and set up disk partitions                                        ####
################################################################################
echo "Wiping disk"
wipefs --all ${install_disk}

echo "Creating GPT Partition Table"
sgdisk ${install_disk} -o 

echo "Creating EFI Partition"
sgdisk ${install_disk} -n 1::+512MiB -t 1:ef00

echo "Creating Root partition"
sgdisk ${install_disk} -n 2

echo "Format EFI partition"
mkfs.vfat ${install_disk}1

if [[ ! -z $encryption_passphrase ]]; then
    echo "Setting up encryption"
    printf "%s" "$encryption_passphrase" | cryptsetup luksFormat ${install_disk}2
    printf "%s" "$encryption_passphrase" | cryptsetup luksOpen ${install_disk}2 archlinux
    cryptdevice_boot_param="cryptdevice=${install_disk}2"
    encrypt_mkinitcpio_hook="encrypt"
    physical_volume="/dev/mapper/archlinux"
else
    exit 0
fi

echo "Setting up BTRFS"
mkfs.btrfs /dev/mapper/archlinux
mount $physical_volume /mnt && cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @var

################################################################################
#### Install Arch                                                           ####
################################################################################
cd && umount /mnt
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@ $physical_volume /mnt
mkdir /mnt/home && mkdir /mnt/var
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@home $physical_volume /mnt/home
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@var $physical_volume /mnt/var
mkdir /mnt/boot
mount ${install_disk}1 /mnt/boot

yes '' | pacstrap -i /mnt base linux linux-firmware git vim amd-ucode btrfs-progs

genfstab -U /mnt >> /mnt/etc/fstab

################################################################################
#### Configure base system                                                  ####
################################################################################
arch-chroot /mnt /bin/bash <<EOF
echo "Setting and generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "Setting time zone"
ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
echo "Setting hostname"
echo $hostname > /etc/hostname
sed -i '/localhost/s/$'"/ $hostname/" /etc/hosts
echo "Generating initramfs"
sed -i "s/^HOOKS.*/HOOKS=\(base udev autodetect modconf block keyboard ${encrypt_mkinitcpio_hook} filesystems keyboard fsck\)/" /etc/mkinitcpio.conf
mkinitcpio -p linux
echo "Setting root password"
echo "root:${root_password}" | chpasswd
EOF

arch-chroot /mnt pacman -S \
acpi \
acpi_call \
acpid \
alsa-utils \
avahi \
base-devel \
bash-completion \
bluez \
bluez-utils \
cups \
dialog \
dnsmasq \
dnsutils \
dosfstools \
ebtables \
efibootmgr \
firewalld \
flatpak \
grub \
gvfs \
gvfs-smb \
hplip \
inetutils \
ipset \
iptables-nft \
linux-headers \
network-manager-applet \
networkmanager \
nfs-utils \
nss-mdns \
ntfs-3g \
openbsd-netcat \
openssh \
os-prober \
pipewire \
pipewire-alsa \
pipewire-jack \
pipewire-pulse \
reflector \
rsync \
smbclient \
sof-firmware \
terminus-font \
tlp \
wpa_supplicant \
xdg-user-dirs \
xdg-utils \

arch-chroot /mnt /bin/bash <<EOF
systemctl enable NetworkManager 
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable firewalld
systemctl enable acpid
echo "Setting up ${user_name} account"
useradd -m ${user_name}
echo "${user_name}:${user_password}" | chpasswd
echo "${user_name} ALL=(ALL) ALL" >> /etc/sudoers.d/${user_name}
EOF

################################################################################
#### Install boot loader                                                    ####
################################################################################
arch-chroot /mnt /bin/bash <<EOF
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="[^"]*|& '"cryptdevice=UUID=$(blkid -s UUID -o value ${install_disk}2):archlinux root=/dev/mapper/archlinux"'|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
EOF

################################################################################
#### The end                                                                ####
################################################################################
echo "Done installing a Basic Arch System.\n Let's reboot the system and install a DE/WM!"
echo -e "\e[1;32mRebooting IN 5..4..3..2..1..\e[0m"
sleep 5
sudo reboot
