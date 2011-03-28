module PgAuditLog
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def install
        directory "lib/tasks"
        copy_file "lib/tasks/pg_audit_log.rake", "lib/tasks/pg_audit_log.rake"
      end
    end
  end
end
