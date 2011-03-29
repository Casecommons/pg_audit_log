module PgAuditLog
  module Generators
    class RSpecGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def install
        directory "spec/models"
      end
    end
  end
end
