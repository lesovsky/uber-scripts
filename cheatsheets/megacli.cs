MegaCli is a RAID utility For LSI MegaRAID Controllers

megacli adpallinfo aall         # get information about all adapters
megacli adpbbucmd aall          # get BBU information
megacli ldinfo lall aall        # get LogicalDrives information from all adapters
magacli pdlist aall             # get PhysicalDrives information from all adapters

megacli ldgetprop cache lall aall       # get LogicalDrives cache information 
megacli ldgetprop dskcache lall aall    # get PhysicalDrive cache status

megacli ldsetprop WB RA DisDskCache NoCachedBadBBU lall aall    # set WriteBack, Adaptive ReadAhead, disable Disk Cache, Disable Cache when bad BBU
