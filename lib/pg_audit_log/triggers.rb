module PgAuditLog
  class Triggers < PgAuditLog::ActiveRecord
    class MissingTriggers < StandardError
      def initialize(tables)
        @tables = tables
      end
      def message
        "Missing PgAuditLog triggers for the following tables: #{@tables.join(', ')}"
      end
    end

    class << self
      def tables
        skip_tables = (PgAuditLog::IGNORED_TABLES + [PgAuditLog::Entry.table_name, /#{PgAuditLog::Entry.table_name}_[0-9]{6}/])
        connection.tables.reject do |table|
          skip_tables.include?(table) ||
            skip_tables.any? { |skip_table| skip_table =~ table if skip_table.is_a? Regexp }
        end
      end

      def tables_with_triggers
        connection.select_values <<-SQL
          SELECT tables.relname as table_name
          FROM pg_trigger triggers, pg_class tables
          WHERE triggers.tgrelid = tables.oid
          AND tables.relname !~ '^pg_'
          AND triggers.tgname LIKE '#{trigger_prefix}%'
        SQL
      end

      def tables_without_triggers
        tables - tables_with_triggers
      end

      def all_tables_without_triggers
        connection.tables - tables_with_triggers
      end

      def install
        tables.each do |table|
          create_for_table(table) unless tables_with_triggers.include?(table)
        end
      end

      def uninstall
        tables_with_triggers.each do |table|
          drop_for_table(table) if tables_with_triggers.include?(table)
        end
      end

      def enable
        connection.set_user_id(nil)
      end

      def disable
        connection.set_user_id(PgAuditLog::Function::DISABLED_USER)
      end

      def without_triggers
        disable
        yield
      ensure
        enable
      end

      def create_for_table(table_name)
        PgAuditLog::Entry.install unless PgAuditLog::Entry.installed?
        PgAuditLog::Function.install unless PgAuditLog::Function.installed?
        return if tables_with_triggers.include?(table_name)
        execute <<-SQL
          CREATE TRIGGER #{trigger_name_for_table(table_name)}
          AFTER INSERT OR UPDATE OR DELETE
          ON #{table_name}
          FOR EACH ROW
          EXECUTE PROCEDURE #{PgAuditLog::Function.name}()
        SQL
      end

      def drop_for_table(table_name)
        return unless tables_with_triggers.include?(table_name)
        execute "DROP TRIGGER #{trigger_name_for_table(table_name)} ON #{table_name}"
      end

      def enable_for_table(table_name)
        execute "ALTER TABLE #{table_name} ENABLE TRIGGER #{trigger_name_for_table(table_name)}"
      end

      def disable_for_table(table_name)
        execute "ALTER TABLE #{table_name} DISABLE TRIGGER #{trigger_name_for_table(table_name)}"
      end

      def trigger_prefix
        'audit_'
      end

      def trigger_name_for_table(table_name)
        "#{trigger_prefix}#{table_name}"
      end
    end
  end
end
