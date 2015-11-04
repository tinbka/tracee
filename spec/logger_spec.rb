describe Tracee::Logger do

  describe 'is initialized' do
    let(:o) {Tracee::Logger.new}
    
    it 'with default stream' do
      expect(o.streams).to_equal [$stdout]
    end
    
    it 'with default formatter' do
      expect(o.formatter).to contain_exactly an_instance_of Tracee::Formatters::Template
    end
    
    it 'with default log level' do
      expect([o.debug?, o.info?, o.warn?]).to_equal [true, true, false]
    end
    
  end
  
end