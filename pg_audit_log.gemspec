# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'pg_audit_log/version'

Gem::Specification.new do |s|
  s.name        = 'pg_audit_log'
  s.version     = PgAuditLog::VERSION
  s.authors     = ['Case Commons, LLC']
  s.email       = ['casecommons-dev@googlegroups.com']
  s.homepage    = 'https://github.com/Casecommons/pg_audit_log'
  s.summary     = %q{PostgreSQL-only database-level audit logging of all databases changes.}
  s.description = %q{A completely transparent audit logging component for your application using a stored procedure and triggers. Comes with specs for your project and a rake task to generate the reverse SQL to undo changes logged.}
  s.post_install_message = %q{Please run PgAuditLog::Function.install (in console/migration) to install the new versions of the database functions}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'rails', '~> 3.1'
  s.add_dependency 'pg', '>= 0.9.0'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'with_model', '>= 0.1.3'
end
