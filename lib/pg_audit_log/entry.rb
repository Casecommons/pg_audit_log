class PgAuditLog::Entry < ActiveRecord::Base
  TABLE_NAME = 'audit_log'.freeze
  self.table_name = TABLE_NAME

  class CannotDeleteError < StandardError
    def message
      'Audit Logs cannot be deleted!'
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
            id bigint PRIMARY KEY DEFAULT nextval('#{self.table_name}_id_seq'),
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

        CREATE OR REPLACE FUNCTION audit_log_insert_trigger()
        RETURNS TRIGGER AS $$
        DECLARE
          tablename TEXT;
          insert_sql TEXT;
          create_table_sql TEXT;
          month_start DATE;
          month_end DATE;
        BEGIN
          tablename := '#{self.table_name}_' || to_char(NEW.occurred_at, 'YYYYMM');
          insert_sql := 'INSERT INTO ' || tablename || ' VALUES($1.*)';
          EXECUTE insert_sql USING NEW;
          RETURN NULL;
        EXCEPTION
          WHEN null_value_not_allowed THEN
            RETURN NULL;
          WHEN undefined_table THEN
            EXECUTE 'SELECT to_char($1, ''YYYY-MM-01'')::DATE' INTO month_start USING NEW.occurred_at;
            EXECUTE 'SELECT ($1 +  INTERVAL ''1 MONTH'')' INTO month_end USING month_start;
            create_table_sql :=  'CREATE TABLE ' || tablename || ' ( CHECK ( date(occurred_at) >= DATE ''' || month_start || ''' AND date(occurred_at) < DATE ''' ||
              month_end || ''' ) ) INHERITS (#{self.table_name})';
            EXECUTE create_table_sql;
            EXECUTE 'CREATE INDEX ' || tablename || '_occurred_at ON ' || tablename || ' (date(occurred_at))';
            EXECUTE insert_sql USING NEW;
            RETURN NULL;
        END;
        $$
        LANGUAGE plpgsql;

        CREATE TRIGGER insert_audit_log_trigger
          BEFORE INSERT ON audit_log
          FOR EACH ROW EXECUTE PROCEDURE audit_log_insert_trigger();
      SQL
      connection.execute(sql)
    end

    def uninstall
      connection.execute("DROP TABLE IF EXISTS #{self.table_name} CASCADE")
    end

    def delete(id)
      raise CannotDeleteError
    end

    def delete_all
      raise CannotDeleteError
    end
  end
end
