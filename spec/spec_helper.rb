require 'bundler'
Bundler.setup

require 'pg_audit_log'
require 'with_model'

connection = nil
begin
  ActiveRecord::Base.establish_connection({
    :adapter  => 'postgresql',
    :database => 'pg_audit_log_test',
    :min_messages => 'warning',
  })
  connection = ActiveRecord::Base.connection
  connection.execute('SELECT 1')
rescue PGError => e
  puts '-' * 80
  puts 'Unable to connect to database.  Please run:'
  puts
  puts '    createdb pg_audit_log_test'
  puts '-' * 80
  raise e
end

ActiveRecord::Base.default_timezone = :local

RSpec.configure do |config|
  config.mock_with :rspec
  config.extend WithModel

  config.before(:each) do
    PgAuditLog::Entry.uninstall rescue nil
    connection.tables.each do |table|
      connection.drop_table_without_auditing(table)
    end
    PgAuditLog::Triggers.uninstall rescue nil
    PgAuditLog::Entry.uninstall
    PgAuditLog::Entry.install
    PgAuditLog::Function.install
  end

  config.after(:each) do
    ActiveRecord::Base.connection.reconnect!
  end
end
