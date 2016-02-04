# List events
perf list
perf list ext4:*
perf list syscalls:sys_enter_*
perf list *:*exec*

# Tracing
perf trace -a                                                   -- trace on all cpu's
perf trace -c 0-4                                               -- trace on provided cpu's list
perf trace -p 12345,...                                         -- trace processes by their pids
perf trace -s -p 12345,...                                      -- summary trace
perf trace -e semctl,...                                        -- trace semctl syscals
perf trace --event sched:sched_process_exec,...                 -- trace events and syscalls
perf trace --no-syscalls --event foo:bar,...                    -- trace only events    (since kernel 4.1)

# Stat
perf stat -a -e vmscan:mm_*                                     -- stat vmscan:mm_8 events on all cpu's
perf stat -a -e vmscan:mm_* -- sleep 10                         -- the same as above but old version required a stub command
perf stat -a -I 10000 -e ...                                    -- print stat every 10 seconds

# Top
perf top -a -e event,...                                        -- top on all cpu's with specified events
perf top -a --call-graph fp|dwarf                               -- top with call-graph
