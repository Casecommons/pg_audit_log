namespace :pg_audit_log do
  IGNORED_TABLES = ["audit_log", "plugin_schema_migrations", "sessions", "schema_migrations"]

  desc "Install audit_log triggers on all tables"
  task :install => :environment do
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
    run_on(all_tables) do |table|
      "DROP TRIGGER audit_#{table} ON #{table};"
    end
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
    all_tables - IGNORED_TABLES
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
