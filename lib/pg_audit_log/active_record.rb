module PgAuditLog
  class ActiveRecord
    class << self
      private

      def connection
        ::ActiveRecord::Base.connection
      end

      def execute(sql)
        connection.execute(sql)
      end
    end
  end
end
