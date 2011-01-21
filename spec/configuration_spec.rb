require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "the PostgreSQL database" do
  after do
    ActiveRecord::Base.connection.reconnect!
  end

  it "allows custom class variables for audit" do
    lambda {
      ActiveRecord::Base.connection.execute('SET audit.test = 1')
    }.should_not raise_error(ActiveRecord::StatementInvalid), "Your postgres is not configured for auditing. See README.rdoc"
  end

  it "has an audit log table" do
    ActiveRecord::Base.connection.table_exists?("audit_log").should be_true
  end

end