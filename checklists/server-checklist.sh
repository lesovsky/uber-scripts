#!/usr/bin/env bash
# Description:	Check and print server system parameters

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

main() {
# Memory & Swap
echo "${yellow}=== memory: status ===${reset}
$(grep -E "^(Mem|Swap)Total:" /proc/meminfo)"

# Virtual Memory checks
echo "${yellow}=== sysctl: virtual memory ===${reset}
$(sysctl vm.dirty_background_bytes vm.dirty_bytes vm.dirty_background_ratio vm.dirty_ratio vm.swappiness vm.overcommit_memory vm.overcommit_ratio)"

# NUMA checks
echo "${yellow}=== sysctl: numa related ===${reset}
$(sysctl vm.zone_reclaim_mode)"

# CPU Scheduler check
echo "${yellow}=== sysctl: cpu scheduler ===${reset}
$(sysctl -e kernel.sched_migration_cost_ns kernel.sched_migration_cost kernel.sched_autogroup_enabled)"

# Files limits check
echo "${yellow}=== sysctl: files limits ===${reset}
$(sysctl fs.file-max)                        # maximum number of open files
$(sysctl fs.inotify.max_user_watches)        # maximum inotify watches per user
open files limit (ulimit -n): $(ulimit -n)          # maximum number of open files per process
available port range: $(sysctl net.ipv4.ip_local_port_range)"

# Transparent Hugepages check
echo "${yellow}=== sysfs: transparent hugepages ===${reset}
/sys/kernel/mm/transparent_hugepage/enabled: $(cat /sys/kernel/mm/transparent_hugepage/enabled)
/sys/kernel/mm/transparent_hugepage/defrag: $(cat /sys/kernel/mm/transparent_hugepage/defrag)"

# Time check
echo "${yellow}=== Ntpd info ===${reset}"
if which ntpd &>/dev/null
  then 
    if [[ $(ps ho comm -C ntpd) == *ntpd* ]]
       then echo "Ntpd found and running."
       else echo "Ntpd found, but not running."
    fi
  else echo "Ntpd not found."
fi

# Pgbouncer open file limit
echo "${yellow}=== Pgbouncer info ===${reset}"
if pgrep pgbouncer &>/dev/null
  then echo "pgbouncer open files limit: $(awk '/Max open files/{print "soft: " $4 " hard: " $5}' /proc/$(pgrep pgbouncer)/limits)"
  else echo "pgbouncer not running"
fi

echo "${yellow}=== Clocksource: available and current clocksource ===${reset}
/sys/devices/system/clocksource/clocksource0/available_clocksource: $(cat /sys/devices/system/clocksource/clocksource0/available_clocksource)
/sys/devices/system/clocksource/clocksource0/current_clocksource: $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"

echo "${yellow}=== EDAC ===${reset}"
if [[ $(lsmod |grep edac) ]]
  then
    for i in $(ls /sys/devices/system/edac/mc/mc*/*e_count);
      do echo "$i - $(cat $i)";
    done
  else
    echo "edac modules not loaded"
fi

# CPU Governor
echo "${yellow}=== CPU Governor ===${reset}"
if [ -d /sys/devices/system/cpu/cpu0/cpufreq/ ]
  then
    echo "current kernel version: $(uname -r)"
    for i in $(ls -1 /sys/devices/system/cpu/ | grep -oE 'cpu[0-9]+');
      do
        echo "$i: $(cat /sys/devices/system/cpu/$i/cpufreq/scaling_governor) (driver: $(cat /sys/devices/system/cpu/$i/cpufreq/scaling_driver))";
      done | awk '!(NR%2){print p "\t\t\t" $0}{p=$0}'
    else
      echo "cpufreq directory not found, invoke lscpu: "
      lscpu |grep -E '^(Model|Vendor|CPU( min| max)? MHz)'
fi

# Mounted filesystems
echo "${yellow}=== Mounted filesystems ===${reset}"
mount |grep -w -E 'ext(3|4)|reiserfs|xfs|rootfs' |column -t
}

main 
