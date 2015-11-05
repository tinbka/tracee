describe Tracee::Stream do
  let(:stdio) {Tracee::Stream.new $stdout}
  let(:fileio) {Tracee::Stream.new File.open('stream.log', 'a')}
  let(:pathy) {Tracee::Stream.new 'stream.log'}
  let(:multipathy) {Tracee::Stream.new debug: 'debug.log', info: 'info.log'}
  let(:cascade) {Tracee::Stream.new cascade: '%{level}.log'}
  
  after(:each) {Dir['*.log'].each {|log| FileUtils.rm log}}
    
  it 'when targeted to an IO, writes a message to it' do
    expect {stdio.write 'hello', 0, 0}.to output('hello').to_stdout
    fileio.write 'hello', 0, 0
    fileio.target.close
    expect(File.read 'stream.log').to eq 'hello'
  end
    
  it 'when targeted to a logfile path, writes a message to it' do
    pathy.write 'hello', 0, 0
    expect(File.read 'stream.log').to eq 'hello'
  end
  
  
  describe 'when targeted to a multiple paths' do
    
    it 'writes a message according to message\'s and logger\'s log level' do
      # message level, logger level
      multipathy.write 'hello', Tracee::Logger::WARN, Tracee::Logger::DEBUG
      expect([File.read('debug.log'), File.read('info.log')]).to eq ['hello', 'hello']
    end
    
    it 'does not write a message anywhere if log_level is too high' do
      # message level, logger level
      multipathy.write 'hello', Tracee::Logger::DEBUG, Tracee::Logger::WARN
      expect([File.exists?('debug.log'), File.exists?('info.log')]).to eq [false, false]
    end
    
  end
  
  
  describe 'when targeted to a cascade path pattern' do
    
    it 'writes a message according to message\'s and logger\'s log level' do
      # message level, logger level
      cascade.write 'hello', Tracee::Logger::WARN, Tracee::Logger::DEBUG
      expect(%w{error fatal}.map {|level| File.exists?(level+'.log')}).to eq [false, false]
      expect(%w{debug info warn}.map {|level| File.read(level+'.log')}).to eq ['hello', 'hello', 'hello']
    end
    
    it 'does not write a message anywhere if log_level is too high' do
      # message level, logger level
      cascade.write 'hello', Tracee::Logger::ERROR, Tracee::Logger::WARN
      expect(%w{debug info fatal}.map {|level| File.exists?(level+'.log')}).to eq [false, false, false]
      expect(%w{warn error}.map {|level| File.read(level+'.log')}).to eq ['hello', 'hello']
    end
    
  end
  
end