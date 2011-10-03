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
end

