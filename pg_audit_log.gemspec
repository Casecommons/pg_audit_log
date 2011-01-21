# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pg_audit_log/version"

Gem::Specification.new do |s|
  s.name        = "pg_audit_log"
  s.version     = PgAuditLog::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Case Commons, LLC"]
  s.email       = ["casecommons-dev@googlegroups.com"]
  s.homepage    = "https://github.com/Casecommons/pg_audit_log"
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("rails", ">=2.3")
  s.add_development_dependency('rspec')
  s.add_development_dependency('with_model')
end
