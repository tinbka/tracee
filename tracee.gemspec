# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tracee/version'

Gem::Specification.new do |spec|
  spec.name          = "tracee"
  spec.version       = Tracee::VERSION
  spec.authors       = ["Sergey Baev"]
  spec.email         = ["tinbka@gmail.com"]

  spec.summary       = %q{Fancy logger to trace all the depths of the code}
  spec.description   = %q{Tracee is a simple Rails-compatible logger meant for development enriched with stack tracing, benchmarking, log-level based output splitting and formatting.}
  spec.homepage      = "https://github.com/tinbka/tracee"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  
  spec.add_dependency "colorize"
  spec.add_dependency "activesupport"
end
