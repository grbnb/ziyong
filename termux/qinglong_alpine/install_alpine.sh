#!/data/data/com.termux/files/usr/bin/bash
#set -x
arch="";
#linux="archlinux";
#linux_ver="";
qemu_command="";
if [ ! -d ~/storage  ]; then
	termux-setup-storage
fi
if [ -x "$(command -v apt)" ]; then
	if [ ! -x "$(command -v proot)" ] || [ ! -x "$(command -v aria2c)" ] || [ ! -x "$(command -v tar)" ]; then
        pkg install -y tar proot aria2
        [ $? != 0 ] && echo "安装出错请重试！！！" && exit 1
	fi
fi
case `dpkg --print-architecture` in
aarch64)
	arch="arm64" ;;
arm)
	arch="armhf" ;;
amd64)
	arch="amd64" ;;
x86_64)
	arch="amd64" ;;	
*)
	echo "系统架构不支持"; exit 1 ;;
esac

newarch=$arch
echo $newarch

linux="alpine";
	echo $linux
	echo "请选择$linux版本:"
	echo "edge        输入：1"
	echo "3.16        输入：2"
	echo "3.15        输入：3"
	echo "3.14        输入：4"
	echo "3.13        输入：5"
	echo "其它版本请输入对应名称"
	read -p "请输入:" banben
	case $banben in
	"1")
		linux_ver="edge";
		echo $linux_ver
	    ;;
	"2")
		linux_ver="3.16";
		echo $linux_ver
	    ;;
	"3")
		linux_ver="3.15";
		echo $linux_ver
	    ;;
	"4")
		linux_ver="3.14";
		echo $linux_ver
	    ;;
	"5")
		linux_ver="3.13";
		echo $linux_ver
	    ;;
	*)
		linux_ver=$banben
		echo $linux_ver
		esac;

if ! [ -f $linux-$newarch-$linux_ver.tar.xz ]; then
	if ! [ -f images.json ]; then
		aria2c "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/streams/v1/images.json"
	fi
#解析json
	rootfs_url=`cat images.json  |	awk -F '[,"}]' '{for(i=1;i<=NF;i++){ print $i}}' | grep "images/$linux/" | grep "${linux_ver}" | grep "/${arch}/default/" | grep "rootfs.tar.xz" | awk 'END {print}' `
	echo  "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/${rootfs_url}"
	if [ $rootfs_url ]; then
		echo "正在下载"
		aria2c -x 4 -s 16 -o $linux-$newarch-$linux_ver.tar.xz  "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/${rootfs_url}"
	else 
		echo "$linux-$newarch ${linux_ver} 版本无法找到，请重新确认输入"
		rm -rf images.json 2>/dev/null
		exit 1
	fi
fi
if [ -d .$linux  ]; then
	echo "安装中断，检测到.$linux文件夹已存在"
	read -p "是否需要重装？[y/n] (输入y回车确认，回车默认退出)：" delete
	case $delete in
	y)
		chmod -R 755 .$linux
		rm -rf .$linux
		;;
	*)
		echo "由于.$linux文件夹已存在，结束安装"
		exit 1
		esac;
fi

echo "下载完成"
echo "开始安装"
cd $HOME
mkdir -p ".$linux"
cd ".$linux"
echo "正在解压rootfs，请稍候"
proot --link2symlink tar -xJf $HOME/$linux-$newarch-$linux_ver.tar.xz --exclude='dev' --exclude='etc/rc.d' --exclude='usr/lib64/pm-utils'

set_sys(){
## Creating /etc/resolv.conf file
local resolv="$HOME/.$linux/etc/resolv.conf"
    [ -f "$resolv" ] && cp -n ${resolv}{,.bak}
    cat <<- EOF > "$resolv"
	nameserver 8.8.8.8
	nameserver 8.8.4.4
	EOF

## Creating /etc/hosts file
local hosts="$HOME/.$linux/etc/hosts"
    [ -f "$hosts" ] && cp -n ${hosts}{,.bak}
    cat <<- EOF > "$hosts"
	# IPv4.
	127.0.0.1   localhost.localdomain localhost

	# IPv6.
	::1         localhost.localdomain localhost ipv6-localhost ipv6-loopback
	fe00::0     ipv6-localnet
	ff00::0     ipv6-mcastprefix
	ff02::1     ipv6-allnodes
	ff02::2     ipv6-allrouters
	ff02::3     ipv6-allhosts
	EOF

## Creating /etc/bash.bashrc file
local bashrc="$HOME/.$linux/etc/bash.bashrc"
cat <<- EOF > "$bashrc"
	# text editor
	export VISUAL=nano
	export EDITOR="\$VISUAL"

	# enable shell options
	shopt -s checkwinsize cdspell extglob

	# some aliases
	alias e='exit'
	alias c='clear'
	alias r='reset'
	alias la='ls -A' # show hidden
	alias l.='ls -d .*' # show only hidden
	alias ll='ls -CF' # show hidden prefix
	alias l='ls -lathF' # sort by newest
	alias L='ls -latrhF' # sort by oldest
	alias lc='ls -lcr' # sort by change time
	alias lo='ls -laSFh' # sort by size largest
	alias lt='ls -ltr' # sort by date

	# alias definitions
	[ -f ~/.bash_aliases ] && . ~/.bash_aliases

	# bash-completion
	[[ \$PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion
	EOF

## Return getprop empty or not
is_getprop() { local prop=`command -v getprop`||:; [[ "$prop" && ! -z "$prop" ]] && return 0 || return 1; }
## Get timezone from android
timezone() { local TZ="" tz=`getprop persist.sys.timezone`; is_getprop && [[ "$tz" && ! -z "$tz" ]] && TZ="$tz"; echo "$TZ"; }
timezone=`timezone`

## Creating /etc/profile file
local profile="$HOME/.$linux/etc/profile"
    [ -f "$profile" ] && cp -n ${profile}{,.bak}
local TZ=""; [ ! -z "$timezone" ] && TZ="export TZ=$timezone"

    cat <<- EOF > "$profile"
	export LANG=C.UTF-8
	$TZ
	export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
	export TERM=${TERM-xterm-256color}
	export TMPDIR=/tmp
	export PAGER=less
	export PS1='[\u@\h \w]\$(if [ \`id -u\` -eq 0 ]; then echo "#"; else echo "\$"; fi) '
	umask 022

	# Load profiles from /etc/profile.d
	if [ -d /etc/profile.d ]; then
	  for profile in /etc/profile.d/*.sh; do
	    if [ -r \$profile ]; then
	      . \$profile
	    fi
	  done
	  unset profile
	fi

	# Source ~/.bashrc or /etc/bash.bashrc
	if [ -n "\$BASH_VERSION" ]; then
	  if [ -f "\$HOME/.bashrc" ]; then
	    . "\$HOME/.bashrc"
	  elif [ -f /etc/bash.bashrc ]; then
	    . /etc/bash.bashrc
	  fi
	fi

	# set PATH so it includes user's private bin if it exists
	if [ -d "\$HOME/bin" ]; then
	    PATH="\$HOME/bin:\$PATH"
	fi
	if [ -d "\$HOME/.local/bin" ]; then
	    PATH="\$HOME/.local/bin:\$PATH"
	fi
	EOF
local fstab="$HOME/.$linux/etc/fstab"
    if [ -f "$fstab" ]; then
        cp -n ${fstab}{,.bak}
        echo "" > $fstab
    fi
}

proc_plan(){
	echo "建立proc文件"
	chmod 700 proc
	echo "cpu  1050008 127632 898432 43828767 37203 63 99244 0 0 0
cpu0 212383 20476 204704 8389202 7253 42 12597 0 0 0
cpu1 224452 24947 215570 8372502 8135 4 42768 0 0 0
cpu2 222993 17440 200925 8424262 8069 9 17732 0 0 0
cpu3 186835 8775 195974 8486330 5746 3 8360 0 0 0
cpu4 107075 32886 48854 8688521 3995 4 5758 0 0 0
cpu5 90733 20914 27798 1429573 2984 1 11419 0 0 0
intr 53261351 0 686 1 0 0 1 12 31 1 20 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7818 0 0 0 0 0 0 0 0 255 33 1912 33 0 0 0 0 0 0 3449534 2315885 2150546 2399277 696281 339300 22642 19371 0 0 0 0 0 0 0 0 0 0 0 2199 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2445 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 162240 14293 2858 0 151709 151592 0 0 0 284534 0 0 0 0 0 0 0 0 0 0 0 0 0 0 185353 0 0 938962 0 0 0 0 736100 0 0 1 1209 27960 0 0 0 0 0 0 0 0 303 115968 452839 2 0 0 0 0 0 0 0 0 0 0 0 0 0 160361 8835 86413 1292 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3592 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6091 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 35667 0 0 156823 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 138 2667417 0 41 4008 952 16633 533480 0 0 0 0 0 0 262506 0 0 0 0 0 0 126 0 0 1558488 0 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 2 8 0 0 6 0 0 0 10 3 4 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 20 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 12 1 1 83806 0 1 1 0 1 0 1 1 319686 2 8 0 0 0 0 0 0 0 0 0 244534 0 1 10 9 0 10 112 107 40 221 0 0 0 144
ctxt 90182396
btime 1595203295
processes 270853
procs_running 2
procs_blocked 0
softirq 25293348 2883 7658936 40779 539155 497187 2864 1908702 7229194 279723 7133925" >proc/.stat
echo "Linux version 5.4.0-faked (termu) (gcc version 6.9.x (Faked /proc/version ) ) #1 SMP PREEMPT Sun May 11 11:11:11 UTC 2022">proc/.version
}

#方案一启动脚本
proot_start1(){
echo "写入方案一启动脚本"
cat > ${PREFIX}/bin/termux-$linux <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --kernel-release=5.4.0-fake-kernel"
command+=" --link2symlink"
command+=" -0"
command+=" -r \$HOME/.$linux"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b \$HOME/.$linux/root:/dev/shm"
command+=" -b \$HOME/.$linux/proc/.stat:/proc/stat"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to / 
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/sh --login"
com="\$@"
if [ -z "\$1" ]; then
    exec \$command
else
    \$command -c "\$com"
fi
EOM
}

#写入方案二
proot_start2(){
echo "写入方案二启动脚本"
local TZ=""; [ ! -z "$timezone" ] && TZ="command+=\" TZ=$timezone\""
cat <<- EOF > "${PREFIX}/bin/termux-$linux"
#!/data/data/com.termux/files/usr/bin/bash
unset LD_PRELOAD
command="proot"
command+=" --kernel-release=5.4.0-fake-kernel"
command+=" --kill-on-exit"
command+=" --link2symlink"
command+=" --rootfs=\$HOME/.$linux"
command+=" --root-id"
command+=" --cwd=/root"
command+=" --bind=/dev"
command+=" --bind=/dev/urandom:/dev/random"
command+=" --bind=/proc"
command+=" --bind=/sys"
command+=" --bind=\$HOME/.$linux/root:/dev/shm"
command+=" --bind=\$HOME/.$linux/proc/.stat:/proc/stat"
command+=" --bind=\$HOME/.$linux/proc/.version:/proc/version"
[ ! -d "\$HOME/.$linux/tmp" ] && mkdir "\$HOME/.$linux/tmp"
command+=" --bind=\$HOME/.$linux/tmp:/dev/shm"
# Bind /data/data/com.termux to /
command+=" --bind=/data/data/com.termux"
# Bind /storage to /
command+=" --bind=/storage"
# Bind /sdcard to /
command+=" --bind=/storage/self/primary:/sdcard"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" LANG=C.UTF-8"
$TZ
command+=" PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
command+=" TERM=\${TERM-xterm-256color}"
command+=" TMPDIR=/tmp"
command+=" SHELL=/bin/sh"
command+=" /bin/sh --login"
com="\$@"; [ -z "\$1" ] && exec \$command || \$command -c "\$com"
EOF
}

set_sys
proc_plan
proot_start2
cd $HOME
echo "授予 termux-$linux 执行权限"
chmod +x "${PREFIX}/bin/termux-$linux"
chmod 700 $HOME/.$linux $HOME/.$linux/*

echo "切换为科大源"
sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' $HOME/.$linux/etc/apk/repositories

#安装必要工具
echo "安装必备软件包"
pkg="bash bash-completion sudo tzdata curl wget git nano vim neofetch"
$PREFIX/bin/termux-$linux "apk -U upgrade --no-progress --no-cache"
$PREFIX/bin/termux-$linux "apk add --update --no-progress --no-cache $pkg"
#替换sh为bash
sed -i "s/ash/bash/g" $HOME/.$linux/etc/passwd
sed -i "s/bin\/sh/bin\/bash/g" ${PREFIX}/bin/termux-$linux

echo "$linux系统安装完成！"
read -p "是否保留镜像？[y/n] (输入y回车确认，回车默认删除)：" delete
    case $delete in
	y)
		echo "镜像文件已保留，如不需要请手动删除！"
		;;
	*)
		rm -rf $linux-$newarch-$linux_ver.tar.xz
		echo "镜像文件已删除！"
		esac;

read -p "是否写入自启动？[y/n] (输入y回车确认，回车默认跳过)：" edit
    case $edit in
    y)
        echo "正在写入alpine系统自启动程序"
        cat > $HOME/.bashrc <<- EOM
		if [ -r /data/data/com.termux/files/usr/bin/termux-alpine ];then
		    termux-alpine
		fi
		EOM
		;;
	*)
		echo "已跳过alpine系统自启动"
		esac;
#删除json
rm -rf images.json 2>/dev/null
echo -e "现在可以执行 \e[32mtermux-${linux}\e[0m 运行 $linux ${linux_ver} 了"