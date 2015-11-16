describe Tracee::IndifferentStream do
  let(:debug_writable) {Object.new.tap {|o| o.class_eval {define_method(:<<) {|msg|}}}}
  let(:error_writable) {Object.new.tap {|o| o.class_eval {define_method(:<<) {|msg|}}}}
  
  let(:stdio) {Tracee::IndifferentStream.new $stdout}
  let(:fileio) {Tracee::IndifferentStream.new File.open('stream.log', 'a')}
  let(:multiio) {Tracee::IndifferentStream.new debug: debug_writable, error: error_writable}
  
  after(:each) {Dir['*.log'].each {|log| FileUtils.rm log}}
    
  it 'when targeted to an IO, writes a message to it' do
    expect {stdio.write 'hel'; stdio.write 'lo'}.to output('hello').to_stdout
    
    fileio.write 'hel'; fileio.write 'lo'; fileio.target.close
    expect(File.read 'stream.log').to eq 'hello'
  end
  
  
  describe 'when targeted to a multiple <<\'able objects' do
    
    it 'writes a message according to message\'s and logger\'s log level' do
      expect(debug_writable).to receive(:<<).with('ahoy').twice
      expect(error_writable).to receive(:<<).with('ahoy').once
      
      # message level, logger level
      multiio.write 'ahoy', Tracee::Logger::ERROR, Tracee::Logger::DEBUG
      multiio.write 'ahoy', Tracee::Logger::INFO, Tracee::Logger::DEBUG
    end
    
    it 'does not write a message anywhere if a logger level is too high for defined targets' do
      expect(debug_writable).to_not receive(:<<)
      expect(error_writable).to_not receive(:<<)
      
      # message level, logger level
      multiio.write 'ahoy', Tracee::Logger::INFO, Tracee::Logger::WARN
    end
    
  end
  
end