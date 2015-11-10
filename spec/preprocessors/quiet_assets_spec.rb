describe Tracee::Preprocessors::QuietAssets do
  let(:default) {Tracee::Preprocessors::QuietAssets.new}
  let(:alt) {Tracee::Preprocessors::QuietAssets.new ['assets', 'alt_assets']}
  let(:now) {DateTime.parse '2015.01.01 00:00:00'}
  
  it 'halts a preprocessor chain when message matches assets path pattern' do
    expect {default.('info', now, nil, 'Started GET "/assets/jquery.js" blah-blah-blah')}.to throw_symbol :halt
    expect {default.('info', now, nil, 'Started GET "/assets')}.to_not throw_symbol anything
    
    expect {alt.('info', now, nil, 'Started GET "/assets/jquery.js" blah-blah-blah')}.to throw_symbol :halt
    expect {alt.('info', now, nil, 'Started GET "/alt_assets/jquery.js" blah-blah-blah')}.to throw_symbol :halt
    expect {alt.('info', now, nil, 'It is gonna have Started GET "/assets/jquery.js" blah-blah-blah')}.to_not throw_symbol :halt
    expect {alt.('info', now, nil, 'Started GET "/assets_something/jquery.js" blah-blah-blah')}.to_not throw_symbol :halt
    expect {alt.('info', now, nil, 'Started GET "/alt_assets" blah-blah-blah')}.to_not throw_symbol :halt
  end
  
end