# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'pg_audit_log/version'

Gem::Specification.new do |spec|
  spec.name        = 'pg_audit_log'
  spec.version     = PgAuditLog::VERSION
  spec.authors     = ['Case Commons, LLC']
  spec.email       = ['casecommons-dev@googlegroups.com', 'andrew@johnandrewmarshall.com']
  spec.homepage    = 'https://github.com/Casecommons/pg_audit_log'
  spec.summary     = %q{PostgreSQL-only database-level audit logging of all databases changes.}
  spec.description = %q{A completely transparent audit logging component for your application using a stored procedure and triggers. Comes with specs for your project and a rake task to generate the reverse SQL to undo changes logged.}
  spec.license     = 'MIT'

  spec.post_install_message = %q{Please run PgAuditLog::Function.install (in console/migration) to install the new versions of the database functions}

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 4.2', '< 5.2'
  spec.add_dependency 'pg', '>= 0.9.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'with_model', '>= 0.1.3'
end
