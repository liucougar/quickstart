#!/bin/bash
random_password() {
    local len=${1:-"12"}
    #echo $(</dev/urandom tr -dc A-Za-z0-9\*\&\\-\!\@\#\$\%\(\)| (head -c $1 > /dev/null 2>&1 || head -c ${len}))
    echo "$(tr -dc '[:print:]' < /dev/urandom | fold -w ${len} |grep .*[0-9].*[0-9].* |grep [^0-9]\$ | grep .*[A-Z].*[A-Z].* | grep ^[a-zA-Z] | head -n 1)"
}

add_user() {
    local name=$1
    local groups=${2:+"-G $2"}
    local password=${3:-"$(random_password)"}
    spawn_chroot "adduser -m ${groups} $name"
    set_password "$name" "$password"
}

find_user_home() {
    local username=$1
    echo "$(cat ${chroot_dir}/etc/passwd | grep ^${username} | cut -d: -f6)"
}

add_ssh_file() {
    local user="$1"
    local idfile="$2"
    local filename="$3"

    local homedir="$(find_user_home "$user")"
    local abshomedir="${chroot_dir}$homedir"
    if [ -n "$abshomedir" -a -d "$abshomedir" ]; then
	#create the .ssh dir as the user if not already exist
        spawn_chroot "sudo -u $user mkdir -p \"${abshomedir}/.ssh/\""
        cp "$idfile" "${abshomedir}/.ssh/${filename}"
	#spawn_chroot is needed because the user may not exist on host
	spawn_chroot "chown ${user}:${user} $homedir/.ssh/${filename}"
        if [ "${filename:0:3}" = "id_" ]; then #id_rsa or similar, set proper permission
            chmod 600 $abshomedir/.ssh/${filename}
        fi
    else
        die "add_ssh_file() Unknown user $user"
    fi
}

add_ssh_config() {
    local user=$1
    local filename=$2
    local value="$3"

    local homedir="$(find_user_home "$user")"
    local abshomedir="${chroot_dir}$homedir"
    if [ -n "$abshomedir" -a -d "$abshomedir" ]; then
        #create the .ssh dir as the user if not already exist
	spawn_chroot "sudo -u $user bash -c \"mkdir -p '${homedir}/.ssh/' && echo '$value' >> ${homedir}/.ssh/${filename}\""
        #echo "$value" >> "$abshomedir/.ssh/$filename"
	#spawn_chroot "chown ${user}:${user} $homedir/.ssh/${filename}"
    else
        die "add_ssh_config($filename) Unknown user $user"
    fi
}
