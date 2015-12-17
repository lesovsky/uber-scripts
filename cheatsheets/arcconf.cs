# device discovery
arcconf list                                    -- lists all controllers connected to the system
arcconf getstatus 1                             -- get controller #1 status 

arcconf getconfig 1 ad                          -- get controller detailed info
arcconf getconfig 1 ld                          -- get info about all logical drives
arcconf getconfig 1 pd                          -- get info about all physical drives

arcconf setstatsdatacollection 1 enable         -- enable data collections (required for getlogs options)
arcconf getlogs 1 stats tabular                 -- get stats, error counters, io histograms

arcconf getperform 1                            -- get performance profile
arcconf setperform 1 X                          -- set performance profile (X - number of profile)

arcconf phyerrorlog 1                           -- get phy error counters for controller
arcconf phyerrorlog 1 device all                -- get phy error counters for physical drives

arcconf setcache 1 deviceall enable             -- set writeback for physical devices (for enterprise ssd)
arcconf setcache 1 deviceall disble             -- set writeback for physical devices (for enterprise ssd)
arcconf setcache 1 logicaldrive 0 wbb           -- set writeback with ZMM for logical drive 0
