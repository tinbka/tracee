describe Tracee::Preprocessors::Formatter do
  [:tracee, :logger_formatter, :plain, :empty].each do |template|
    let(template) {Tracee::Preprocessors::Formatter.new template}
  end
  
  let(:now) {DateTime.parse '2015.01.01 00:00:00'}
  
  describe 'when a template contains %{message} key' do
  
    it 'renders a string message without quotes' do
      expect(tracee.('info', now, nil, 'hello')).to match(/(^|[^"])hello([^"]|$)/)
    end
  
    it 'renders a non-string message inspected' do
      expect(tracee.('info', now, nil, ['hello'])).to match(/\["hello"\]/)
    end
        
      end
      
    
  describe 'as tracee' do
  
    it 'renders a tracee template containing time, log level, caller and message' do
      expect(tracee.('info', now, 'world', 'hello', caller(0)[0..1])).to match(/00:00:00.000 \S+INFO\S+ \[\S+:\S+ .+ -> \S+#{File.basename __FILE__}:#{__LINE__}\S+ .+\]: hello/)
    end
  
  end
  
  describe 'as logger_formatter' do
  
    it 'renders a logger_formatter template containing time, log level, pid, progname and message' do
      expect(logger_formatter.('info', now, 'world', 'hello')).to \
        match(/I, \[2015-01-01T00:00:00.000000 ##{Process.pid}\] INFO -- world: hello/)
    end
  
  end
  
  describe 'as empty' do
  
    it 'renders only newline' do
      expect(empty.('info', now, 'world', 'hello')).to eq "\n"
    end
  
  end
  
end