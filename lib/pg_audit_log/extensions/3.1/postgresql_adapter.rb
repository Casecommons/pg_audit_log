require "active_record/connection_adapters/postgresql_adapter"

# Did not want to reopen the class but sending an include seemingly is not working.
class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def generate_auditing_sql(sql)
    current_user = Thread.current[:current_user]
    user_unique_name = current_user.try(:unique_name) || "UNKNOWN"

    log_user_id = %[SET audit.user_id = #{current_user.try(:id) || "-1"}]
    log_user_unique_name = %[SET audit.user_unique_name = "#{user_unique_name}"]
    { :user_id => log_user_id, :unique_name => log_user_unique_name, :sql => sql }
  end

  def exec_query_with_auditing(sql, name = 'SQL', binds = [])
    audited_sql = generate_auditing_sql(sql)
    log(audited_sql.values.join("; "), name, binds) do
      exec_no_cache(audited_sql[:user_id], binds)
      exec_no_cache(audited_sql[:unique_name], binds)
      result = binds.empty? ? exec_no_cache(sql, binds) :
                              exec_cache(sql, binds)

      ret = ActiveRecord::Result.new(result.fields, result_as_array(result))
      result.clear
      return ret
    end
  end
  alias_method_chain :exec_query, :auditing

  def execute_with_auditing(sql, name = nil)
    log(generate_auditing_sql(sql), name) do
      @connection.async_exec(sql)
    end
  end
  alias_method_chain :execute, :auditing

  def begin_db_transaction
    execute_without_auditing "BEGIN"
  end

  # Commits a transaction.
  def commit_db_transaction
    execute_without_auditing "COMMIT"
  end

  # Aborts a transaction.
  def rollback_db_transaction
    execute_without_auditing "ROLLBACK"
  end

  def create_savepoint
    execute_without_auditing("SAVEPOINT #{current_savepoint_name}")
  end

  def rollback_to_savepoint
    execute_without_auditing("ROLLBACK TO SAVEPOINT #{current_savepoint_name}")
  end

  def release_savepoint
    execute_without_auditing("RELEASE SAVEPOINT #{current_savepoint_name}")
  end

  def drop_table_with_auditing(table_name, options = {})
    if PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.drop_for_table(table_name)
    end
    drop_table_without_auditing(table_name, options)
  end
  alias_method_chain :drop_table, :auditing

  def create_table_with_auditing(table_name, options = {}, &block)
    create_table_without_auditing(table_name, options, &block)
    unless PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.create_for_table(table_name)
    end
  end
  alias_method_chain :create_table, :auditing

  def rename_table_with_auditing(table_name, new_name)
    rename_table_without_auditing(table_name, new_name)
    if PgAuditLog::Triggers.tables_with_triggers.include?(table_name)
      PgAuditLog::Triggers.drop_for_table(table_name)
    end
    unless PgAuditLog::Triggers.tables_with_triggers.include?(new_name)
      PgAuditLog::Triggers.create_for_table(new_name)
    end
  end
  alias_method_chain :rename_table, :auditing

end

