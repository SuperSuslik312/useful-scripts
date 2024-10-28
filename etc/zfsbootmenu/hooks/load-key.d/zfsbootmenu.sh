#!/bin/bash

# Need to add this binaries to zfsbootmenu initcpio:
# argon2 xxd dialog

export DIALOGRC=/etc/zfsbootmenu/.dialogrc
export SALT=abcd1234

askForPassphrase() {
    while true; do
        tput civis
        PASSWORD=$(dialog --no-cancel --colors --title "\Z1\Zbf\Z7society" --insecure --passwordbox "Enter passphrase or get the fuck out of here" 8 80 3>&1 1>&2 2>&3 3>&-)

        if [ $? -ne 0 ]; then
            clear
            return 1
        fi

        (printf "$PASSWORD" | argon2 $SALT -id -t 3 -m 12 -p 1 -r | xxd -r -p | zfs load-key -L prompt $ZBM_ENCRYPTION_ROOT >/dev/null 2>&1) &
        pid=$!
        hashStatus $pid

        if [ $? -eq 0 ]; then
            break
        else
            tput civis
            dialog --colors --title "\Z1\ZbFUCK YOU" --msgbox "Incorrect passphrase!\nTry again if you want, but it won't get you anywhere.\n(>w<)" 7 57
        fi
    done

    sleep 1
}

hashStatus() {
    local pid=$1
    local count=0
    local total=10000
    local exit_code

    tput civis
    (
        while [ $count -le $total ]; do
            count=$((count + 33))
            percent=$((100 * count / total))
            echo $percent
            sleep .01
        done
    ) | dialog --colors --title "\Z3\ZbTrying decryption" --gauge "Calculating hash..." 6 80 0
    wait $pid
    exit_code=$?
    return $exit_code
}

askForPassphrase
