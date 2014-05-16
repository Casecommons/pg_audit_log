require 'spec_helper'

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

    context "new style" do
      it "escapes the email" do
        subject.should_not match('SET')

        subject.should match('FUNCTION')
        subject.should match("'o''connell@fred.com'::varchar")
      end
    end

    context "old style" do
      before do
        Rails = double
        Rails.stub_chain(:configuration, :pg_audit_log_old_style_user_id).and_return(true)
      end

      after { Object.send(:remove_const, :Rails) }

      it "escapes the email" do
        subject.should match('SET')
        subject.should match("'o''connell@fred.com'")

        subject.should_not match('FUNCTION')
        subject.should_not match("'o''connell@fred.com'::varchar")
      end
    end
  end
end
