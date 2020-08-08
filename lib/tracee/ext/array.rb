class Array

  def decorate_stack(paint_code_line: 'greenish')
    Tracee::Stack::BaseDecorator.call(self, paint_code_line: paint_code_line)
  end

end
