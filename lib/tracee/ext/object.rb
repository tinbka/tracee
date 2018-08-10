class Object
  
  def __log__(caller_at: 0)
    if Tracee.default_logger
      Tracee.default_logger.debug(caller_at: caller_at + 1) {inspect}
    end
    self
  end
  
end
