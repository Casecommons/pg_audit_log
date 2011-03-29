module PgAuditLog
  class Triggers < ActiveRecord
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
        execute "DROP TRIGGER audit_#{table_name} ON #{table_name};"
      end

    end
  end
end
