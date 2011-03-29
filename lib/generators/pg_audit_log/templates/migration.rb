class InstallPgAuditLog < ActiveRecord::Migration

  def self.up
    PgAuditLog::Entry.install
    PgAuditLog::Function.install
    PgAuditLog::Triggers.install
  end

  def self.down
    PgAuditLog::Triggers.uninstall
    PgAuditLog::Function.uninstall
    PgAuditLog::Entry.uninstall
  end
end

