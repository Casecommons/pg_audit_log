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

  describe ".user_unique_name_temporary_function" do
    subject { PgAuditLog::Function.user_unique_name_temporary_function(email) }
    let(:email) { "o'connell@fred.com" }

    it "escapes the email" do
      subject.should match("'o''connell@fred.com'::varchar")
    end
  end
end
