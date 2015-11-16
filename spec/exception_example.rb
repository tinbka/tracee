require 'tracee'

Tracee.decorate_stack_everywhere

class Bomb
  
  def boom!
    fail "It has appeared too wet!"
  end
  
  class Explosive
    
    class Temperature
      
      def raise!
        t = 0
        loop {loop {Bomb.new.boom! if (t += 1) == 100}}
      end
      
    end
    
    def heat!
      Temperature.new.raise!
    end
    
  end
  
  class Wick
    
    def light!
      Explosive.new.heat!
    end
    
  end
  
end

if __FILE__ == $0
  Bomb::Wick.new.light!
end