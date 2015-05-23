require 'spec_helper'

describe PgAuditLog::Function do
  describe ".installed?" do
    subject { PgAuditLog::Function.installed? }
    context "when it is not" do
      before do
        PgAuditLog::Function.uninstall
      end

      it { is_expected.to be_falsey }
    end

    context "when it is" do
      before do
        PgAuditLog::Function.install
      end

      it { is_expected.to be_truthy }
    end
  end

  describe ".user_unique_name_temporary_function" do
    subject { PgAuditLog::Function.user_unique_name_temporary_function(email) }
    let(:email) { "o'connell@fred.com" }

    context "new style" do
      it "escapes the email" do
        expect(subject).not_to match('SET')

        expect(subject).to match('FUNCTION')
        expect(subject).to match("'o''connell@fred.com'::varchar")
      end
    end

    context "old style" do
      before do
        Rails = double
        allow(Rails).to receive_message_chain(:configuration, :pg_audit_log_old_style_user_id).and_return(true)
      end

      after { Object.send(:remove_const, :Rails) }

      it "escapes the email" do
        expect(subject).to match('SET')
        expect(subject).to match("'o''connell@fred.com'")

        expect(subject).not_to match('FUNCTION')
        expect(subject).not_to match("'o''connell@fred.com'::varchar")
      end
    end
  end
end
