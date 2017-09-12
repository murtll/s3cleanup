# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 's3cleanup'
  spec.version       = '0.1.0'
  spec.authors       = ['Dmitry Shmelev']
  spec.email         = ['dmitry.shmelev@default.com']

  spec.summary       = 's3 cleanup'
  spec.description   = 's3 cleanup.'
  spec.homepage      = 'https://www.onetwotrip.com'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = 'run'
  spec.require_paths = ['lib']
end
