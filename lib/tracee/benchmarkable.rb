module Tracee
  # Suppose, we have a code that works too slow, still it runs for 50ms.
  # You measure time in 5 points between calls, and it gives you the first time:
  #   0.025997, 0.012339, 0.037864, 0.0415
  # the next time:
  #   0.01658, 0.011366, 0.046607, 0.052117
  # the third time:
  #   0.016733, 0.011295, 0.032805, 0.036667
  # How long has each block of code been executed _actualy_?
  # The code runtime may fluctuate slightly because a PC does some work beside your benchmarking.
  # The less the code runtime, the more relative fluctuations are. Thats why we do enough passes to minify them.
  #
  # This module allows to not only measure time between arbitrary calls (ticks),
  # and not only get an average from multiple repeats of a block,
  # but to get a list of averages between each arbitrary call (tick) in a block.
  #
  # Here's a sample:
  #
  #> $log.benchmark(times:20) {Ability.new(u)}
  #  23:29:59.021 INFO [ability.rb:76 :assistant_permissions]: [tick +0.576797] 
  #  23:29:59.034 INFO [ability.rb:84 :assistant_permissions]: [tick +0.245685] 
  #  23:29:59.075 INFO [ability.rb:93 :assistant_permissions]: [tick +0.728214] 
  #  23:29:59.120 INFO [ability.rb:111 :assistant_permissions]: [tick +0.866646] 
  #  23:29:59.120 INFO [(irb):8 :irb_binding]: [tick +0.000559] [120.978946ms each; 2419.578914ms total] #<Ability:0x000000088c89c8>
  module Benchmarkable
    
    def benchmark(times: 1, &block)
      @benchmark = Benchmark.new
      before_proc = Time.now
      
      (times - 1).times {yield}
      @benchmark.last_pass!
      result = yield
      
      now = Time.now
      @benchmark = nil
      
      diff_ms = (now - before_proc)*1000
      milliseconds_each = highlight_time_diff(diff_ms/times)
      milliseconds_total = highlight_time_diff(diff_ms)
      info "[#{milliseconds_each}ms each; #{milliseconds_total}ms total] #{result}", caller_at: 1
    end
    
    def tick(msg='', caller_offset: 0)
      now = Time.now
      
      if @benchmark
        if prev = Thread.current[:tracee_checkpoint]
          tick_diff = @benchmark.add_time(now - prev)
          if @benchmark.last_pass
            info "[tick +#{highlight_time_diff(tick_diff)}] #{msg}", caller_at: caller_offset+1
          end
          @benchmark.next
        # else we just write `now' to a thread var
        end
      else
        if prev = Thread.current[:tracee_checkpoint]
          info "[tick +#{highlight_time_diff(now - prev)}] #{msg}", caller_at: caller_offset+1
        else
          info "[tick] #{msg}", caller_at: caller_offset+1
        end
      end
      
      Thread.current[:tracee_checkpoint] = now
      nil
    end
    
    def tick!(msg='', caller_offset: 0)
      @benchmark.first! if @benchmark
      Thread.current[:tracee_checkpoint] = nil
      
      tick msg, caller_offset: caller_offset+1
    end
    
    
    private
    
    def highlight_time_diff(diff)
      diff.round(6).to_s.sub(/(\d+)\.(\d{0,3})(\d*)$/) {|m| "#$1.".light_white + $2.white + $3.light_black}
    end
    
  end
  
  
  class Benchmark
    attr_reader :ticks_diffs, :last_pass, :tick_number
    
    def initialize
      @ticks_diffs = Hash.new {|h, k| h[k] = 0}
    end
    
    def last_pass!
      @last_pass = true
    end
    
    def first!
      @tick_number = 0
    end
    
    def next
      @tick_number += 1
    end
    
    def add_time(amount)
      @ticks_diffs[@tick_number] += amount
    end
    
    def tick_diff
      @ticks_diffs[@tick_number]
    end
    
  end
end