#!/bin/bash
echo '** SETTING SELINUX TO PERMISSIVE'
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/sysconfig/selinux

echo '** PATCHING SYSTEM'
yum clean all && yum -y upgrade

echo '** INSTALLING BASE TOOLKIT'
yum -y install bind-utils mtr nc nmap traceroute wget git lsof xfsdump

echo '** CLEANING UP YUM CACHE'
yum clean all
rm -rf /var/cache/yum

echo '** SHREDDING SENSITIVE DATA'
shred -u /etc/ssh/*_key /etc/ssh/*_key.pub /root/.*history \
/home/*/.*history /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys
sync; sleep 1; sync

echo '** REMOVING MARKETPLACE TAGS'
echo '** PERFORMING DD COPY TO COPY DISK STRUCTURE AND MBR INFO'
dd bs=1024M if=/dev/nvme0n1 of=/dev/nvme1n1 status=progress

echo '** VERIFICATION VIA FDISK'
fdisk -l

echo '** FORCE REFORMATING'
mkfs.xfs -f /dev/nvme1n1p1

echo '** MOUNT THE DISK FOR SECOND PASS COPY USING XFSDUMP AND XFSRESTORE'
mount /dev/nvme1n1p1 /mnt

echo '** PERFORMING SECOND PASS COPY'
xfsdump -l0 -J - /dev/nvme0n1p1 | xfsrestore - /mnt

echo '** FIXING FSTAB'
cat /etc/fstab
sed -i "s/$(xfs_admin -u /dev/nvme0n1p1 | awk '{print $3};')/$(xfs_admin -u /dev/nvme1n1p1 | awk '{print $3};')/g" /mnt/etc/fstab

echo '** AFTER FIXING FSTAB'
cat /etc/fstab

echo '** FIXING GRUB'
cat /boot/grub/grub.conf
cat /boot/grub/menu.lst
cat /boot/grub2/grub.cfg
sed -i "s/$(xfs_admin -u /dev/nvme0n1p1 | awk '{print $3};')/$(xfs_admin -u /dev/nvme1n1p1 | awk '{print $3};')/g" /mnt/boot/grub/grub.conf /mnt/boot/grub/menu.lst /mnt/boot/grub2/grub.cfg

echo '** AFTER GRUB FIX'
cat /boot/grub/grub.conf
cat /boot/grub/menu.lst
cat /boot/grub2/grub.cfg

umount /mnt
