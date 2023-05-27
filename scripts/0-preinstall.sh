#!/usr/bin/env bash

echo -ne "
-------------------------------------------------------------------------

        ░██████╗██╗░░░██╗██████╗░██╗░░░██╗██╗░░██╗░█████╗░░██████╗
        ██╔════╝╚██╗░██╔╝██╔══██╗╚██╗░██╔╝██║░██╔╝██╔══██╗██╔════╝
        ╚█████╗░░╚████╔╝░██║░░██║░╚████╔╝░█████═╝░██║░░██║╚█████╗░
        ░╚═══██╗░░╚██╔╝░░██║░░██║░░╚██╔╝░░██╔═██╗░██║░░██║░╚═══██╗
        ██████╔╝░░░██║░░░██████╔╝░░░██║░░░██║░╚██╗╚█████╔╝██████╔╝
        ╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═════╝░

-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------

Setting up mirrors for optimal download
"
source $CONFIGS_DIR/setup.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
-------------------------------------------------------------------------
                    Setting up $iso mirrors for faster downloads
-------------------------------------------------------------------------
"
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null
echo -ne "
-------------------------------------------------------------------------
                    Installing Prerequisites
-------------------------------------------------------------------------
"
pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc
echo -ne "
-------------------------------------------------------------------------
                    Formating Disk
-------------------------------------------------------------------------
"
umount -A --recursive /mnt
# disk prep
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

# create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK}

# make filesystems
echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
-------------------------------------------------------------------------
"
# Creates the btrfs subvolumes. 
createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
}

# Mount all btrfs subvolumes after root has been mounted.
mountallsubvol () {
    mount -o ${MOUNT_OPTIONS},subvol=@home ${partition3} /mnt/home
    mount -o ${MOUNT_OPTIONS},subvol=@tmp ${partition3} /mnt/tmp
    mount -o ${MOUNT_OPTIONS},subvol=@var ${partition3} /mnt/var
    
}

# BTRFS subvolulme creation and mounting. 
subvolumesetup () {
# create nonroot subvolumes
    createsubvolumes     
# unmount root to remount with subvolume 
    umount /mnt
# mount subvolume
    mount -o ${MOUNT_OPTIONS},subvol=@ ${partition3} /mnt
# make directories home, var, tmp
    mkdir -p /mnt/{home,var,tmp}
# mount subvolumes
    mountallsubvol
}

if [[ "${DISK}" =~ "nvme" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi

if [[ "${FS}" == "btrfs" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.btrfs -L ROOT ${partition3} -f
    mount -t btrfs ${partition3} /mnt
    subvolumesetup
elif [[ "${FS}" == "ext4" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.ext4 -L ROOT ${partition3}
    mount -t ext4 ${partition3} /mnt

fi


# mount target
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi
echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive
-------------------------------------------------------------------------
"
pacstrap /mnt base base-devel linux-zen linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/SyDykOS
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -L /mnt >> /mnt/etc/fstab
echo " 
  Generated /etc/fstab:
"
cat /mnt/etc/fstab
echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
else
    pacstrap /mnt efibootmgr --noconfirm --needed
fi

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 1-setup.sh
-------------------------------------------------------------------------
"
