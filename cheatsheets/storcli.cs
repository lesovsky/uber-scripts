StorCli is a RAID utility For LSI MegaRAID Controllers
cx - controller
vx - volumegroup (RAID)
dx - diskgroup

# storcli /cx/vx show all                       show volumegroup properties
# storcli /cx/vx set wrcache=WT|WB|AWB          array cache policy
# storcli /cx/vx set rdcache=RA|NoRA            readahead policy
# storcli /cx/vx set pdcache=On|Off|Default     disc cache policy
# storcli /cx/bbu show                          bbu status
