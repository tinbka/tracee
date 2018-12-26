module Tracee::Preprocessors
  class Colorize < Base
    COLOR_MAP = {
      head: :white,
      action: :yellow,
      params: :yellowish,
      redirect: :purple,
      render: :greenish,
      complete: :white,
      raise: :red
    }
    
    def initialize(color_map=COLOR_MAP)
      @color_map = color_map
      exception_classes = []
      ObjectSpace.each_object(Exception.singleton_class) do |k|
        exception_classes.unshift k unless k == self
      end
      @exception_classes_re = exception_classes.map(&:name).join '|'
    end
  
    def call(msg_level, datetime, progname, msg, caller_slice=[])
      case msg
      when %r{^Started (?<method>[A-Z]+) "(?<path>/[^"]*)" for (?<ip>(?:[\d\.]+|[\da-f:]+)) at (?<time>[\d\-]+ [\d:]+(?: \+\d{4})?)}
        m = $~
        %{Started #{m[:method].send @color_map[:head]} "#{m[:path].send @color_map[:head]}" for #{m[:ip].send @color_map[:head]} at #{m[:time].send @color_map[:head]}}
      when %r{^Processing by (?<class>[A-Z][\w:]+)#(?<method>\w+) as (?<format>[A-Z]+|\*\/\*)$}
        m = $~
        %{Processing by #{m[:class].send @color_map[:action]}##{m[:method].send @color_map[:action]} as #{m[:format].send @color_map[:action]}}
      when %r{^  Parameters: (.+)$}
        m = $~
        "  Parameters: #{m[1].send @color_map[:params]}"
      when %r{^Redirected to (\S+)$}
        m = $~
        "Redirected to #{m[1].send @color_map[:redirect]}"
      when %r{^  Rendered .+ \(\d+\.\dms\)$}
        msg.send @color_map[:render]
      when %r{^Completed (?<code>\d{3}) (?<codename>[A-Z][\w ]+) in (?<time>\d+ms) (?<times>.+)$}
        m = $~
        #"\e[4mCompleted #{m[:code].send @color_map[:complete]}\e[4m #{m[:codename].send @color_map[:complete]}\e[4m in #{m[:time].send @color_map[:complete]}\e[4mms #{m[:times]}\e[0m"
        "Completed #{m[:code].send @color_map[:complete]} #{m[:codename].send @color_map[:complete]} in #{m[:time].send @color_map[:complete]} #{m[:times]}"
      when %r{^(BetterErrors::RaisedException|#@exception_classes_re) (.+)}
        m = $~
        "#{m[1].send @color_map[:raise]} #{m[2]}"
      else
        msg
      end
    end

  end
end