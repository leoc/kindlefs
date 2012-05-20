# -*- encoding: utf-8 -*-
require File.expand_path('../lib/kindlefs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Arthur Andersen"]
  gem.email         = ["leoc.git@gmail.com"]
  gem.description   = %q{KindleFS mounts the collection information of a Kindle device as file system in user space via the Rindle gem.}
  gem.summary       = %q{Mount Kindle via Rindle.}
  gem.homepage      = "https://github.com/leoc/kindlefs"

  gem.files         = `git ls-files`.split("\n")
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "kindlefs"
  gem.require_paths = ["lib"]
  gem.version       = KindleFS::VERSION

  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_dependency 'rfusefs'
  gem.add_dependency 'rindle'
end
