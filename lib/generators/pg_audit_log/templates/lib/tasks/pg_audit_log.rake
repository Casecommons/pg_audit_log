namespace :pg_audit_log do
  desc "Install audit_log triggers on all tables"
  task :install => :environment do
    unless PgAuditLog::Entry.installed?
      puts "Creating #{PgAuditLog::Entry.table_name} table..."
      PgAuditLog::Entry.install
    end

    puts "Installing audit_changes() function..."
    PgAuditLog::Function.install

    puts "Installing all audit log triggers... "
    PgAuditLog::Triggers.install

    export_development_structure
  end

  desc "Uninstall audit log triggers on all tables"
  task :uninstall => :environment do
    puts "Dropping all audit_log triggers... "
    PgAuditLog::Triggers.uninstall

    puts "Uninstalling audit_changes() function..."
    PgAuditLog::Function.uninstall

    export_development_structure
  end

  desc "Check all tables that are missing triggers (fails if any are)"
  task :check => :environment do
    tables = PgAuditLog::Triggers.tables_without_triggers
    raise(PgAuditLog::Triggers::MissingTriggers, tables) if tables.any?
  end

  private

  def export_development_structure
    puts "Exporting development_structure.sql..."
    Rake::Task["db:structure:dump"].reenable
    Rake::Task["db:structure:dump"].invoke
  end
end
