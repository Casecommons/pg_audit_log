require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "the PostgreSQL database" do
  after do
    ActiveRecord::Base.connection.reconnect!
  end

  it "has an audit log table" do
    ActiveRecord::Base.connection.table_exists?('audit_log').should be_true
  end
end
