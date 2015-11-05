module Tracee
  module Stack
    module BaseDecorator
    
      def self.call(source)
        return source if source.empty? or source[0]["\n"] # already decorated
        
        result, current_line_steps = [], []
        # path, file, line, is_block, block_level, method
        step_details = source[0].match(CALLER_RE)
        
        source.each_with_index do |step, i|
          next_step_details = source[i+1] && source[i+1].match(CALLER_RE)
          
          if step_details and step_details[:path] !~ Tracee::IGNORE_RE
            #if level = step_details[:block_level]
            #  step = step.sub(/block (\(\d+ levels\) )?in/, "{#{level}}")
            #end
            if method = step_details[:method] and next_step_details and [step_details[:path], step_details[:line]] == [next_step_details[:path], next_step_details[:line]]
              current_line_steps.unshift "`#{method}#{" {#{step_details[:block_level]}}" if step_details[:block_level]}'"
            elsif step_details[:line].to_i > 0 and code_line = Tracee::Stack.readline(step_details[:path], step_details[:line])
              current_line_steps.unshift step
              result << "#{current_line_steps * ' -> '}\n   >>   #{code_line}"
              current_line_steps = []
            else
              result << step
            end
          end
          step_details = next_step_details
        end
        
        if defined? IRB and result.size > IRB.conf[:BACK_TRACE_LIMIT] and result.last[-1] != "\n"
          result.last << "\n"
        end
        
        result
      end
    
    end
  end
end