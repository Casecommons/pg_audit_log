module PgAuditLog
  class Triggers < PgAuditLog::ActiveRecord
    class MissingTriggers < Exception
      def initialize(tables)
        @tables = tables
      end
      def message
        "Missing PgAuditLog triggers for the following tables: #{@tables.join(', ')}"
      end
    end

    class << self
      def tables
        connection.tables - (PgAuditLog::IGNORED_TABLES + [PgAuditLog::Entry.table_name])
      end

      def tables_without_triggers
        tables_with_triggers = connection.select_values <<-SQL
          SELECT tables.relname as table_name
          FROM pg_trigger triggers, pg_class tables
          WHERE triggers.tgrelid = tables.oid
          AND tables.relname !~ '^pg_'
          AND triggers.tgname LIKE '#{trigger_prefix}%'
        SQL
        tables - tables_with_triggers
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
        CREATE TRIGGER #{trigger_name_for_table(table_name)}
        AFTER INSERT OR UPDATE OR DELETE
        ON #{table_name}
        FOR EACH ROW
        EXECUTE PROCEDURE #{PgAuditLog::Function.name}()
        SQL
      end

      def drop_for_table(table_name)
        execute "DROP TRIGGER #{trigger_name_for_table(table_name)} ON #{table_name}"
      end

      def enable_for_table(table_name)
        execute "ALTER TABLE #{table_name} ENABLE TRIGGER #{trigger_name_for_table(table_name)}"
      end

      def disable_for_table(table_name)
        execute "ALTER TABLE #{table_name} DISABLE TRIGGER #{trigger_name_for_table(table_name)}"
      end

      def trigger_prefix
        "audit_"
      end

      def trigger_name_for_table(table_name)
        "#{trigger_prefix}#{table_name}"
      end
    end
  end
end
