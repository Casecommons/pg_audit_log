require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "the connection adapter" do
  subject { ActiveRecord::Base.connection }

  it { should respond_to(:execute_without_auditing) }

  it "should work for both execute and execute_without_auditing" do
    subject.execute("SELECT 1 = 1")
    subject.execute_without_auditing("SELECT 1 = 1")
  end

end