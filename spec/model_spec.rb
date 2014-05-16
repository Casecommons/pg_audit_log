require 'spec_helper'

describe PgAuditLog::Entry do
  subject { PgAuditLog::Entry.create! }

  describe ".delete" do
    it "blows up because deleting audit logs is not allowed" do
      proc { PgAuditLog::Entry.delete(subject.id) }.should raise_error(PgAuditLog::Entry::CannotDeleteError)
    end
  end

  describe ".delete_all" do
    it "blows up because deleting audit logs is not allowed" do
      proc { PgAuditLog::Entry.delete_all }.should raise_error(PgAuditLog::Entry::CannotDeleteError)
    end
  end

  describe "#destroy" do
    it "blows up because deleting audit logs is not allowed" do
      proc { subject.destroy }.should raise_error(PgAuditLog::Entry::CannotDeleteError)
    end
  end
end
