# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-pghstore"
  s.version     = "0.2.9"
  s.authors     = ["WAKAYAMA Shirou"]
  s.email       = ["shirou.faw@gmail.com"]
  s.homepage    = "https://github.com/shirou/fluent-plugin-pghstore"
  s.summary     = %q{Output to PostgreSQL database which has a hstore extension}
  s.description = %q{Output to PostgreSQL database which has a hstore extension}
  s.license     = "Apache-2.0"

  s.rubyforge_project = "fluent-plugin-pghstore"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec", "~> 3.2.0"
  # s.add_runtime_dependency "rest-client"
  s.add_development_dependency "pg", "~> 0.18.1"
  s.add_development_dependency "rake", ">= 11.0"
  s.add_development_dependency "test-unit", "~> 3.1.0"
  s.add_runtime_dependency "fluentd", [">= 0.14.0", "< 2"]
#  s.add_runtime_dependency "pg", "~> 0.18.1"
end
