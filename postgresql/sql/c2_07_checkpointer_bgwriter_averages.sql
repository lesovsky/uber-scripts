SELECT round(100.0*checkpoints_req/checkpoints,1)                   "Forced checkpoint ratio (%)",
       round(min_since_reset/checkpoints,2)                         "Minutes between checkpoints",
       round(checkpoint_write_time::numeric/(checkpoints*1000),2)   "Average write time per checkpoint(s)",
       round(checkpoint_sync_time::numeric/(checkpoints*1000),2)    "Average sync time per checkpoint(s)",
       round(total_buffers/mp,1)                                    "Total MB written",
       round(buffers_checkpoint/(mp*checkpoints),2)                 "MB per checkpoint",
       round(buffers_checkpoint/(mp*min_since_reset*60),2)          "Checkpoint MBps",
       round(buffers_clean/(mp*min_since_reset*60),2)               "`bgwriter` MBps",
       round(buffers_backend/(mp*min_since_reset*60),2)             "Backend MBps",
       round(total_buffers/(mp*min_since_reset*60),2)               "Total MBps",
       round(100.0*buffers_checkpoint/total_buffers,1)              "Clean by checkpoints (%)",
       round(100.0*buffers_clean/total_buffers,1)                   "Clean by `bgwriter` (%)",
       round(100.0*buffers_backend/total_buffers,1)                 "Clean by backends (%)",
       round(100.0*maxwritten_clean/(min_since_reset*60000/bgwriter_delay),2)                       "`bgwriter` halt-only length (buffers)",
       coalesce(round(100.0*maxwritten_clean/(nullif(buffers_clean,0)/bgwriter_lru_maxpages),2),0)  "`bgwriter` halt ratio (%)",
       round(1.0*buffers_alloc/total_buffers,3)         "New buffer allocation ratio",
       now()-stats_reset                                "Since stats reset",
       now()-pg_postmaster_start_time()                 "Uptime",
       '-------'                                                  "-------------------------------------",
       *
  FROM (
    SELECT bg.*,
           checkpoints_timed + checkpoints_req checkpoints,
           buffers_checkpoint + buffers_clean + buffers_backend total_buffers,
           pg_postmaster_start_time() startup,
           round(extract('epoch' from now() - stats_reset)/60)::numeric min_since_reset,
           (1024 * 1024 / block.setting::numeric) mp,
           delay.setting::numeric bgwriter_delay,
           lru.setting::numeric bgwriter_lru_maxpages,
           ratio.setting::numeric bgwriter_lru_multiplier
      FROM pg_stat_bgwriter bg
      JOIN pg_settings lru   ON lru.name = 'bgwriter_lru_maxpages'
      JOIN pg_settings delay ON delay.name = 'bgwriter_delay'
      JOIN pg_settings ratio ON ratio.name = 'bgwriter_lru_multiplier'
      JOIN pg_settings block ON block.name = 'block_size'
        ) bgstats;
