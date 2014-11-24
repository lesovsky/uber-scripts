MegaCli is a RAID utility For LSI MegaRAID Controllers
LD - LogicalDrive
PD - PhysicalDrive
BBU - Backup Battery Unit

megacli adpcount                # get controllers count
megacli adpallinfo aall         # get information about all adapters
megacli adpbbucmd aall          # get BBU information
megacli ldinfo lall aall        # get LogicalDrives information from all adapters
magacli pdlist aall             # get PhysicalDrives information from all adapters

megacli ldgetprop cache lall aall       # get LogicalDrives cache information 
megacli ldgetprop dskcache lall aall    # get PhysicalDrive cache status
MegaCli ldinfo lall aall |grep -E '(Virtual Drive|RAID Level|Cache Policy|Access Policy)'       # get LD cache and PD cache information

megacli ldsetprop WB RA DisDskCache NoCachedBadBBU lall aall    # set WriteBack, Adaptive ReadAhead, disable Disk Cache, Disable Cache when bad BBU

megacli adpfwflash -f filename aN       # flash adapter firmware from image
