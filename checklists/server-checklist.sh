#!/usr/bin/env bash
# Description:	Check and print server system parameters

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Memory & Swap
echo "=== memory: free ===
$(grep -E "^(Mem|Swap)Total:" /proc/meminfo |sed -e 's/^/   /g')"

# Virtual Memory checks
echo "=== sysctl: virtual memory ===
   $(sysctl vm.dirty_background_bytes)
   $(sysctl vm.dirty_bytes)
   $(sysctl vm.dirty_background_ratio)
   $(sysctl vm.dirty_ratio)
   $(sysctl vm.swappiness)
   $(sysctl vm.overcommit_memory)
   $(sysctl vm.overcommit_ratio)"

# NUMA checks
echo "=== sysctl: numa related ===
   $(sysctl vm.zone_reclaim_mode)"

# Files limits check
echo "=== sysctl: files limits ===
   $(sysctl fs.file-max)                        # maximum number of open files
   $(sysctl fs.inotify.max_user_watches)        # maximum inotify watches per user
   open files limit (ulimit -n): $(ulimit -n)          # maximum number of open files per process
   available port range: $(sysctl net.ipv4.ip_local_port_range)"

# Transparent Hugepages check
echo "=== sysfs: transparent hugepages ===
   /sys/kernel/mm/transparent_hugepage/enabled: $(cat /sys/kernel/mm/transparent_hugepage/enabled)
   /sys/kernel/mm/transparent_hugepage/defrag: $(cat /sys/kernel/mm/transparent_hugepage/defrag)"

# Time check
echo "=== Ntpd info ==="
if which ntpd &>/dev/null
  then 
    if [[ $(ps ho comm -C ntpd) == *ntpd* ]]
       then echo "   Ntpd found and running."
       else echo "   Ntpd found, but not running."
    fi
  else echo "   Ntpd not found."
fi
echo "=== Clocksource: available and current clocksource ===
   /sys/devices/system/clocksource/clocksource0/available_clocksource: $(cat /sys/devices/system/clocksource/clocksource0/available_clocksource)
   /sys/devices/system/clocksource/clocksource0/current_clocksource: $(cat /sys/devices/system/clocksource/clocksource0/current_clocksource)"

echo "=== EDAC ==="
if [[ $(lsmod |grep edac) ]]
  then
    for i in $(ls /sys/devices/system/edac/mc/mc*/*e_count);
      do echo "   $i - $(cat $i)";
    done
  else
    echo "   edac modules not loaded"
fi

echo "=== CPU Governor ==="
echo "   current kernel version: $(uname -r)"
for i in $(ls -1 /sys/devices/system/cpu/ | grep -oE 'cpu[0-9]+'); 
do 
  echo "   $i: $(cat /sys/devices/system/cpu/$i/cpufreq/scaling_governor) (driver: $(cat /sys/devices/system/cpu/$i/cpufreq/scaling_driver))";
done;
