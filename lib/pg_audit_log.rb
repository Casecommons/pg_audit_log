module PgAuditLog
  IGNORED_TABLES = [
    'plugin_schema_migrations'.freeze,
    'sessions'.freeze,
    'schema_migrations'.freeze,
  ]
end

require 'active_record'
require 'pg_audit_log/version'

require 'pg_audit_log/extensions/postgresql_adapter.rb'
require 'pg_audit_log/active_record'
require 'pg_audit_log/entry'
require 'pg_audit_log/function'
require 'pg_audit_log/triggers'
