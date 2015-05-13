require "rails/generators/active_record"

module PgAuditLog
  module Generators
    class InstallGenerator < ::ActiveRecord::Generators::Base
      # ActiveRecord::Generators::Base inherits from Rails::Generators::NamedBase which requires a NAME parameter for the
      # new table name. Our generator doesn't require a name, so we just set a random name here.
      argument :name, type: :string, default: "random_name"
      
      source_root File.expand_path('../templates', __FILE__)

      def install
        directory "lib/tasks"
        migration_template "migration.rb", "db/migrate/install_pg_audit_log.rb"
      end
    end
  end
end
