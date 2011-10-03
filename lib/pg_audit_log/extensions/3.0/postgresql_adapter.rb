require "active_record/connection_adapters/postgresql_adapter"

# Did not want to reopen the class but sending an include seemingly is not working.
class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def execute_with_auditing(sql, name = nil)
    user_id, unique_name = user_id_and_name
    log_user_id = PgAuditLog::Function.user_identifier_temporary_function(user_id)
    log_user_unique_name = PgAuditLog::Function.user_unique_name_temporary_function(unique_name)

    log([log_user_id, log_user_unique_name, sql].join("; "), name) do
      if @async
        @connection.async_exec(log_user_id)
        @connection.async_exec(log_user_unique_name)
        @connection.async_exec(sql)
      else
        @connection.exec(log_user_id)
        @connection.exec(log_user_unique_name)
        @connection.exec(sql)
      end
    end
  end

  alias_method_chain :execute, :auditing
end

