module PgAuditLog
  IGNORED_TABLES = ["plugin_schema_migrations", "sessions", "schema_migrations"]
end

require "active_record"
require "pg_audit_log/version"

raise "ActiveRecord #{::ActiveRecord::VERSION::MAJOR}.x unsupported!" unless [3, 4].include?(::ActiveRecord::VERSION::MAJOR)

require "pg_audit_log/extensions/postgresql_adapter.rb"
require "pg_audit_log/active_record"
require "pg_audit_log/entry"
require "pg_audit_log/function"
require "pg_audit_log/triggers"

