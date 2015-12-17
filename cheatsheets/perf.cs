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
