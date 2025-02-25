#!/bin/bash

TEMP_FILE="/tmp/reboot_confirmation_needed"
CONFIRMATION_TIMEOUT=10 # in seconds
REBOOT_TIMEOUT=5

if [ $EUID -ne "0" ]; then
    echo "Нужны права рут!"
    hyprctl notify 3 3000 0 "fontsize:24  Нужны права рут!"
    exit 1
fi

if [ -f "$TEMP_FILE" ]; then #
    FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$TEMP_FILE") ))

    if [ "$FILE_AGE" -le "$CONFIRMATION_TIMEOUT" ]; then
        rm "$TEMP_FILE"
        PARAM="vfio-pci.ids"
        VALUE="10de:1f99,10de:10fa"
        KERNEL_NAME="linux-cachyos"

        CMDLINE=$(cat /proc/cmdline)

        if echo "$CMDLINE" | grep -qE " ${PARAM}="; then
            NEW_CMDLINE=$(echo "$CMDLINE" | sed "s/${PARAM}=[^ ]*//g")
            hyprctl notify -1 ${REBOOT_TIMEOUT}000 "rgb(00ff00)" "fontsize:24 Перезагрузка с драйверами NVIDIA через ${REBOOT_TIMEOUT} сек..."
            sleep $REBOOT_TIMEOUT
            kexec -l /boot/vmlinuz-$KERNEL_NAME --initrd=/boot/initramfs-$KERNEL_NAME.img --append="${NEW_CMDLINE}"
            systemctl kexec
        else
            NEW_CMDLINE="$CMDLINE ${PARAM}=${VALUE}"
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
    hyprctl notify -1 ${CONFIRMATION_TIMEOUT}000 "rgb(ffff00)" "fontsize:24 Подтвердите перезагрузку пока видно это уведомление..."
fi

exit 0
