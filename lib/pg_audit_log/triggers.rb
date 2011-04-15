module PgAuditLog
  class Triggers < PgAuditLog::ActiveRecord
    class << self
      def tables
        connection.tables - (PgAuditLog::IGNORED_TABLES + [PgAuditLog::Entry.table_name])
      end

      def install
        tables.each do |table|
          create_for_table(table)
        end
      end

      def uninstall
        tables.each do |table|
          drop_for_table(table)
        end
      end

      def enable
        tables.each do |table|
          enable_for_table(table)
        end
      end

      def disable
        tables.each do |table|
          disable_for_table(table)
        end
      end

      def without_triggers
        begin
          disable
          yield
        ensure
          enable
        end
      end

      def create_for_table(table_name)
        execute <<-SQL
        CREATE TRIGGER audit_#{table_name}
        AFTER INSERT OR UPDATE OR DELETE
        ON #{table_name}
        FOR EACH ROW
        EXECUTE PROCEDURE audit_changes()
        SQL
      end

      def drop_for_table(table_name)
        execute "DROP TRIGGER #{trigger_name_for_table(table_name)} ON #{table_name}"
      end

      def enable_for_table(table_name)
        execute "ALTER TABLE #{table_name} DISABLE TRIGGER #{trigger_name_for_table(table_name)}"
      end

      def disable_for_table(table_name)
        execute "ALTER TABLE #{table_name} ENABLE TRIGGER #{trigger_name_for_table(table_name)}"
      end

      def trigger_name_for_table(table_name)
        "audit_#{table_name}"
      end
    end
  end
end
