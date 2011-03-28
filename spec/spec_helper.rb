require "bundler/setup"
require "pg_audit_log"
require "with_model"

connection = nil
begin
  ActiveRecord::Base.establish_connection(:adapter  => 'postgresql',
                                          :database => 'pg_audit_log_test',
                                          :min_messages => 'warning')
  connection = ActiveRecord::Base.connection
  connection.execute("SELECT 1")
rescue PGError => e
  puts "-" * 80
  puts "Unable to connect to database.  Please run:"
  puts
  puts "    createdb pg_audit_log_test"
  puts "-" * 80
  raise e
end

connection.execute("DROP TABLE IF EXISTS audit_log")

sql_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib", "generators", "pg_audit_log", "templates", "lib", "tasks", "pg_audit_log"))

["create_audit_changes.sql", "create_audit_log_table.sql"].each do |sql_file|
  begin
    connection.execute File.read(File.join(sql_path, sql_file))
  rescue => e
    puts "-" * 80
    puts "Unable to install #{sql_file}"
    puts "-" * 80
    raise e
  end
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.extend WithModel

  config.after(:each) do
    ActiveRecord::Base.connection.reconnect!
  end
end
