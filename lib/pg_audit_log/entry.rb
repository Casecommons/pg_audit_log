class PgAuditLog::Entry < ActiveRecord::Base
  TABLE_NAME = "audit_log"
  set_table_name TABLE_NAME

  class CannotDeleteError < StandardError
    def message
      "Audit Logs cannot be deleted!"
    end
  end

  before_destroy do
    raise CannotDeleteError
  end

  class << self
    def installed?
      connection.tables.include?(self.table_name)
    end

    def install
      sql = <<-SQL
        CREATE SEQUENCE #{self.table_name}_id_seq
            START WITH 1
            INCREMENT BY 1;

        CREATE TABLE #{self.table_name} (
            id integer PRIMARY KEY DEFAULT nextval('#{self.table_name}_id_seq'),
            user_id integer,
            user_unique_name character varying(255),
            operation character varying(255),
            table_name character varying(255),
            field_name character varying(255),
            field_value_new text,
            field_value_old text,
            occurred_at timestamp without time zone,
            primary_key character varying(255)
        );

        ALTER SEQUENCE #{self.table_name}_id_seq OWNED BY #{self.table_name}.id;
      SQL
      connection.execute_without_auditing(sql)
    end

    def uninstall
      connection.execute("DROP TABLE IF EXISTS #{self.table_name}")
    end

    def delete(id)
      raise CannotDeleteError
    end

    def delete_all
      raise CannotDeleteError
    end
  end

end
