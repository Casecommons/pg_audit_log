module PgAuditLog
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def install
        directory "lib/tasks"
      end
    end
  end
end
