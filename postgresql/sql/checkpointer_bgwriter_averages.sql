SELECT 
        now()-pg_postmaster_start_time()    "Uptime", now()-stats_reset     "Since stats reset",
        round(100.0*checkpoints_req/total_checkpoints,1)                    "Forced checkpoint ratio (%)",
        round(np.min_since_reset/total_checkpoints,2)                       "Minutes between checkpoints",
        round(checkpoint_write_time::numeric/(total_checkpoints*1000),2)    "Average write time per checkpoint (s)",
        round(checkpoint_sync_time::numeric/(total_checkpoints*1000),2)     "Average sync time per checkpoint (s)",
        round(total_buffers/np.mp,1)                                        "Total MB written",
        round(buffers_checkpoint/(np.mp*total_checkpoints),2)               "MB per checkpoint",
        round(buffers_checkpoint/(np.mp*np.min_since_reset*60),2)           "Checkpoint MBps",
        round(buffers_clean/(np.mp*np.min_since_reset*60),2)                "Bgwriter MBps",
        round(buffers_backend/(np.mp*np.min_since_reset*60),2)              "Backend MBps",
        round(total_buffers/(np.mp*np.min_since_reset*60),2)                "Total MBps",
        round(1.0*buffers_alloc/total_buffers,3)                            "New buffer allocation ratio",        
        round(100.0*buffers_checkpoint/total_buffers,1)                     "Clean by checkpoints (%)",
        round(100.0*buffers_clean/total_buffers,1)                          "Clean by bgwriter (%)",
        round(100.0*buffers_backend/total_buffers,1)                        "Clean by backends (%)",
        round(100.0*maxwritten_clean/(np.min_since_reset*60000/np.bgwr_delay),2)            "Bgwriter halt-only length (buffers)",
        coalesce(round(100.0*maxwritten_clean/(nullif(buffers_clean,0)/np.bgwr_maxp),2),0)  "Bgwriter halt ratio (%)",
        '--------------------------------------'         "--------------------------------------",
        bgstats.*
  FROM (
    SELECT bg.*,
        checkpoints_timed + checkpoints_req total_checkpoints,
        buffers_checkpoint + buffers_clean + buffers_backend total_buffers,
        pg_postmaster_start_time() startup,
        current_setting('checkpoint_timeout') checkpoint_timeout,
        current_setting('max_wal_size') max_wal_size,
        current_setting('checkpoint_completion_target') checkpoint_completion_target,
        current_setting('bgwriter_delay') bgwriter_delay,
        current_setting('bgwriter_lru_maxpages') bgwriter_lru_maxpages,
        current_setting('bgwriter_lru_multiplier') bgwriter_lru_multiplier
    FROM pg_stat_bgwriter bg
        ) bgstats,
        (
    SELECT
        round(extract('epoch' from now() - stats_reset)/60)::numeric min_since_reset,
        (1024 * 1024 / block.setting::numeric) mp,
        delay.setting::numeric bgwr_delay,
        lru.setting::numeric bgwr_maxp
    FROM pg_stat_bgwriter bg
    JOIN pg_settings lru   ON lru.name = 'bgwriter_lru_maxpages'
    JOIN pg_settings delay ON delay.name = 'bgwriter_delay'
    JOIN pg_settings block ON block.name = 'block_size'
        ) np;   -- don't print that
