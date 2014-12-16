### README: gnuplot scripts

Iostat (systat) - generate graphs based on iostat utility output. Compatible with iostat older versions and newer versions which have different output about latency (versions before 9.1.2 have not r_await and w_await columns).
- iostat-generate-cpu-graph.sh - generate graph about CPU usage (us,sy,wa).
- iostat-generate-iops-graph.sh - generate graph about IOPS (read/write).
- iostat-generate-bw-graph.sh - generate graph about bandwidth (read/write).
- iostat-generate-lat-graph.sh - generate graph about latency (await,r_await,w_await).
- iostat-generate-util-graph.sh - generate graph about disk utilization.

How-to use:
- start iostat and redirect output to file, for example: ```iostat -x 1 120 >iostat.out```
- generate specified graph: ```iostat-generate-lat-graph.sh iostat.out```
- additionally you can specify device and poll interval (default poll interval - 1 second, device - sda): ```iostat-generate-lat-graph.sh iostat.out sdb 2```
