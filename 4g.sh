#!/bin/bash

do_red='\033[0;31m'
do_green='\033[0;32m'
do_yellow='\033[0;33m'
do_plain='\033[0m'

cur_dir=$(pwd)

# kiểm tra root
[[ $EUID -ne 0 ]] && echo -e "${do_red}Error:${do_plain} Ban can chay script nay voi quyen root!\n" && exit 1

# kiểm tra hệ điều hành
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${do_red}Khong phat hien duoc phien ban he dieu hanh, vui long lien he tac gia script!${do_plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${do_red}Kiem tra kien truc that bai, su dung kien truc mac dinh: ${arch}${do_plain}"
fi

echo "Kien truc: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "Phan mem nay khong ho tro he thong 32 bit (x86), vui long su dung he thong 64 bit (x86_64), neu kiem tra sai, vui long lien he tac gia"
    exit -1
fi

os_version=""

# phiên bản hệ điều hành
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${do_red}Vui long su dung CentOS 7 hoac phien ban cao hon cua he dieu hanh!${do_plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${do_red}Vui long su dung Ubuntu 16 hoac phien ban cao hon cua he dieu hanh!${do_plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${do_red}Vui long su dung Debain 8 hoac phien ban cao hon cua he dieu hanh!${do_plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

config_after_install() {
    echo -e "${do_yellow}Vi ly do an ninh, sau khi cai dat / cap nhat, ban can phai bat buoc thay doi Port va Password tai khoan${do_plain}"
    read -p "Xac nhan tiep tuc ?[y/n]": config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "Vui lòng nhập User:" config_account
        echo -e "${do_yellow}-----------> User:${config_account}${do_plain}"
        read -p "Vui lòng nhập Password:" config_password
        echo -e "${do_yellow}-----------> Password:${config_password}${do_plain}"
        read -p "Vui lòng nhập Port:" config_port
        echo -e "${do_yellow}-----------> Port:${config_port}${do_plain}"
        echo -e "${do_yellow}Xac nhan thiet lap, dang thiet lap${do_plain}"
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${do_yellow}Thiet lap mat khau tai khoan hoan tat${do_plain}"
        /usr/local/x-ui/x-ui setting -port ${config_port}
        echo -e "${do_yellow}Thiet lap cong bang dieu khien hoan tat${do_plain}"
    else
        echo -e "${do_red}Da huy, tat ca cac muc cai dat deu la mac dinh, vui long thay doi ngay lap tuc${do_plain}"
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/vaxilu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${do_red}Kiem tra phien ban x-ui that bai, co the vuot qua gioi han API Github, vui long thu lai sau hoac xac dinh phien ban x-ui de cai dat${do_plain}"
            exit 1
        fi
        echo -e "Phat hien phien ban x-ui moi nhat: ${last_version}, bat dau cai dat"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${do_red}Tai xuong x-ui that bai, hay chac chan rang may chu cua ban co the tai xuong cac tep tu Github${do_plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "Bat dau cai dat x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${do_red}Tai xuong x-ui v$1 that bai, vui long chac chan rang phien ban nay ton tai${do_plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/vaxilu/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${do_green}x-ui v${last_version}${do_plain} da duoc cai dat, bang dieu khien da duoc khoi dong,"
    echo -e ""
    echo -e "|---------------------------------CACH SU DUNG x-ui: -----------------------------------|"
    echo -e "|---------------------------------------------------------------------------------------|"
    echo -e "|         x-ui              - Hien thi menu quan ly (co nhieu tinh nang)                |"
    echo -e "|         x-ui start        - Khoi dong x-ui                                            |"
    echo -e "|         x-ui stop         - Dung x-ui                                                 |"
    echo -e "|         x-ui restart      - Khoi dong lai x-ui                                        |"
    echo -e "|         x-ui status       - Kiem tra trang thai thái x-ui                             |"
    echo -e "|         x-ui enable       - Thiet lap x-ui tu khoi dong cung he thong                 |"
    echo -e "|         x-ui disable      - Huy bo tu khoi dong x-ui cung he thong                    |"
    echo -e "|         x-ui log          - Xem log x-ui                                              |"
    echo -e "|         x-ui v2-ui        - Di chuyen du lieu tai khoan v2-ui tren may nay sang x-ui  |"
    echo -e "|         x-ui update       - Cap nhat x-ui                                             |"
    echo -e "|         x-ui install      - Cai dat x-ui                                              |"
    echo -e "|         x-ui uninstall    - Go cai dat x-ui                                           |"
    echo -e "|---------------------------------------------------------------------------------------|"
    echo -e "|------------------------------------BI VAN DAT-----------------------------------------|"
    echo -e "Truy cap: IP:[port_vua nhap ben tren]"
}

echo -e "${do_green}Bat dau cai dat${do_plain}"
install_base
install_x-ui $1
