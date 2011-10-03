module PgAuditLog
  IGNORED_TABLES = ["plugin_schema_migrations", "sessions", "schema_migrations"]
end

require "active_record"
require "pg_audit_log/version"

case ::ActiveRecord::VERSION::MAJOR
when 3
  require "pg_audit_log/extensions/shared/postgresql_adapter.rb"
  if ::ActiveRecord::VERSION::MINOR == 0
    require "pg_audit_log/extensions/3.0/postgresql_adapter.rb"
  else
    require "pg_audit_log/extensions/3.1/postgresql_adapter.rb"
  end
else
  raise "ActiveRecord #{::ActiveRecord::VERSION::MAJOR}.x unsupported!"
end
require "pg_audit_log/active_record"
require "pg_audit_log/entry"
require "pg_audit_log/function"
require "pg_audit_log/triggers"

