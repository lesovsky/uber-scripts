#!/usr/bin/env bash
# Description:	Check and print server system parameters

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
red=$(tput setaf 1)
green=$(tput setaf 2)
reset=$(tput sgr0)

main() {
# Memory & Swap
echo "${red}=== memory: status ===${reset}
$(grep -E "^(Mem|Swap)Total:" /proc/meminfo)"

# Virtual Memory checks
echo "${red}=== sysctl: virtual memory ===${reset}
$(sysctl -a --pattern 'vm.dirty.*(ratio|bytes)')
$(sysctl vm.swappiness)
$(sysctl -a --pattern 'vm.overcommit_(memory|ratio)')"

# NUMA checks
echo "${red}=== sysctl: numa related ===${reset}
$(sysctl vm.zone_reclaim_mode)"

# CPU Scheduler check
echo "${red}=== sysctl: cpu scheduler ===${reset}
$(sysctl -a --pattern 'kernel.sched_(migration_cost|autogroup_enabled)')"

# Files limits check
echo "${red}=== sysctl: files limits ===${reset}
$(sysctl fs.file-max)                        # maximum number of open files
$(sysctl fs.inotify.max_user_watches)        # maximum inotify watches per user
open files limit (ulimit -n): $(ulimit -n)          # maximum number of open files per process
available port range: $(sysctl net.ipv4.ip_local_port_range)"

# Transparent Hugepages check
echo "${red}=== sysfs: transparent hugepages ===${reset}
/sys/kernel/mm/transparent_hugepage/enabled: $(cat /sys/kernel/mm/transparent_hugepage/enabled)
/sys/kernel/mm/transparent_hugepage/defrag: $(cat /sys/kernel/mm/transparent_hugepage/defrag)"

# Time check
echo "${red}=== Ntpd info ===${reset}"
if which ntpd &>/dev/null
  then 
    if [[ $(ps ho comm -C ntpd) == *ntpd* ]]
       then echo "Ntpd found and running."
       else echo "Ntpd found, but not running."
    fi
  else echo "Ntpd not found."
fi
echo "${red}=== Clocksource: available and current clocksource ===${reset}
/sys/devices/system/clocksource/clocksource0/available_clocksource: $(cat /sys/devices/system/clocksource/clocksource0/available_clocksource)
/sys/devices/system/clocksource/clocksource0/current_clocksource: $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"

echo "${red}=== EDAC ===${reset}"
if [[ $(lsmod |grep edac) ]]
  then
    for i in $(ls /sys/devices/system/edac/mc/mc*/*e_count);
      do echo "$i - $(cat $i)";
    done
  else
    echo "edac modules not loaded"
fi

# CPU Governor info
echo "${red}=== CPU Governor ===${reset}
current kernel version: $(uname -r)"
for i in $(ls -1 /sys/devices/system/cpu/ | grep -oE 'cpu[0-9]+'); 
do 
  echo "$i: $(cat /sys/devices/system/cpu/$i/cpufreq/scaling_governor) (driver: $(cat /sys/devices/system/cpu/$i/cpufreq/scaling_driver))";
done;

# Mounted filesystems
echo "${red}=== Mounted filesystems ===${reset}"
mount |grep -w -E 'ext(3|4)|reiserfs|xfs|rootfs' |column -t
}

main 
