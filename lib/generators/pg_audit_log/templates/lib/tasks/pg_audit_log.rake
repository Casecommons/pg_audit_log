namespace :pg_audit_log do
  IGNORED_TABLES = ["plugin_schema_migrations", "sessions", "schema_migrations"]

  desc "Install audit_log triggers on all tables"
  task :install => :environment do
    unless all_tables.include?(PgAuditLog::Entry.table_name)
      puts "Creating #{PgAuditLog::Entry.table_name} table..."
      sql = File.read(File.join(sql_path, "create_audit_log_table.sql"))
      connection.execute_without_auditing(sql)
    end
    puts "Installing audit_changes() function..."
    sql = File.read(File.join(sql_path, "create_audit_changes.sql"))
    connection.execute_without_auditing(sql)

    puts "Installing all audit log triggers... "
    run_on(audit_log_tables) do |table|
      <<-SQL
        CREATE TRIGGER audit_#{table}
        AFTER INSERT OR UPDATE OR DELETE
        ON #{table}
        FOR EACH ROW
          EXECUTE PROCEDURE audit_changes()
      SQL
    end
    puts "Exporting development_structure.sql..."
    Rake::Task["db:structure:dump"].reenable
    Rake::Task["db:structure:dump"].invoke
  end

  desc "Uninstall audit log triggers on all tables"
  task :uninstall => :environment do
    puts "Dropping all audit_log triggers... "
    run_on(audit_log_tables) do |table|
      "DROP TRIGGER audit_#{table} ON #{table};"
    end
    puts "Uninstalling audit_changes() function..."
    sql = File.read(File.join(sql_path, "uninstall_audit_changes.sql"))
    connection.execute_without_auditing(sql)

    puts "Exporting development_structure.sql..."
    Rake::Task["db:structure:dump"].reenable
    Rake::Task["db:structure:dump"].invoke
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  def all_tables
    connection.tables
  end

  def audit_log_tables
    all_tables - (IGNORED_TABLES + [PgAuditLog::Entry.table_name])
  end

  def sql_path
    Rails.root.join("lib/tasks/pg_audit_log")
  end

  def run_on(tables, &block)
    tables.sort.each do |table|
      puts "* #{table}"
      sql = yield(table)
      begin
        connection.execute_without_auditing(sql)
      rescue => e
        puts e.to_s
        connection.reconnect!
      end
    end
  end

end
