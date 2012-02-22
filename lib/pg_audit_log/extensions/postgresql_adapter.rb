require "active_record/connection_adapters/postgresql_adapter"

# Did not want to reopen the class but sending an include seemingly is not working.
class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def drop_table_with_auditing(table_name, options = {})
    if PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.drop_for_table(table_name)
    end
    if ::ActiveRecord::VERSION::MAJOR == 3 && ::ActiveRecord::VERSION::MINOR >= 2
      drop_table_without_auditing(table_name)
    else
      drop_table_without_auditing(table_name, options)
    end
  end
  alias_method_chain :drop_table, :auditing

  def create_table_with_auditing(table_name, options = {}, &block)
    create_table_without_auditing(table_name, options, &block)
    unless options[:temporary] ||
      PgAuditLog::IGNORED_TABLES.include?(table_name) ||
      PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.create_for_table(table_name)
    end
  end
  alias_method_chain :create_table, :auditing

  def rename_table_with_auditing(table_name, new_name)
    rename_table_without_auditing(table_name, new_name)
    if PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.drop_for_table(table_name)
    end
    unless PgAuditLog::IGNORED_TABLES.include?(table_name) ||
      PgAuditLog::Triggers.tables_with_triggers.include?(new_name)
      PgAuditLog::Triggers.create_for_table(new_name)
    end
  end
  alias_method_chain :rename_table, :auditing

  def set_audit_user_id_and_name
    user_id, unique_name = user_id_and_name
    execute PgAuditLog::Function::user_identifier_temporary_function(user_id) unless @last_user_id && @last_user_id == user_id
    execute PgAuditLog::Function::user_unique_name_temporary_function(unique_name) unless @last_unique_name && @last_unique_name == unique_name
    @last_user_id = user_id
    @last_unique_name = unique_name
    true
  end

  def blank_audit_user_id_and_name
    execute 'DROP FUNCTION pg_temp.pg_audit_log_user_identifier()'
    execute 'DROP FUNCTION pg_temp.pg_audit_log_user_unique_name()'
    @last_user_id = @last_unique_name = nil
    true
  end

  def reconnect_with_pg_audit_log!
    reconnect_without_pg_audit_log!
    @last_user_id = @last_unique_name = nil
  end
  alias_method_chain :reconnect!, :pg_audit_log

  private

  def user_id_and_name
    current_user = Thread.current[:current_user]
    user_id = current_user.try(:id) || "-1"
    user_unique_name = current_user.try(:unique_name) || "UNKNOWN"
    return [user_id, user_unique_name]
  end

end

module ActiveRecord
  module ConnectionAdapters
    class ConnectionPool
      def release_connection_with_pg_audit_log(with_id = current_connection_id)
        conn = @reserved_connections.delete(with_id)
        conn.blank_audit_user_id_and_name
        checkin conn if conn
      end
      alias_method_chain :release_connection, :pg_audit_log
    end
  end

  class Base
    class << self
      def retrieve_connection_with_pg_audit_log
        conn = retrieve_connection_without_pg_audit_log
        conn.set_audit_user_id_and_name
        conn
      end
      alias_method_chain :retrieve_connection, :pg_audit_log
    end
  end
end
