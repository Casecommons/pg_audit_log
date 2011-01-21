module PgAuditLog
  module Generators
    class RSpecGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def install
        directory "spec/models"
        copy_file "spec/models/pg_audit_log_spec.rb", "spec/models/pg_audit_log_spec.rb"
      end
    end
  end
end
