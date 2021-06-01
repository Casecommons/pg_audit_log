require 'active_record/connection_adapters/postgresql_adapter'

# Did not want to reopen the class but sending an include seemingly is not working.
class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def drop_table_with_auditing(table_name)
    if PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.drop_for_table(table_name)
    end
    drop_table_without_auditing(table_name)
  end
  alias_method :drop_table_without_auditing, :drop_table
  alias_method :drop_table, :drop_table_with_auditing

  def create_table_with_auditing(table_name, options = {}, &block)
    create_table_without_auditing(table_name, options, &block)
    unless options[:temporary] ||
        PgAuditLog::IGNORED_TABLES.include?(table_name) ||
        PgAuditLog::IGNORED_TABLES.any? { |table| table =~ table_name if table.is_a? Regexp } ||
        PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.create_for_table(table_name)
    end
  end
  alias_method :create_table_without_auditing, :create_table
  alias_method :create_table, :create_table_with_auditing

  def rename_table_with_auditing(table_name, new_name)
    if PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.drop_for_table(table_name)
    end
    rename_table_without_auditing(table_name, new_name)
    unless PgAuditLog::IGNORED_TABLES.include?(table_name) ||
        PgAuditLog::IGNORED_TABLES.any? { |table| table =~ table_name if table.is_a? Regexp } ||
        PgAuditLog::Triggers.tables_with_triggers.include?(new_name)
      PgAuditLog::Triggers.create_for_table(new_name)
    end
  end
  alias_method :rename_table_without_auditing, :rename_table
  alias_method :rename_table, :rename_table_with_auditing

  def set_audit_user_id_and_name
    user_id, unique_name = user_id_and_name
    return true if (@last_user_id && @last_user_id == user_id) && (@last_unique_name && @last_unique_name == unique_name)

    execute_without_pg_audit_log PgAuditLog::Function::user_identifier_temporary_function(user_id)
    execute_without_pg_audit_log PgAuditLog::Function::user_unique_name_temporary_function(unique_name)
    @last_user_id = user_id
    @last_unique_name = unique_name

    true
  end

  def set_user_id(user_id = nil)
    execute_without_pg_audit_log PgAuditLog::Function::user_identifier_temporary_function(user_id || @last_user_id)
  end

  def blank_audit_user_id_and_name
    @last_user_id = @last_unique_name = nil
    true
  end

  def reconnect_with_pg_audit_log!
    reconnect_without_pg_audit_log!
    @last_user_id = @last_unique_name = nil
  end
  alias_method :reconnect_without_pg_audit_log!, :reconnect!
  alias_method :reconnect!, :reconnect_with_pg_audit_log!

  def execute_with_pg_audit_log(sql, name = nil)
    set_audit_user_id_and_name
    conn = execute_without_pg_audit_log(sql, name = nil)
    conn
  end
  alias_method :execute_without_pg_audit_log, :execute
  alias_method :execute, :execute_with_pg_audit_log

  def exec_query_with_pg_audit_log(*args, &block)
    set_audit_user_id_and_name
    conn = exec_query_without_pg_audit_log(*args, &block)
    conn
  end
  alias_method :exec_query_without_pg_audit_log, :exec_query
  alias_method :exec_query, :exec_query_with_pg_audit_log

  def exec_update_with_pg_audit_log(*args, &block)
    set_audit_user_id_and_name
    conn = exec_update_without_pg_audit_log(*args, &block)
    conn
  end
  alias_method :exec_update_without_pg_audit_log, :exec_update
  alias_method :exec_update, :exec_update_with_pg_audit_log

  def exec_delete_with_pg_audit_log(*args, &block)
    set_audit_user_id_and_name
    conn = exec_delete_without_pg_audit_log(*args, &block)
    conn
  end
  alias_method :exec_delete_without_pg_audit_log, :exec_delete
  alias_method :exec_delete, :exec_delete_with_pg_audit_log

  private

  def user_id_and_name
    current_user = Thread.current[:current_user]
    user_id = current_user.try(:id) || "-1"
    user_unique_name = current_user.try(:unique_name) || "UNKNOWN"
    return [user_id, user_unique_name]
  end
end
