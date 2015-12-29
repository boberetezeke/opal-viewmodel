# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opal/viewmodel/version'

Gem::Specification.new do |gem|
  gem.name          = 'opal-viewmodel'
  gem.version       = Opal::ViewModel::VERSION
  gem.authors       = ['Steve Tuckner']
  gem.email         = ['stevetuckner@gmail.com']
  gem.licenses      = ['MIT']
  gem.description   = %q{A simple functional UI framework}
  gem.summary       = %q{
                        This uses view model differencing to determine what
                        needs to be updated on the UI and encodes the
                        view state in the URL automatically.
                      }
  gem.homepage      = 'https://github.com/boberetezeke/opal-viewmodel'
  gem.rdoc_options << '--main' << 'README' <<
                      '--line-numbers' <<
                      '--include' << 'opal'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'opal', ['>= 0.5.0', '< 1.0.0']
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'opal-rspec'
end
