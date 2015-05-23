require 'spec_helper'

describe "the PostgreSQL database" do
  after do
    ActiveRecord::Base.connection.reconnect!
  end

  it "has an audit log table" do
    expect(ActiveRecord::Base.connection.table_exists?('audit_log')).to be_truthy
  end
end
