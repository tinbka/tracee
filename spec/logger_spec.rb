describe Tracee::Logger do
  let(:o) {Tracee::Logger.new}

  describe 'is initialized' do
    let(:o2) {Tracee::Logger.new streams: [$stdout, '/path/to/logfile'], formatter: :abstract, log_level: :debug}
    
    it 'with default stream' do
      expect(o.streams).to contain_exactly an_instance_of Tracee::Stream
      expect(o.streams[0].target).to eq $stdout
    end
    
    it 'with default formatter' do
      expect(o.formatters).to contain_exactly an_instance_of Tracee::Formatters::Template
    end
    
    it 'with default log level' do
      expect([o.debug?, o.info?, o.warn?]).to contain_exactly(false, true, true)
    end
    
    it 'with custom stream' do
      expect(o2.streams[1].target).to eq '/path/to/logfile'
    end
    
    it 'with custom formatter' do
      expect(o2.formatters).to contain_exactly an_instance_of Tracee::Formatters::Abstract
    end
    
    it 'with custom log level' do
      expect([o2.debug?, o2.info?, o2.warn?]).to contain_exactly(true, true, true)
    end
    
  end
  

  describe 'can change log level' do
    
    it 'accepts numbers' do
      initial = 1
      (0..5).each {|i|
        expect {o.log_level = i}.to change {o.log_level}.from(initial).to(i)
        initial = i
      }
    end
    
    it 'accepts symbols' do
      initial = 1
      Tracee::Logger::LEVEL_NAMES.each_with_index {|name, i|
        expect {o.log_level = name.to_sym}.to change {o.log_level}.from(initial).to(i)
        initial = i
      }
    end
    
  end
  
  
  describe 'passes messages' do
    
    it 'to a stream' do
      expect(o.streams[0]).to receive(:write).with(a_string_matching(/hello/), 2, 1)
      o.warn 'hello'
    end
    
    it 'unless the message level is too less' do
      expect(o.streams[0]).to_not receive(:write)
      o.debug 'hello?'
      o.debug {'anyone?'}
    end
      
    it 'to a formatter' do
      # because it receives #call, actual #call would not be called
      expect(o.formatters[0]).to receive(:call).with('hello', 'world', 'info', a_collection_containing_exactly(a_string_matching(/#{__FILE__}:#{__LINE__+1}/), a_string_matching(/example.rb/)))
      o.info('world', caller_at: 0..1) {'hello'}
    end
    
    it 'unless the message level is too less' do
      expect(o.formatters[0]).to_not receive(:call)
      o.debug 'hello?'
    end
    
  end
  
  
  describe 'can do simple benchmarking' do
    
    it 'measures time between calls on any stack level with #tick' do
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(0.001), Time.at(0.1))
      expect {o.tick!; o.tick; o.tick 'hello'}.to output(a_string_matching(/\[tick\] \n.+\[tick \+\S+0.\S+001\S+\] \n.+\[tick \+\S+0.\S+099\S+\] hello\n/)).to_stdout
    end
    
    it 'resets previous measurement with #tick!' do
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(0.001), Time.at(0.1), Time.at(0.5))
      expect {o.tick!; o.tick; o.tick! 'hello!'; o.tick}.to output(a_string_matching(/\[tick\] \n.+\[tick \+\S+0.\S+001\S+\] \n.+\[tick\] hello!\n.+\[tick \+\S+0.\S+4\S+\] \n/)).to_stdout
    end
    
  end
  
end