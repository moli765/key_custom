#!/usr/bin/env bash
#=============================================================
# https://github.com/P3TERX/SSH_Key_Installer
# Description: Install SSH keys via GitHub, URL or local files
# Version: 2.7
# Author: P3TERX
# Blog: https://p3terx.com
# 
# modify by moli765
#=============================================================

VERSION=2.7
RED_FONT_PREFIX="\033[31m"
LIGHT_GREEN_FONT_PREFIX="\033[1;32m"
FONT_COLOR_SUFFIX="\033[0m"
INFO="[${LIGHT_GREEN_FONT_PREFIX}INFO${FONT_COLOR_SUFFIX}]"
ERROR="[${RED_FONT_PREFIX}ERROR${FONT_COLOR_SUFFIX}]"
[ $EUID != 0 ] && SUDO=sudo

USAGE() {
    echo "
SSH Key Installer $VERSION

Usage:
 ## bash <(curl -fsSL git.io/key.sh) [options...] <arg>

Options:
  -o Overwrite mode, this option is valid at the top
  -g Get the public key from GitHub, the arguments is the GitHub ID
  -u Get the public key from the URL, the arguments is the URL
  -f Get the public key from the local file, the arguments is the local file path
  -p Change SSH port, the arguments is port number
  -d Disable password login
  -c Costume settings:
     set pub key and overwrite
     PermitRootLogin=yes 
     PasswordAuthentication no
     UserDNS=no 
     GSSAPIAuthentication=no
     MaxAuthTries=3 
     ClientAliveInterval=60  
     ClientAliveCountMax=720"
}

if [ $# -eq 0 ]; then
    USAGE
    exit 1
fi

set_pub_key(){
    PUB_KEY="ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBADSdaT+Mrh0+hLc8YaNTaoZ5fclYfZqrWg3kZ+XEgIrzQ1ux06zxlyCByI0ZZ8jUK+yXtaoCwJp58EwIp6vBxe0OwH/Jyd7wZT8dHscQClTpLtQ9H5gWU2jXM/1UrQ/q/2re4vh+L9WhY80M+AoEuw0Qfx4qWOD2/yVupfIoTYSG6O5Cg=="
    #手动设置公钥,改成自己的
}
#apt install curl -y
##要用到 curl 以防万一装一下

get_github_key() {
    if [ "${KEY_ID}" == '' ]; then
        read -e -p "Please enter the GitHub account:" KEY_ID
        [ "${KEY_ID}" == '' ] && echo -e "${ERROR} Invalid input." && exit 1
    fi
    echo -e "${INFO} The GitHub account is: ${KEY_ID}"
    echo -e "${INFO} Get key from GitHub..."
    PUB_KEY=$(curl -fsSL https://github.com/${KEY_ID}.keys)
    if [ "${PUB_KEY}" == 'Not Found' ]; then
        echo -e "${ERROR} GitHub account not found."
        exit 1
    elif [ "${PUB_KEY}" == '' ]; then
        echo -e "${ERROR} This account ssh key does not exist."
        exit 1
    fi
}

get_url_key() {
    if [ "${KEY_URL}" == '' ]; then
        read -e -p "Please enter the URL:" KEY_URL
        [ "${KEY_URL}" == '' ] && echo -e "${ERROR} Invalid input." && exit 1
    fi
    echo -e "${INFO} Get key from URL..."
    PUB_KEY=$(curl -fsSL ${KEY_URL})
}

get_loacl_key() {
    if [ "${KEY_PATH}" == '' ]; then
        read -e -p "Please enter the path:" KEY_PATH
        [ "${KEY_PATH}" == '' ] && echo -e "${ERROR} Invalid input." && exit 1
    fi
    echo -e "${INFO} Get key from $(${KEY_PATH})..."
    PUB_KEY=$(cat ${KEY_PATH})
}

install_key() {
    [ "${PUB_KEY}" == '' ] && echo "${ERROR} ssh key does not exist." && exit 1
    if [ ! -f "${HOME}/.ssh/authorized_keys" ]; then
        echo -e "${INFO} '${HOME}/.ssh/authorized_keys' is missing..."
        echo -e "${INFO} Creating ${HOME}/.ssh/authorized_keys..."
        mkdir -p ${HOME}/.ssh/
        touch ${HOME}/.ssh/authorized_keys
        if [ ! -f "${HOME}/.ssh/authorized_keys" ]; then
            echo -e "${ERROR} Failed to create SSH key file."
        else
            echo -e "${INFO} Key file created, proceeding..."
        fi
    fi
    if [ "${OVERWRITE}" == 1 ]; then
        echo -e "${INFO} Overwriting SSH key..."
        echo -e "${PUB_KEY}\n" >${HOME}/.ssh/authorized_keys
    else
        echo -e "${INFO} Adding SSH key..."
        echo -e "\n${PUB_KEY}\n" >>${HOME}/.ssh/authorized_keys
    fi
    chmod 700 ${HOME}/.ssh/
    chmod 600 ${HOME}/.ssh/authorized_keys
    [[ $(grep "${PUB_KEY}" "${HOME}/.ssh/authorized_keys") ]] &&
        echo -e "${INFO} SSH Key installed successfully!" || {
        echo -e "${ERROR} SSH key installation failed!"
        exit 1
    }
}

change_port() {
    echo -e "${INFO} Changing SSH port to ${SSH_PORT} ..."
    if [ $(uname -o) == Android ]; then
        [[ -z $(grep "Port " "$PREFIX/etc/ssh/sshd_config") ]] &&
            echo -e "${INFO} Port ${SSH_PORT}" >>$PREFIX/etc/ssh/sshd_config ||
            sed -i "s@.*\(Port \).*@\1${SSH_PORT}@" $PREFIX/etc/ssh/sshd_config
        [[ $(grep "Port " "$PREFIX/etc/ssh/sshd_config") ]] && {
            echo -e "${INFO} SSH port changed successfully!"
            RESTART_SSHD=2
        } || {
            RESTART_SSHD=0
            echo -e "${ERROR} SSH port change failed!"
            exit 1
        }
    else
        $SUDO sed -i "s@.*\(Port \).*@\1${SSH_PORT}@" /etc/ssh/sshd_config && {
            echo -e "${INFO} SSH port changed successfully!"
            RESTART_SSHD=1
        } || {
            RESTART_SSHD=0
            echo -e "${ERROR} SSH port change failed!"
            exit 1
        }
    fi
}

disable_password() {
    if [ $(uname -o) == Android ]; then
        sed -i "s@.*\(PasswordAuthentication \).*@\1no@" $PREFIX/etc/ssh/sshd_config && {
            RESTART_SSHD=2
            echo -e "${INFO} Disabled password login in SSH."
        } || {
            RESTART_SSHD=0
            echo -e "${ERROR} Disable password login failed!"
            exit 1
        }
    else
        $SUDO sed -i "s@.*\(PasswordAuthentication \).*@\1no@" /etc/ssh/sshd_config && {
            RESTART_SSHD=1
            echo -e "${INFO} Disabled password login in SSH."
        } || {
            RESTART_SSHD=0
            echo -e "${ERROR} Disable password login failed!"
            exit 1
        }
    fi
}

custome_set() {
    echo -e "${INFO} Changing PasswordAuthentication PermitRootLogin UseDNS MaxAuthTries ClientAliveInterval ClientAliveCountMax ..."
    if [ $(uname -o) == Android ]; then
         if [[ ${PermitRootLogin} == "yes" ]];then
            sed -i "s@.*#\(PermitRootLogin \).*@\1yes@"  $PREFIX/etc/ssh/sshd_config
        fi
            echo -e "${INFO} Changing" >>$PREFIX/etc/ssh/sshd_config 
            sed -i "s@.*\(MaxAuthTries \).*@\1${MaxAuthTries}@" $PREFIX/etc/ssh/sshd_config
            sed -i "s@.*\(ClientAliveInterval \).*@\1${ClientAliveInterval}@" $PREFIX/etc/ssh/sshd_config
            sed -i "s@.*\(ClientAliveCountMax \).*@\1${ClientAliveCountMax}@" $PREFIX/etc/ssh/sshd_config
        [[ $(grep "PermitRootLogin " "$PREFIX/etc/ssh/sshd_config") ]] && 
        {
            echo -e "${INFO} Changed successfully!"
            RESTART_SSHD=2
        } || {
            RESTART_SSHD=0
            echo -e "${ERROR} Change failed!"
            exit 1
        }
        ##没测试安卓，应该用不了
    else
        if [[ ${PermitRootLogin} == "yes" ]];then
        $SUDO sed -i "s@.*#\(PermitRootLogin \).*@\1yes@" /etc/ssh/sshd_config
        fi
        if [[ ${GSSAPIAuthentication} == "no" ]];then
        $SUDO sed -i "s@.*#\(GSSAPIAuthentication \).*@\1no@" /etc/ssh/sshd_config
        fi        
        { $SUDO sed -i "s@.*\(MaxAuthTries \).*@\1${MaxAuthTries}@" /etc/ssh/sshd_config 
          $SUDO sed -i "s@.*\(ClientAliveInterval \).*@\1${ClientAliveInterval}@" /etc/ssh/sshd_config
          $SUDO sed -i "s@.*\(ClientAliveCountMax \).*@\1${ClientAliveCountMax}@" /etc/ssh/sshd_config
          #$SUDO sed -i "s@.*\(PasswordAuthentication \).*@\1no@" /etc/ssh/sshd_config
          $SUDO sed -i "s@.*#\(UseDNS \).*@\1no@" /etc/ssh/sshd_config
        } && {
            echo -e "${INFO} Changed successfully!"
            RESTART_SSHD=1
        } || {
            RESTART_SSHD=0
            echo -e "${ERROR} Change failed!"
            exit 1
        }
    fi
}

while getopts "og:u:f:p:d:c" OPT; do
    case $OPT in
    o)
        OVERWRITE=1
        ;;
    g)
        KEY_ID=$OPTARG
        get_github_key
        install_key
        ;;
    u)
        KEY_URL=$OPTARG
        get_url_key
        install_key
        ;;
    f)
        KEY_PATH=$OPTARG
        get_loacl_key
        install_key
        ;;
    p)
        SSH_PORT=$OPTARG
        change_port
        ;;
    d)
        disable_password
        ;;
    c)  
        OVERWRITE=1
        set_pub_key
        install_key
        #使用手动设置的公钥并强制覆盖
        disable_password
        #关闭密码登录
        ClientAliveInterval=60
        ClientAliveCountMax=720
        #连接保活，60s一次，可保持连接12h
        MaxAuthTries=3
        #最大尝试次数为3,默认20
        PermitRootLogin=yes
        #允许root登录,默认no
        GSSAPIAuthentication=no
        #设置no可加速SSH登录，部分系统默认为no
        custome_set
        #此处自定义修改参数
        ;;
    ?)
        USAGE
        exit 1
        ;;
    :)
        USAGE
        exit 1
        ;;
    *)
        USAGE
        exit 1
        ;;
    esac
done

if [ "$RESTART_SSHD" = 1 ]; then
    echo -e "${INFO} Restarting sshd..."
    $SUDO systemctl restart sshd && echo -e "${INFO} Done."
elif [ "$RESTART_SSHD" = 2 ]; then
    echo -e "${INFO} Restart sshd or Termux App to take effect."
fi
