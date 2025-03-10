#!/bin/bash

TEMP_FILE="/tmp/reboot_confirmation_needed"
CONFIRMATION_TIMEOUT=10 # in seconds
REBOOT_TIMEOUT=5
CMDLINE=$(cat /proc/cmdline)
PARAM="vfio-pci.ids"
VALUE="10de:1f99,10de:10fa"
KERNEL_NAME="linux-cachyos"

if [ $EUID -ne "0" ]; then
    echo "Нужны права рут!"
    hyprctl notify 3 3000 0 "fontsize:24  Нужны права рут!"
    exit 1
fi

if [ -f "$TEMP_FILE" ]; then #
    FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$TEMP_FILE") ))

    if [ "$FILE_AGE" -le "$CONFIRMATION_TIMEOUT" ]; then
        rm "$TEMP_FILE"

        if echo "$CMDLINE" | grep -qE " ${PARAM}="; then
            NEW_CMDLINE=$(echo "$CMDLINE" | sed "s/ ${PARAM}=[^ ]*//g;s/ module_blacklist=[^ ]*//g")
            hyprctl notify -1 ${REBOOT_TIMEOUT}000 "rgb(00ff00)" "fontsize:24 Перезагрузка с драйверами NVIDIA через ${REBOOT_TIMEOUT} сек..."
            sleep $REBOOT_TIMEOUT
            kexec -l /boot/vmlinuz-$KERNEL_NAME --initrd=/boot/initramfs-$KERNEL_NAME.img --append="${NEW_CMDLINE}"
            systemctl kexec
        else
            NEW_CMDLINE="$CMDLINE ${PARAM}=${VALUE} module_blacklist=nvidia,nvidia_uvm,nvidia_drm,nvidia_modeset"
            hyprctl notify -1 ${REBOOT_TIMEOUT}000 "rgb(00b2ff)" "fontsize:24 Перезагрузка с драйверами VFIO через ${REBOOT_TIMEOUT} сек..."
            sleep $REBOOT_TIMEOUT
            kexec -l /boot/vmlinuz-$KERNEL_NAME --initrd=/boot/initramfs-$KERNEL_NAME.img --append="${NEW_CMDLINE}"
            systemctl kexec
        fi
    else
        rm "$TEMP_FILE"
        hyprctl notify -1 3000 "rgb(ff0000)" "fontsize:24 Время подтверждения перезагрузки истекло."
    fi
else
    touch "$TEMP_FILE"
    if echo "$CMDLINE" | grep -qE " ${PARAM}="; then
        hyprctl notify -1 ${CONFIRMATION_TIMEOUT}000 "rgb(ffff00)" "fontsize:24 Подтвердите перезагрузку с драйверами NVIDIA пока видно это уведомление..."
    else
        hyprctl notify -1 ${CONFIRMATION_TIMEOUT}000 "rgb(ffff00)" "fontsize:24 Подтвердите перезагрузку с драйверами VFIO пока видно это уведомление..."
    fi
fi

exit 0
