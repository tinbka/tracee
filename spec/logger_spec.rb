describe Tracee::Logger do
  let(:o) {Tracee::Logger.new}
  let(:stream) {o.streams[0]}
  let(:formatter) {o.formatter}
  let(:now) {DateTime.parse '2015.01.01 00:00:00'}
  
  before {allow(DateTime).to receive(:now).and_return(now)}

  describe 'is initialized' do
    let(:o2) {Tracee::Logger.new streams: [$stdout, '/path/to/logfile'], formatter: :base, preprocessors: [:base], level: :debug}
    
    it 'with default stream' do
      expect(o.streams).to contain_exactly an_instance_of Tracee::Stream
      expect(stream.target).to eq $stdout
    end
    
    it 'with default formatter' do
      expect(o.formatter).to be_an_instance_of Tracee::Preprocessors::Formatter
    end
    
    it 'with default log level' do
      expect([o.debug?, o.info?, o.warn?]).to contain_exactly(false, true, true)
    end
    
    it 'with custom stream' do
      expect(o2.streams[1].target).to eq '/path/to/logfile'
    end
    
    it 'with custom formatter' do
      expect(o2.formatter).to be_an_instance_of Tracee::Preprocessors::Base
    end
    
    it 'with custom preprocessor chain' do
      expect(o2.preprocessors).to contain_exactly an_instance_of Tracee::Preprocessors::Base
    end
    
    it 'with custom log level' do
      expect([o2.debug?, o2.info?, o2.warn?]).to contain_exactly(true, true, true)
    end
    
  end
  

  describe 'can change log level' do
    
    it 'accepts numbers' do
      initial = 1
      (0..5).each {|i|
        expect {o.level = i}.to change {o.level}.from(initial).to(i)
        initial = i
      }
    end
    
    it 'accepts symbols' do
      initial = 1
      Tracee::Logger::LEVEL_NAMES.each_with_index {|name, i|
        expect {o.level = name.to_sym}.to change {o.level}.from(initial).to(i)
        initial = i
      }
    end
    
  end
  
  
  describe 'passes a message' do
    let(:o3) {Tracee::Logger.new preprocessors: [:base]}
    let(:ppr) {o3.preprocessors[0]}
      
    it 'to a preprocessor' do
      allow(o3.formatter).to receive(:call) # to prevent $stdout output
      expect(ppr).to receive(:call).with('info', now, 'world', 'hello', a_collection_containing_exactly(a_string_matching(/#{__FILE__}:#{__LINE__+1}/)))
      o3.info('world') {'hello'}
    end
    
    it 'unless the message level is too less' do
      expect(ppr).to_not receive(:call)
      o3.debug 'hello?'
      o3.debug {o3.warn 'anyone?'}
    end
    
    it 'to a stream' do
      # because it intercepts #write, original #write would not be called
      expect(stream).to receive(:write).with(a_string_matching(/hello/), 2, 1)
      o.warn 'hello'
    end
    
    it 'unless the message level is too less' do
      expect(stream).to_not receive(:write)
      o.debug 'hello?'
      o.debug {o.warn 'anyone?'}
    end
    
    it 'unless a preprocessor throws :halt' do
      allow_any_instance_of(Tracee::Preprocessors::Base).to receive(:call) {throw :halt}
      expect(stream).to_not receive(:write)
      o3.fatal 'hello!'
    end
      
    it 'to a formatter' do
      # because it intercepts #call, original #call would not be called
      expect(formatter).to receive(:call).with('info', now, 'world', 'hello', a_collection_containing_exactly(a_string_matching(/#{__FILE__}:#{__LINE__+1}/), a_string_matching(/example.rb/)))
      o.info('world', caller_at: 0..1) {'hello'}
    end
    
    it 'unless the message level is too less' do
      expect(formatter).to_not receive(:call)
      o.debug 'hello?'
      o.debug {o.warn 'anyone?'}
    end
    
    it 'unless a preprocessor throws :halt' do
      allow_any_instance_of(Tracee::Preprocessors::Base).to receive(:call) {throw :halt}
      expect(formatter).to_not receive(:call)
      o3.fatal 'hello!'
    end
    
  end
  
  
  describe 'accepts a message' do
    let(:hash) {{key: :value}}
    let(:ambigous_hash) {{caller_at: :value}}
    
    it 'as hash' do
      expect(formatter).to receive(:call).with('info', now, nil, hash, satisfying {|a| a.size == 1})
      o << hash
    end
    
    it 'as hashes along with caller_at option' do
      expect(formatter).to receive(:call).with('info', now, nil, hash, satisfying {|a| a.size == 3})
      o.info hash, caller_at: [1, 3, 5]
    end
    
    it 'as literally {:caller_at => value}, but not as option' do
      expect(formatter).to receive(:call).with('info', now, nil, ambigous_hash, satisfying {|a| a.size == 1})
      o << ambigous_hash
    end
    
    it 'as block result with caller_at option' do
      expect(formatter).to receive(:call).with('info', now, nil, hash, satisfying {|a| a.size == 3})
      o.info(caller_at: [1, 3, 5]) {hash}
    end
    
    it 'as block result with progname first argument' do
      expect(formatter).to receive(:call).with('info', now, 'world', hash, satisfying {|a| a.size == 1})
      o.info('world') {hash}
    end
    
    it 'as block result with progname first argument and caller_at option' do
      expect(formatter).to receive(:call).with('info', now, 'world', hash, satisfying {|a| a.size == 3})
      o.info('world', caller_at: [1, 3, 5]) {hash}
    end
    
  end
  
  
  describe 'can do simple benchmarking' do
    let(:o4) {Tracee::Logger.new level: :warn}
    
    it 'measures time between calls on any stack level with #tick' do
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(0.001), Time.at(0.1))
      expect {o.tick!; o.tick; o.tick 'hello'}.to output(a_string_matching(/\[tick\] \n.+\[tick \+\S+0.\S+001\S+\] \n.+\[tick \+\S+0.\S+099\S+\] hello\n/)).to_stdout
    end
    
    it 'resets previous measurement with #tick!' do
      allow(Time).to receive(:now).and_return(Time.at(0), Time.at(0.001), Time.at(0.1), Time.at(0.5))
      expect {o.tick!; o.tick; o.tick! 'hello!'; o.tick}.to output(a_string_matching(/\[tick\] \n.+\[tick \+\S+0.\S+001\S+\] \n.+\[tick\] hello!\n.+\[tick \+\S+0.\S+4\S+\] \n/)).to_stdout
    end
    
    it 'writes nothing if log level set is too high' do
      expect {o4.tick!; o4.tick; o4.tick! 'hello!'; o4.tick}.to output('').to_stdout
    end
    
  end
  
end