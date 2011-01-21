class PgAuditLog::Entry < ActiveRecord::Base
  class CannotDeleteError < StandardError
    def message
      "Audit Logs cannot be deleted!"
    end
  end
  set_table_name :audit_log

  before_destroy do
    raise CannotDeleteError
  end

  class << self
    def delete(id)
      raise CannotDeleteError
    end

    def delete_all
      raise CannotDeleteError
    end
  end

end