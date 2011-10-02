require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe PgAuditLog::Function do
  describe ".installed?" do
    subject { PgAuditLog::Function.installed? }
    context "when it is not" do
      before do
        PgAuditLog::Function.uninstall
      end
      it { should be_false }
    end

    context "when it is" do
      before do
        PgAuditLog::Function.install
      end
      it { should be_true }
    end
  end
end
