# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-pghstore"
  s.version     = "0.1.2"
  s.authors     = ["WAKAYAMA Shirou"]
  s.email       = ["shirou.faw@gmail.com"]
  s.homepage    = "https://github.com/shirou/fluent-plugin-pghstore"
  s.summary     = %q{Output to PostgreSQL database which has a hstore extension}
  s.description = %q{Output to PostgreSQL database which has a hstore extension}

  s.rubyforge_project = "fluent-plugin-pghstore"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_development_dependency "fluentd"
  s.add_development_dependency "pg"
  s.add_runtime_dependency "fluentd"
  s.add_runtime_dependency "pg"
end
