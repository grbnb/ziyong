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

echo "********************************"
echo "   请选择安装的系统架构   "
echo "   aarch64 请输入：1"
echo "   armhf   请输入：2"
echo "   x86     请输入：3"
echo "   amd64   请输入：4"
echo "   其它 输入平台名称 （如："
echo "   回车默认使用本机架构)"
echo "   退出    请输入：exit"
echo "********************************"
read -p "请输入:" charch
case $charch in
"1")
	newarch="arm64"
	echo $newarch
	qemu_user="qemu-aarch64"
	;;

"2")
	newarch="armhf"
	echo $newarch
	qemu_user="qemu-arm"
	;;
"3")
	newarch="i386"
	echo $newarch
	qemu_user="qemu-i386"
	;;
"4")
	newarch="amd64"
	echo $newarch
	qemu_user="qemu-x86_64"
	;;
"")
    newarch=$arch
    echo $newarch
    ;;
"exit")
	exit 1
	;;
*)
	newarch=$charch
	echo $newarch
	qemu_user="qemu-$newarch"
	esac;

echo "********************************"
echo "   请选择安装的Linux 发行版  "
echo "   debian 请输入：1"
echo "   ubuntu 请输入：2"
echo "   kali   请输入：3"
echo "   fedora 请输入：4"
echo "   centos 请输入: 5"
echo "   其它 输入发行版名称 （如："
echo "   archlinux、alpine、oracle...)"
echo "   退出   请输入：exit"
echo "********************************"
read -p "请输入:" name
#限制可安装的系统
#linux_os=(1 debian 2 ubuntu 3 kali 4 fedora 5 centos archlinux alpine rockylinux voidlinux almalinux oracle opensuse devuan gentoo funtoo)
#if echo "${linux_os[@]}" | grep -w "$name" &>/dev/null; then
case $name in
"1")
	linux="debian";
	echo "请选择$linux版本:"
	echo "bullseye  输入：1"
	echo "buster    输入：2"
	echo "sid       输入：3"
	echo "其它版本请输入对应名称"
	read -p "请输入:" banben
	case $banben in
	"1")
		linux_ver="bullseye";
		echo $linux_ver
	    ;;
	"2")
		linux_ver="buster";
		echo $linux_ver
	    ;;
	"3")
		linux_ver="sid";
		echo $linux_ver
	    ;;
	*)
		linux_ver=$banben
		echo $linux_ver
	esac;
    ;;
"2")
	linux="ubuntu";
	echo $linux
	echo "请选择$linux版本:"
	echo "bionic    输入：1"
	echo "focal     输入：2"
	echo "xenial    输入：3"
	echo "其它版本请输入对应名称"
	read -p "请输入:" banben
	case $banben in
	"1")
		linux_ver="bionic";
		echo $linux_ver
	    ;;
	"2")
		linux_ver="focal";
		echo $linux_ver
		;;	
	"3")
		linux_ver="xenial";
		echo $linux_ver
	    ;;
	*)
		linux_ver=$banben
		echo $linux_ver
	esac;
    ;;
"3")
	linux="kali";
	echo $linux
	linux_ver="current";
    ;;
"4")
	linux="fedora";
	echo $linux
	echo "请选择$linux版本:"
	echo "30        输入：1"
	echo "31        输入：2"
	echo "32        输入：3"
	echo "其它版本请输入对应名称"
	read -p "请输入:" banben
	case $banben in
	"1")
		linux_ver="30";
		echo $linux_ver
	    ;;
	"2")
		linux_ver="31";
		echo $linux_ver
	    ;;
	"3")
		linux_ver="32";
		echo $linux_ver
	    ;;
	*)
		linux_ver=$banben
		echo $linux_ver
		esac;
    ;;
"5")
linux="centos";
	echo $linux
	echo "请选择$linux版本:"
	echo "8-Stream  输入：1"
	echo "9-Stream  输入：2"
	echo "其它版本请输入对应名称"
	read -p "请输入:" banben
	case $banben in
	"1")
		linux_ver="8-Stream";
		echo $linux_ver
	    ;;
	"2")
		linux_ver="9-Stream";
		echo $linux_ver
	    ;;
	*)
		linux_ver=$banben
		echo $linux_ver
		esac;
    ;;
"exit")
    exit 1
    ;;
*)
	linux=$name;
	echo $linux
	read -p "请输入系统版本(回车自动选择):" banben
	linux_ver=$banben
esac
: "else
   echo "$name为暂不支持的Linux系统!"
   exit 1
fi
"
if [ $newarch != $arch ]; then
#排除部分不支持模拟的系统
unlinux_os=(centos rockylinux almalinux oracle)
    if ! echo "${unlinux_os[@]}" | grep -w "$linux" &>/dev/null; then
	    echo $newarch"已使用qemu-user 正在配置"
	    arch="$newarch"
	    qemu_command=" -q $qemu_user  -b /vendor -b /system -b /apex -b /data/dalvik-cache -b $PREFIX"
        qemu_command+=" -L --sysvipc"
        qemu_command+=" --kill-on-exit"
        qemu_command+=" --kernel-release=5.4.0-fake-kernel"
        qemu_command+=" -b $HOME/.$linux/sys/fs/selinux/:/sys/fs/selinux"
        qemu_command+=" -b $HOME/.$linux/tmp/:/dev/shm/"
        qemu_command+=" -b /dev/urandom:/dev/random"
        qemu_command+=" -b $HOME/.$linux/proc/.stat:/proc/stat"
        qemu_command+=" -b $HOME/.$linux/proc/.loadavg:/proc/loadavg"
        qemu_command+=" -b $HOME/.$linux/proc/.uptime:/proc/uptime"
        qemu_command+=" -b $HOME/.$linux/proc/.version:/proc/version"
        qemu_command+=" -b $HOME/.$linux/proc/.vmstat:/proc/vmstat"
	    if [ ! -x "$(command -v $qemu_user)" ]; then
            apt update && apt upgrade -y &&
            apt install -y qemu-user-* 
	    fi
	    if [ ! -x "$(command -v $qemu_user)" ]; then
		    echo "找不到适配的$qemu_user"
		    exit 1;
	    fi
	    echo $newarch"qemu-user 配置完成"
    else
    echo "$linux系统暂不支持模拟其它架构！"
    exit 1;
    fi
fi

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
	;;
	esac
fi

echo "下载完成"

echo "开始安装"
cur=$HOME
cd $cur
mkdir -p ".$linux"
cd ".$linux"
echo "正在解压rootfs，请稍候"
proot --link2symlink tar -xJf ${cur}/$linux-$newarch-$linux_ver.tar.xz --exclude='dev' --exclude='etc/rc.d' --exclude='usr/lib64/pm-utils'
echo "更新DNS"
echo -e "127.0.0.1        localhost
::1        ip6-localhost ip6-loopback" > etc/hosts
rm -rf etc/resolv.conf &&
echo "nameserver 114.114.114.114" > etc/resolv.conf
echo "nameserver 8.8.4.4" >> etc/resolv.conf
echo "export TZ='Asia/Shanghai'" >> etc/profile

if [ -n "$qemu_command" ]; then
echo "使用配置方案二"
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
	echo "0.54 0.41 0.30 1/931 370386">proc/.loadavg
	echo "284684.56 513853.46">proc/.uptime
	echo "Linux version 5.4.0-faked (termu) (gcc version 6.9.x (Faked /proc/version ) ) #1 SMP PREEMPT Sun May 11 11:11:11 UTC 2022">proc/.version
	echo "nr_free_pages 146031
nr_zone_inactive_anon 196744
nr_zone_active_anon 301503
nr_zone_inactive_file 2457066
nr_zone_active_file 729742
nr_zone_unevictable 164
nr_zone_write_pending 8
nr_mlock 34
nr_page_table_pages 6925
nr_kernel_stack 13216
nr_bounce 0
nr_zspages 0
nr_free_cma 0
numa_hit 672391199
numa_miss 0
numa_foreign 0
numa_interleave 62816
numa_local 672391199
numa_other 0
nr_inactive_anon 196744
nr_active_anon 301503
nr_inactive_file 2457066
nr_active_file 729742
nr_unevictable 164
nr_slab_reclaimable 132891
nr_slab_unreclaimable 38582
nr_isolated_anon 0
nr_isolated_file 0
workingset_nodes 25623
workingset_refault 46689297
workingset_activate 4043141
workingset_restore 413848
workingset_nodereclaim 35082
nr_anon_pages 599893
nr_mapped 136339
nr_file_pages 3086333
nr_dirty 8
nr_writeback 0
nr_writeback_temp 0
nr_shmem 13743
nr_shmem_hugepages 0
nr_shmem_pmdmapped 0
nr_file_hugepages 0
nr_file_pmdmapped 0
nr_anon_transparent_hugepages 57
nr_unstable 0
nr_vmscan_write 57250
nr_vmscan_immediate_reclaim 2673
nr_dirtied 79585373
nr_written 72662315
nr_kernel_misc_reclaimable 0
nr_dirty_threshold 657954
nr_dirty_background_threshold 328575
pgpgin 372097889
pgpgout 296950969
pswpin 14675
pswpout 59294
pgalloc_dma 4
pgalloc_dma32 101793210
pgalloc_normal 614157703
pgalloc_movable 0
allocstall_dma 0
allocstall_dma32 0
allocstall_normal 184
allocstall_movable 239
pgskip_dma 0
pgskip_dma32 0
pgskip_normal 0
pgskip_movable 0
pgfree 716918803
pgactivate 68768195
pgdeactivate 7278211
pglazyfree 1398441
pgfault 491284262
pgmajfault 86567
pglazyfreed 1000581
pgrefill 7551461
pgsteal_kswapd 130545619
pgsteal_direct 205772
pgscan_kswapd 131219641
pgscan_direct 207173
pgscan_direct_throttle 0
zone_reclaim_failed 0
pginodesteal 8055
slabs_scanned 9977903
kswapd_inodesteal 13337022
kswapd_low_wmark_hit_quickly 33796
kswapd_high_wmark_hit_quickly 3948
pageoutrun 43580
pgrotated 200299
drop_pagecache 0
drop_slab 0
oom_kill 0
numa_pte_updates 0
numa_huge_pte_updates 0
numa_hint_faults 0
numa_hint_faults_local 0
numa_pages_migrated 0
pgmigrate_success 768502
pgmigrate_fail 1670
compact_migrate_scanned 1288646
compact_free_scanned 44388226
compact_isolated 1575815
compact_stall 863
compact_fail 392
compact_success 471
compact_daemon_wake 975
compact_daemon_migrate_scanned 613634
compact_daemon_free_scanned 26884944
htlb_buddy_alloc_success 0
htlb_buddy_alloc_fail 0
unevictable_pgs_culled 258910
unevictable_pgs_scanned 3690
unevictable_pgs_rescued 200643
unevictable_pgs_mlocked 199204
unevictable_pgs_munlocked 199164
unevictable_pgs_cleared 6
unevictable_pgs_stranded 6
thp_fault_alloc 10655
thp_fault_fallback 130
thp_collapse_alloc 655
thp_collapse_alloc_failed 50
thp_file_alloc 0
thp_file_mapped 0
thp_split_page 612
thp_split_page_failed 0
thp_deferred_split_page 11238
thp_split_pmd 632
thp_split_pud 0
thp_zero_page_alloc 2
thp_zero_page_alloc_failed 0
thp_swpout 4
thp_swpout_fallback 0
balloon_inflate 0
balloon_deflate 0
balloon_migrate 0
swap_ra 9661
swap_ra_hit 7872">proc/.vmstat
    chmod -R 755 sys
	mkdir -p sys/fs/selinux
fi

cd "$cur"

if [ $linux == "alpine" ]; then 
	bash_tmp="sh";
else
    bash_tmp="su"
fi

if [ $linux == "ubuntu" ]; then
	touch ".$linux/root/.hushlogin"
fi

if [ ! -n "$qemu_command" ]; then
echo "使用配置方案一"
	echo "建立proc文件"
	chmod 700 $HOME/.$linux/proc
	cat <<- EOF > "$HOME/.$linux/proc/.loadavg"
0.35 0.22 0.15 1/575 7767
EOF
	cat <<- EOF > "$HOME/.$linux/proc/.stat"
cpu  265542 13183 24203 611072 152293 68 191340 255 0 0 0
cpu0 265542 13183 24203 611072 152293 68 191340 255 0 0 0
intr 815181 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 906205
btime 163178502
processes 25384
procs_running 1
procs_blocked 0
softirq 1857962 55 2536781 34 1723322 8 2457784 5 1914410
EOF
	cat <<- EOF > "$HOME/.$linux/proc/.uptime"
11965.80 11411.22
EOF
	cat <<- EOF > "$HOME/.$linux/proc/.vmstat"
nr_free_pages 705489
nr_alloc_batch 0
nr_inactive_anon 1809
nr_active_anon 61283
nr_inactive_file 69543
nr_active_file 58416
nr_unevictable 64
nr_mlock 64
nr_anon_pages 60894
nr_mapped 99503
nr_file_pages 130218
nr_dirty 9
nr_writeback 0
nr_slab_reclaimable 2283
nr_slab_unreclaimable 3714
nr_page_table_pages 1911
nr_kernel_stack 687
nr_unstable 0
nr_bounce 0
nr_vmscan_write 0
nr_vmscan_immediate_reclaim 0
nr_writeback_temp 0
nr_isolated_anon 0
nr_isolated_file 0
nr_shmem 2262
nr_dirtied 3675
nr_written 3665
nr_pages_scanned 0
workingset_refault 1183
workingset_activate 1183
workingset_nodereclaim 0
nr_anon_transparent_hugepages 0
nr_free_cma 0
nr_dirty_threshold 21574
nr_dirty_background_threshold 5393
pgpgin 541367
pgpgout 23248
pswpin 1927
pswpout 2562
pgalloc_dma 182
pgalloc_normal 76067
pgalloc_high 326333
pgalloc_movable 0
pgfree 1108260
pgactivate 53201
pgdeactivate 2592
pgfault 420060
pgmajfault 4323
pgrefill_dma 0
pgrefill_normal 2589
pgrefill_high 0
pgrefill_movable 0
pgsteal_kswapd_dma 0
pgsteal_kswapd_normal 0
pgsteal_kswapd_high 0
pgsteal_kswapd_movable 0
pgsteal_direct_dma 0
pgsteal_direct_normal 1211
pgsteal_direct_high 7987
pgsteal_direct_movable 0
pgscan_kswapd_dma 0
pgscan_kswapd_normal 0
pgscan_kswapd_high 0
pgscan_kswapd_movable 0
pgscan_direct_dma 0
pgscan_direct_normal 4172
pgscan_direct_high 25365
pgscan_direct_movable 0
pgscan_direct_throttle 0
pginodesteal 0
slabs_scanned 9728
kswapd_inodesteal 0
kswapd_low_wmark_hit_quickly 0
kswapd_high_wmark_hit_quickly 0
pageoutrun 1
allocstall 189
pgrotated 7
drop_pagecache 0
drop_slab 0
htlb_buddy_alloc_success 0
htlb_buddy_alloc_fail 0
unevictable_pgs_culled 64
unevictable_pgs_scanned 0
unevictable_pgs_rescued 0
unevictable_pgs_mlocked 64
unevictable_pgs_munlocked 0
unevictable_pgs_cleared 0
unevictable_pgs_stranded 0
EOF
	cat <<- EOF > "$HOME/.$linux/proc/.model"
$(getprop ro.product.brand) $(getprop ro.product.model)
EOF
	cat <<- EOF > "$HOME/.$linux/proc/.version"
Linux version 5.10.0 (termux@android) (gcc version 4.9 (GCC)) $(uname -v)
EOF

echo "写入方案一启动脚本"
cat <<- EOF > "${PREFIX}/bin/termux-$linux"
#!/bin/bash
unset LD_PRELOAD
command="proot"
command+=" --kernel-release=5.10.0"
command+=" --link2symlink"
command+=" --kill-on-exit"
command+=" --rootfs=\$HOME/.$linux"
command+=" --root-id"
command+=" --cwd=/root"
command+=" --bind=/dev"
command+=" --bind=/dev/urandom:/dev/random"
command+=" --bind=/proc"
command+=" --bind=/sys"
command+=" --bind=/storage/self/primary:/sdcard"
command+=" --bind=/data/data/com.termux"
command+=" --bind=\$HOME/.$linux/tmp:/dev/shm"
if ! cat /proc/loadavg > /dev/null 2>&1; then
command+=" --bind=\$HOME/.$linux/proc/.loadavg:/proc/loadavg"
fi
if ! cat /proc/stat > /dev/null 2>&1; then
command+=" --bind=\$HOME/.$linux/proc/.stat:/proc/stat"
fi
if ! cat /proc/uptime > /dev/null 2>&1; then
command+=" --bind=\$HOME/.$linux/proc/.uptime:/proc/uptime"
fi
if ! cat /proc/vmstat > /dev/null 2>&1; then
command+=" --bind=\$HOME/.$linux/proc/.vmstat:/proc/vmstat"
fi
command+=" --bind=\$HOME/.$linux/proc/.model:/sys/firmware/devicetree/base/model"
command+=" --bind=\$HOME/.$linux/proc/.version:/proc/version"
command+=" /usr/bin/env --ignore-environment"
command+=" HOME=/root"
command+=" LANG=C.UTF-8"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
command+=" TERM=\${TERM-xterm-256color}"
command+=" TMPDIR=/tmp"
command+=" SHELL=/bin/sh"
command+=" /bin/$bash_tmp --login"
com="\$@"; [ -z "\$1" ] && exec \${command} || \${command} -c "\${com}"
EOF

else
#写入方案二启动脚本
echo "写入方案二启动脚本"
cat > ${PREFIX}/bin/termux-$linux <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r \$HOME/.$linux"

command+=" $qemu_command "
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
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/$bash_tmp --login"
com="\$@"
if [ -z "\$1" ]; then
    exec \$command
else
    \$command -c "\$com"
fi
EOM
fi

echo "授予 termux-$linux 执行权限"
chmod +x "${PREFIX}/bin/termux-$linux"
chmod 700 $HOME/.$linux $HOME/.$linux/*

if [ $linux == "alpine" ]; then
#apline系统换科大源
echo "切换为科大源"
sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' $HOME/.$linux/etc/apk/repositories

#安装必要工具
echo "安装必备软件包"
pkg="bash bash-completion sudo tzdata curl wget git nano vim neofetch"
$PREFIX/bin/termux-$linux "apk -U upgrade --no-progress --no-cache"
$PREFIX/bin/termux-$linux "apk add --update --no-progress --no-cache $pkg"
fstab="$HOME/.$linux/etc/fstab"
if [ -f "$fstab" ]; then
    cp -n ${fstab}{,.bak}
    echo "" > $fstab
fi
echo "替换为bash"
sed -i "s/ash/bash/g" $HOME/.$linux/etc/passwd
sed -i "s/bin\/sh/bin\/bash/g" ${PREFIX}/bin/termux-$linux
fi

echo "$linux系统安装完成！"
read -p "是否保留镜像？[y/n] (输入y回车确认，回车默认删除)：" delete
    case $delete in
    y)
      echo "镜像文件已保留，如不需要请手动删除！"
      ;;
    *)
      rm -rf $linux-$newarch-$linux_ver.tar.xz
      echo "镜像文件已删除！"
    ;;
    esac;
#删除json
rm -rf images.json 2>/dev/null
echo -e "现在可以执行 \e[32mtermux-${linux}\e[0m 运行 $linux ${linux_ver} 了"
