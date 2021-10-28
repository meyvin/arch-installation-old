#!/bin/bash

################################################################################
#### Disk variables (todo menu prompt to select a specific disk             ####
################################################################################
install_disk=/dev/nvme0n1
boot_partition=/dev/nvme0n1p1
root_partition=/dev/nvme0n1p2
encrypt_partition=/dev/mapper/archlinux

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

################################################################################
#### Welcome                                                                ####
################################################################################
clear
installer_dialog --title "Welcome" --msgbox "\nWelcome to Meyvin's Arch Linux Installer." 10 60

################################################################################
#### User account Prompts                                                   ####
################################################################################
installer_dialog --title "Root account" --msgbox "\nCreate a root account.\n" 10 60

installer_dialog --title "Root password" --passwordbox "\nEnter a strong password for the root user.\n" 10 60
root_password="$DIALOG_RESULT"
installer_cancel

installer_dialog --title "Root account" --msgbox "\nCreate a user account.\n" 10 60

installer_dialog --title "username" --inputbox "\nPlease enter a username for your home account.\n" 10 60
user_name="$DIALOG_RESULT"
installer_cancel

installer_dialog --title "user password" --passwordbox "\nEnter a strong password for ${user_name}'s account.\n" 10 60
user_password="$DIALOG_RESULT"
installer_cancel

installer_dialog --title "User accounts" --msgbox "\nDone setting up accounts.\n" 10 60
################################################################################
#### Password prompts                                                       ####
################################################################################
installer_dialog --title "Disk encryption" --passwordbox "\nEnter a strong passphrase for the disk encryption." 10 60
encryption_passphrase="$DIALOG_RESULT"
installer_cancel

################################################################################
#### Hostname host                                                              ####
################################################################################
installer_dialog --title "Hostname" --inputbox "\nPlease enter a hostname for this device.\n" 10 60
hostname="$DIALOG_RESULT"
installer_cancel

################################################################################
#### Processor                                                              ####
################################################################################
installer_dialog --title "Select cpu manufacturer" --menu "\nChoose an option\n" 18 100 10 "amd-ucode" "AMD Processor" "intel-ucode" "Intel Processor"		
cpu_ucode="$DIALOG_RESULT"
installer_cancel

################################################################################
#### Graphics                                                               ####
################################################################################
installer_dialog --title "Select gpu manufacturer" --menu "\nChoose an option\n" 18 100 10 "AMD" "" "Intel" "" "Nvidia" ""	
gpu_manufacturer="$DIALOG_RESULT"
installer_cancel

################################################################################
#### Swap size                                                              ####
################################################################################
installer_dialog --title "Swap partition size?" --menu "\nChoose an option\n" 18 100 10 "8G" "" "16G" "" "32G" ""	
swap_size="$DIALOG_RESULT"
installer_cancel


################################################################################
#### Warning                                                                ####
################################################################################
installer_dialog --title "WARNING" --yesno "\nThis script will NUKE ${install_disk}.\nPress <Enter> to continue or <Esc> to cancel.\n" 10 60
installer_cancel
clear

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
sgdisk ${install_disk} -n 2 -t 1:8e00

echo "Format EFI partition"
mkfs.vfat ${boot_partition}

if [[ ! -z $encryption_passphrase ]]; then
    echo "Setting up encryption"
    printf "%s" "$encryption_passphrase" | cryptsetup luksFormat ${root_partition}
    printf "%s" "$encryption_passphrase" | cryptsetup luksOpen ${root_partition} archlinux
    mkinitcpio_hooks="encrypt lvm2"
    lvm_volume="${encrypt_partition}"
else
    exit 0
fi

echo "Setting up LVM"
vgcreate vg1 $lvm_volume
lvcreate -L 60G vg1 -n root
lvcreate -L $swap_size vg1 -n swap
lvcreate -l 100%FREE vg1 -n home

echo "Creating filesystems and enabling swap"
mkfs.vfat /dev/nvme0n1p1
mkfs.ext4 /dev/vg1/root
mkfs.ext4 /dev/vg1/home
mkswap /dev/vg1/swap

################################################################################
#### Install Arch                                                           ####
################################################################################
mount /dev/vg1/root /mnt
mkdir /mnt/home
mount /dev/vg1/home /mnt/home
mkdir /mnt/boot
mount ${boot_partition} /mnt/boot
swapon /dev/vg1/swap

yes '' | pacstrap -i /mnt base linux linux-firmware git vim $cpu_ucode btrfs-progs

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

echo "Disabling annoying pc speaker"
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

echo "Generating initramfs"
sed -i "s/^HOOKS.*/HOOKS=\(base udev autodetect modconf block keyboard ${mkinitcpio_hooks} filesystems keyboard fsck\)/" /etc/mkinitcpio.conf
kernel_version=$( ls /usr/lib/modules )
mkinitcpio -g /boot/initramfs-linux.img -k $kernel_version

echo "Setting root password"
echo "root:${root_password}" | chpasswd

echo "Enable Colors, Parallel Downloads and Multilib in /etc/pacman.conf"
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

echo "Updating pacman"
pacman -Syuu
EOF

################################################################################
#### Graphic driver variabele                                               ####
################################################################################
case $gpu_manufacturer in
	AMD)	
		gpu_drivers="mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon";;
	Intel)
		gpu_drivers="mesa lib32-mesa xf86-video-intel vulkan-intel";;
	Nvidia)	
		gpu_drivers="nvidia lib32-nvidia-utils";;
	*) ;;
esac

################################################################################
#### Installing basic packages                                              ####
################################################################################
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
firewalld \
flatpak \
$gpu_drivers \
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
mirror_country="Netherlands"

sudo timedatectl set-ntp true
sudo hwclock --systohc

systemctl enable NetworkManager 
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable firewalld
systemctl enable acpid

echo "Retrieve and filter the latest Pacman mirror list for ${mirror_country}"
reflector -c $mirror_country -a 12 --sort rate --save /etc/pacman.d/mirrorlist

echo "Setting up Firewall"
firewall-cmd --add-port=1025-65535/tcp --permanent
firewall-cmd --add-port=1025-65535/udp --permanent
firewall-cmd --reload

echo "Setting up ${user_name} account"
useradd -m ${user_name}
echo "${user_name}:${user_password}" | chpasswd
echo "${user_name} ALL=(ALL) ALL" >> /etc/sudoers.d/${user_name}
EOF

################################################################################
#### The end                                                                ####
################################################################################
echo "Done installing a Basic Arch System.\n Let's reboot the system and configure the efistub!"
echo -e "\e[1;32mRebooting IN 5..4..3..2..1..\e[0m"
sleep 5
sudo reboot
