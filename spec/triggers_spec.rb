require 'spec_helper'

describe PgAuditLog::Triggers do
  before :each do
    PgAuditLog::Triggers.uninstall rescue nil
  end

  with_model :table_with_triggers do
    table {}
  end

  with_model :table_without_triggers do
    table {}
  end

  before do
    PgAuditLog::Triggers.drop_for_table(TableWithoutTriggers.table_name) rescue nil
  end

  describe ".tables" do
    subject { PgAuditLog::Triggers.tables }

    with_model :table_to_ignore do
      table {}
    end

    before do
      PgAuditLog::IGNORED_TABLES << /ignore/
    end

    it { is_expected.to include(TableWithTriggers.table_name) }
    it { is_expected.to include(TableWithoutTriggers.table_name) }
    it { is_expected.not_to include(PgAuditLog::Entry.table_name) }
    it { is_expected.not_to include(TableToIgnore.table_name) }
  end

  describe ".tables_with_triggers" do
    it "should return an array of all tables that do have an audit trigger installed" do
      expect(PgAuditLog::Triggers.tables_with_triggers).to include(TableWithTriggers.table_name)
      expect(PgAuditLog::Triggers.tables_with_triggers).not_to include(TableWithoutTriggers.table_name)
    end
  end

  describe ".tables_without_triggers" do
    it "should return an array of all tables that do not have an audit trigger installed" do
      expect(PgAuditLog::Triggers.tables_without_triggers).not_to include(TableWithTriggers.table_name)
      expect(PgAuditLog::Triggers.tables_without_triggers).to include(TableWithoutTriggers.table_name)
    end
  end

  context "when no triggers are installed" do
    before do
      PgAuditLog::Triggers.uninstall
    end

    describe ".install" do
      it "should work" do
        expect{
          PgAuditLog::Triggers.install
        }.not_to raise_error
      end
    end

    describe ".uninstall" do
      it "should work" do
        expect{
          PgAuditLog::Triggers.uninstall
        }.not_to raise_error
      end
    end

  end

  context "when triggers are installed" do
    describe ".install" do
      it "should work" do
        expect{
          PgAuditLog::Triggers.install
        }.not_to raise_error
      end
    end
    describe ".uninstall" do
      it "should work" do
        expect{
          PgAuditLog::Triggers.uninstall
        }.not_to raise_error
      end
    end

    describe ".enable" do
      it "should not blow up" do
        expect{
          PgAuditLog::Triggers.enable
        }.not_to raise_error
      end

      it "should fire the audit" do
        PgAuditLog::Triggers.enable
        expect {
          TableWithTriggers.create!
        }.to change(PgAuditLog::Entry, :count)
      end
    end

    describe ".disable" do
      it "should not blow up" do
        expect{
          PgAuditLog::Triggers.disable
        }.not_to raise_error
      end

      it "should not fire the audit" do
        PgAuditLog::Function.install

        PgAuditLog::Triggers.disable
        expect {
          TableWithTriggers.create!
        }.to_not change(PgAuditLog::Entry, :count)
      end
    end

    describe ".without_triggers" do
      it "should record the user correctly afterwards" do
        PgAuditLog::Triggers.without_triggers do
          expect {
            TableWithTriggers.create!
          }.to_not change(PgAuditLog::Entry, :count)
        end

        expect {
          TableWithTriggers.create!
        }.to change(PgAuditLog::Entry, :count)
        expect(PgAuditLog::Entry.last.user_id).to eq(-1)
      end
    end

    describe ".create_for_table" do
      context "for a table that already has a trigger" do
        it "should not blow up" do
          expect(PgAuditLog::Triggers.tables_with_triggers).to include(TableWithTriggers.table_name)
          expect{
            PgAuditLog::Triggers.create_for_table(TableWithTriggers.table_name)
          }.not_to raise_error
        end
      end
    end

    describe ".drop_for_table" do
      context "for a table that has no trigger" do
        it "should not blow up" do
          PgAuditLog::Triggers.drop_for_table(TableWithTriggers.table_name)
          expect{
            PgAuditLog::Triggers.drop_for_table(TableWithTriggers.table_name)
          }.not_to raise_error
        end
      end
    end
  end
end
