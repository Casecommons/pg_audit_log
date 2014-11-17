require "rails/generators/active_record"

module PgAuditLog
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend ::ActiveRecord::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def install
        migration_template "migration.rb", "db/migrate/install_pg_audit_log.rb"
      end

    end
  end
end
