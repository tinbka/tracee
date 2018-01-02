# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tracee/version'

Gem::Specification.new do |spec|
  spec.name          = "tracee"
  spec.version       = Tracee::VERSION
  spec.authors       = ["Sergey Baev"]
  spec.email         = ["tinbka@gmail.com"]

  spec.summary       = %q{An extensible logger with stack tracing, benchmarking, preprocessing, and severity-based output splitting}
  spec.description   = %q{Tracee is a simple extensible logger with stack tracing, benchmarking, preprocessing, and severity-based output splitting. Tracee is meant for development and debugging of any type of application or library, and compatible with Rails. The main reason of its existence is to help you see through a stack.}
  spec.homepage      = "https://github.com/tinbka/tracee"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  
  spec.add_dependency "colorize", ">= 0"
  spec.add_dependency "activesupport", ">= 3"
end
