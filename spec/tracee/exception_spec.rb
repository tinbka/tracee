require_relative '../../spec/exception_example'

describe 'Tracee stack trace extension' do

  it 'decorates an example exception trace as described' do
    begin
      Bomb::Wick.new.light!
    rescue => e
      expect(e.backtrace[0..4]).to contain_exactly(
        a_string_matching(%r{/spec/exception_example.rb:8:in `boom!'\n {3}>> {3}.*\s+fail "It has appeared too wet!"}),
        a_string_matching(%r{/spec/exception_example.rb:17:in `raise!' -> `loop' -> `raise!' -> `loop' -> `raise! \{2\}'\n {3}>> {3}.*\s+loop \{loop \{Bomb.new.boom! if \(t \+= 1\) == 100\}\}}),
        a_string_matching(%r{/spec/exception_example.rb:23:in `heat!'\n {3}>> {3}.*\s+Temperature.new.raise!}),
        a_string_matching(%r{/spec/exception_example.rb:31:in `light!'\n {3}>> {3}.*\s+Explosive.new.heat!}),
        a_string_matching(%r{/spec/tracee/exception_spec.rb:7:in `block \(2 levels\) in <top \(required\)>'\n {3}>> {3}.*\s+Bomb::Wick.new.light!})
      )
    end
  end

end