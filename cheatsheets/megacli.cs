MegaCli is a RAID utility For LSI MegaRAID Controllers
LD - LogicalDrive
PD - PhysicalDrive
BBU - Backup Battery Unit

# Get Info
megacli adpcount                # get controllers count
megacli adpallinfo aall         # get information about all adapters
megacli adpbbucmd aall          # get BBU information
megacli ldinfo lall aall        # get LogicalDrives information from all adapters
magacli pdlist aall             # get PhysicalDrives information from all adapters
megacli pdinfo physdrv [32:2] a0                # get info about specified drive
megacli pdrbld showprog physdrv [32:2] a0       # get info about rebuild progress
megacli pdlocate start|stop physdrv [32:2] a0   # start/stop flashing on specified drive

# Get/Set Logical Drives Properties
megacli ldgetprop cache lall aall       # get LogicalDrives cache information 
megacli ldgetprop dskcache lall aall    # get PhysicalDrive cache status
MegaCli ldinfo lall aall |grep -E '(Virtual Drive|RAID Level|Cache Policy|Access Policy)'       # get LD cache and PD cache information

megacli ldsetprop WB RA DisDskCache NoCachedBadBBU lall aall    # set WriteBack, Adaptive ReadAhead, disable Disk Cache, Disable Cache when bad BBU

# Misc
megacli adpfwflash -f filename aN       # flash adapter firmware from image
megacli phyerrorcounters aN             # get error counters for physical media

# EventLog
MegaCli -AdpEventLog -GetEventLogInfo -aN|-a0,1,2|-aALL 
MegaCli -AdpEventLog -GetEvents {-info -warning -critical -fatal} {-f <fileName>} -aN|-a0,1,2|-aALL 
MegaCli -AdpEventLog -GetSinceShutdown {-info -warning -critical -fatal} {-f <fileName>} -aN|-a0,1,2|-aALL 
MegaCli -AdpEventLog -GetSinceReboot {-info -warning -critical -fatal} {-f <fileName>} -aN|-a0,1,2|-aALL 
MegaCli -AdpEventLog -IncludeDeleted {-info -warning -critical -fatal} {-f <fileName>} -aN|-a0,1,2|-aALL 
MegaCli -AdpEventLog -GetLatest n {-info -warning -critical -fatal} {-f <fileName>} -aN|-a0,1,2|-aALL 
MegaCli -AdpEventLog -GetCCIncon -f <fileName> -LX|-L0,2,5...|-LALL -aN|-a0,1,2|-aALL 
MegaCli -AdpEventLog -Clear -aN|-a0,1,2|-aALL 

# Disgnose
megacli fwtermlogdsply aall > /tmp/out.log
