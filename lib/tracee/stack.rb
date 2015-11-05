require 'tracee/stack/base_decorator'

module Tracee
  module Stack
    mattr_accessor :reload_script_lines
    SCRIPT_LINES_MTIMES = {}
    
    # Note that Rails' autoreload of code doesn't rewrite SCRIPT_LINES__,
    # to perform that automatically, Tracee::Stack.reload_script_lines should be turned on.
    def self.readlines(file)
      if reload_script_lines
        if File.exists?(file)
          mtime = File.mtime(file)
          if SCRIPT_LINES_MTIMES[file] < File.mtime(file)
            SCRIPT_LINES__[file] = IO.readlines(file)
          end
          SCRIPT_LINES__[file]
        end
      else
        if lines = SCRIPT_LINES__[file]
          lines
        else
          if File.exists?(file)
            SCRIPT_LINES_MTIMES[file] = File.mtime(file)
            SCRIPT_LINES__[file] = IO.readlines(file)
          end
        end
      end
    end
    
    def self.readline(file, line)
      if lines = readlines(file)
        (lines[line.to_i - 1] || "<line #{line} is not found> ").chomp.green
      end
    end
  
  end
end