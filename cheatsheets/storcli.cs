StorCli is a RAID utility For LSI MegaRAID Controllers
cx - controller, for example c0
vx - volumegroup (RAID), for example v0

# storcli cx show help                          show controller related help
# storcli vx show help                          show virtual drive related help

Troubleshoot
# storcli /c0 show health                       show controller current health and status
# storcli /c0 show termlog                      show firmware logs (very cryptic)
# storcli /c0/bbu show                          bbu status

Describe configuration
# storcli /c0 show                              show controller info, vd list, pd list, cachevault status
# storcli /c0/v0 show all                       show volumegroup properties
# storcli /c0/v0 set wrcache=WT|WB|AWB          array cache policy
# storcli /c0/v0 set rdcache=RA|NoRA            readahead policy
# storcli /c0/v0 set pdcache=On|Off|Default     disc cache policy
# storcli /c0/bbu show                          bbu status
# storcli /c0/dall show cachecade               show cachecade configuration
