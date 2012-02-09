require "active_record/connection_adapters/postgresql_adapter"

# Did not want to reopen the class but sending an include seemingly is not working.
class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def generate_auditing_sql(sql)
    user_id, unique_name = user_id_and_name
    log_user_id = PgAuditLog::Function.user_identifier_temporary_function(user_id)
    log_user_unique_name = PgAuditLog::Function.user_unique_name_temporary_function(unique_name)
    { :user_id => log_user_id, :unique_name => log_user_unique_name, :sql => sql }
  end

  def exec_query_with_auditing(sql, name = 'SQL', binds = [])
    audited_sql = generate_auditing_sql(sql)
    logged_sql = ENV["LOG_AUDIT_SQL"] ? audited_sql.values.join('; ') : sql
    log(logged_sql, name, binds) do
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
end

