#!/bin/bash

if [ $EUID -ne "0" ]; then
    echo "Нужны права рут!"
    hyprctl notify 3 3000 0 "fontsize:24  Нужны права рут!"
    exit 1
fi

PARAM="vfio-pci.ids"
VALUE="10de:1f99,10de:10fa"
KERNEL_NAME="linux-cachyos"

CMDLINE=$(cat /proc/cmdline)

if echo "$CMDLINE" | grep -qE " ${PARAM}="; then
    NEW_CMDLINE=$(echo "$CMDLINE" | sed "s/${PARAM}=[^ ]*//g")
    hyprctl notify -1 5000 "rgb(00ff00)" "fontsize:24 Перезагрузка с драйверами NVIDIA через 5 сек..."
    sleep 5
    kexec -l /boot/vmlinuz-$KERNEL_NAME --initrd=/boot/initramfs-$KERNEL_NAME.img --append="${NEW_CMDLINE}"
    systemctl kexec
else
    NEW_CMDLINE="$CMDLINE ${PARAM}=${VALUE}"
    hyprctl notify -1 5000 "rgb(00b2ff)" "fontsize:24 Перезагрузка с драйверами VFIO через 5 сек..."
    sleep 5
    kexec -l /boot/vmlinuz-$KERNEL_NAME --initrd=/boot/initramfs-$KERNEL_NAME.img --append="${NEW_CMDLINE}"
    systemctl kexec
fi
