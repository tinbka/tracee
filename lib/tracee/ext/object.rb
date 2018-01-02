class Object
  
  def __log__(caller_at: 0)
    $log.debug(caller_at: caller_at + 1) {inspect}
    self
  end
  
end
