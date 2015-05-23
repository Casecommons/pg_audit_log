require 'spec_helper'

describe PgAuditLog::Entry do
  subject { PgAuditLog::Entry.create! }

  describe ".delete" do
    it "blows up because deleting audit logs is not allowed" do
      expect { PgAuditLog::Entry.delete(subject.id) }.to raise_error(PgAuditLog::Entry::CannotDeleteError)
    end
  end

  describe ".delete_all" do
    it "blows up because deleting audit logs is not allowed" do
      expect { PgAuditLog::Entry.delete_all }.to raise_error(PgAuditLog::Entry::CannotDeleteError)
    end
  end

  describe "#destroy" do
    it "blows up because deleting audit logs is not allowed" do
      expect { subject.destroy }.to raise_error(PgAuditLog::Entry::CannotDeleteError)
    end
  end
end
