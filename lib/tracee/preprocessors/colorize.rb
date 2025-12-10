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
      when %r{^Started (?<method>[A-Z]+) "(?<path>/[^"]*)" for (?<ip>(?:[\d\.]+|[\da-f:]+)) at (?<time>[\d\-]+ [\d:]+(?: (\+\d{4}|[A-Z]{3}))?)}
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
      when %r{^  Render(ed|ing) .+(?: \([\w\d .:|]+\))?$}
        msg.send @color_map[:render]
      when %r{^Completed (?<code>\d{3}) (?<codename>[A-Z][\w ]+) in (?<time>\d+ms) (?<times>.+)$}
        m = $~
        #"\e[4mCompleted #{m[:code].send @color_map[:complete]}\e[4m #{m[:codename].send @color_map[:complete]}\e[4m in #{m[:time].send @color_map[:complete]}\e[4mms #{m[:times]}\e[0m"
        "Completed #{m[:code].send @color_map[:complete]} #{m[:codename].send @color_map[:complete]} in #{m[:time].send @color_map[:complete]} #{m[:times]}"
      when %r{^(BetterErrors::RaisedException|#@exception_classes_re) (.+)}
        m = $~
        "#{m[1].send @color_map[:raise]} #{m[2]}"
      when %r{(?<verb>(Enqueued|Performing|Performed)) (?<job>[\w:]+) \(Job ID: (?<id>[\da-f\-]+)\) (?<dir>(to|from)) (?<env>\w+)\((?<queue>\w+)\) ((?<at>(enqueued )?at )(?<time>[\d\-]+[ T][\d:]+(?:( \+\d{4}| [A-Z]{3}|Z))? ))?(?<with>with arguments: )?(?<args>.*)}
        m = $~
        args = m[:args].send(@color_map[:params]).sub(/\e\[0;33m"([\w:]+)"/, "\e[0;33m\"#{'\1'.send(@color_map[:action]) }\e[0;33m\"")
        %{#{m[:verb]} #{m[:job].send @color_map[:action]} (Job ID: #{m[:id].send @color_map[:head]}) #{m[:dir]} #{m[:env].send @color_map[:head]}(#{m[:queue].send @color_map[:head]}) #{m[:at]}#{m[:time].try @color_map[:head]}#{"\n  Arguments: " if m[:with]}#{args}}
      else
        msg
      end
    end

  end
end
