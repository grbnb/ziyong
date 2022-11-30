SYS_DOWN() {
ARCH=amd64
AH=amd64
qemu=qemu-x86_64-static
echo "即将下载安装centos"
sys_name=centos
DEF_CUR="https://mirrors.bfsu.edu.cn/lxc-images/images/centos/9-Stream/$ARCH/default/"
BAGNAME="rootfs.tar.xz"
    if [ -e ${BAGNAME} ]; then
        rm -rf ${BAGNAME}
	fi
	curl -o ${BAGNAME} ${DEF_CUR}
		VERSION=`cat ${BAGNAME} | grep href | tail -n 2 | cut -d '"' -f 4 | head -n 1`
		rm rootfs.tar.xz
		aria2c -o ${BAGNAME} -x 4 -s 16 ${DEF_CUR}${VERSION}${BAGNAME}
		if [ $? -ne 0 ]; then
			echo -e "下载失败"
		fi
        
		#mkdir $sys_name-$AH
#tar xvf rootfs.tar.xz -C ${BAGNAME}
#echo -e "正在解压系统包"
		#tar xf ${BAGNAME} -C $sys_name-$AH 2>/dev/null
		if [ -e $sys_name-$AH ]; then
			echo "检测到之前已安装的系统"
			sleep 0.6
			echo "准备执行删除操作"
			echo "正在删除之前的系统"
			chmod -R 755 $sys_name-$AH
		    rm -rf $sys_name-$AH
		fi
        mkdir $sys_name-$AH
echo -e "正在解压系统包"
		tar xf ${BAGNAME} -C $sys_name-$AH 2>/dev/null
		rm ${BAGNAME}
        echo -e "$sys_name-$AH系统已下载，文件夹名为$sys_name-$AH"
}

SYS_SET() {
    neofetch >>systeminfo.log
    hostinfo=$(cat systeminfo.log |grep Host |awk -F':' '{print $2}')
	echo "更新DNS"
	sleep 1
	echo "127.0.0.1 localhost" > $sys_name-$AH/etc/hosts
	rm -rf $sys_name-$AH/etc/hostname
	echo "$hostinfo" > $sys_name-$AH/etc/hostname
	echo "127.0.0.1 $hostinfo" > $sys_name-$AH/etc/hosts
	rm -rf $sys_name-$AH/etc/resolv.conf &&
	echo "nameserver 223.5.5.5
nameserver 223.6.6.6
nameserver 114.114.114.114" >$sys_name-$AH/etc/resolv.conf
echo "设置时区"
sleep 1
     rm systeminfo.log
	echo "export  TZ='Asia/Shanghai'" >> $sys_name-$AH/root/.bashrc
	echo "export  TZ='Asia/Shanghai'" >> $sys_name-$AH/etc/profile
	echo "export PULSE_SERVER=tcp:127.0.0.1:4173" >> $sys_name-$AH/etc/profile
	echo "export PULSE_SERVER=tcp:127.0.0.1:4173" >> $sys_name-$AH/root/.bashrc
	echo 检测到你没有权限读取/proc内的所有文件
	echo 将自动伪造新文件
	mkdir proot_proc
	aria2c -o proc.tar.xz -d ./proot_proc/ -x 16 https://gitee.com/suiyuehq/ziyong/raw/master/termux/proc.tar.xz
	sleep 1
	mkdir tmp
	echo 正在解压伪造文件
	
	tar xJf proot_proc/proc.tar.xz -C tmp 
	cp -r tmp/usr/local/etc/tmoe-linux/proot_proc tmp/
	sleep 1
	echo 复制文件
	cp -r tmp/proot_proc $sys_name-$AH/etc/proc
	sleep 1
	echo 删除缓存
	rm proot_proc tmp -rf
}

#模拟qemux64系统【centos】
FIN_(){
    if [ -e centos-amd64 ]
    then
    cpu="-cpu Snowridge-v4"
    fi
echo "配置qemu"
sleep 2
mkdir termux_tmp && cd termux_tmp
CURL_T=`curl https://mirrors.bfsu.edu.cn/debian/pool/main/q/qemu/ | grep '\.deb' | grep 'qemu-user-static' | grep arm64 | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2`
aria2c -x 8 -o qemu.deb https://mirrors.bfsu.edu.cn/debian/pool/main/q/qemu/$CURL_T
apt install binutils
ar -vx qemu.deb
tar xvf data.tar.xz
cd && cp termux_tmp/usr/bin/$qemu  $sys_name-$AH/ && rm -rf termux_tmp
echo "删除临时文件"
sleep 1
echo "创建登录系统脚本"
sleep 1
echo "
#!/bin/bash
pulseaudio --start
unset LD_PRELOAD
proot --bind=/vendor --bind=/system --bind=/data/data/com.termux/files/usr --bind=/storage --bind=/storage/self/primary:/sdcard --bind=/data/data/com.termux/files/home --bind=/data/data/com.termux/cache --bind=/data/dalvik-cache --bind=$sys_name-$AH/tmp:/dev/shm --bind=$sys_name-$AH/etc/proc/vmstat:/proc/vmstat --bind=$sys_name-$AH/etc/proc/version:/proc/version --bind=$sys_name-$AH/etc/proc/uptime:/proc/uptime --bind=$sys_name-$AH/etc/proc/stat:/proc/stat --bind=$sys_name-$AH/etc/proc/loadavg:/proc/loadavg --bind=/sys --bind=/proc/self/fd/2:/dev/stderr --bind=/proc/self/fd/1:/dev/stdout --bind=/proc/self/fd/0:/dev/stdin --bind=/proc/self/fd:/dev/fd --bind=/proc --bind=/dev/urandom:/dev/random --bind=/dev --root-id --cwd=/root -L --kernel-release=5.17.18-perf --sysvipc --link2symlink --kill-on-exit  -q '$sys_name-$AH/$qemu $cpu' --rootfs=$sys_name-$AH/ /usr/bin/env -i HOME=/root LANG=C.UTF-8 TERM=xterm-256color /bin/su -l root ">$sys_name-$AH.sh
echo "赋予执行权限"
sleep 1
chmod +x $sys_name-$AH.sh
chmod 700 $sys_name-$AH $sys_name-$AH/*
sleep 2
echo -e "现在可以执行 ./$sys_name-$AH.sh 运行 $sys_name-$AH系统"
exit 1
}

# 开始安装amd64位centos系统
echo 软件源获取更新
apt update
echo 检查基础依赖
apt install curl git neofetch wget aria2 -y
[ $? != 0 ] && echo "安装出错请重试！！！" && exit 1
sleep 1
SYS_DOWN
SYS_SET
FIN_