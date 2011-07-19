require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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

  describe ".tables_with_triggers" do
    before do
      PgAuditLog::Triggers.create_for_table(TableWithTriggers.table_name)
    end

    it "should return an array of all tables that do have an audit trigger installed" do
      PgAuditLog::Triggers.tables_with_triggers.should include(TableWithTriggers.table_name)
      PgAuditLog::Triggers.tables_with_triggers.should_not include(TableWithoutTriggers.table_name)
    end
  end

  describe ".tables_without_triggers" do
    before do
      PgAuditLog::Triggers.create_for_table(TableWithTriggers.table_name)
    end

    it "should return an array of all tables that do not have an audit trigger installed" do
      PgAuditLog::Triggers.tables_without_triggers.should_not include(TableWithTriggers.table_name)
      PgAuditLog::Triggers.tables_without_triggers.should include(TableWithoutTriggers.table_name)
    end
  end

  describe ".install" do
    it "should work" do
      ->{
        PgAuditLog::Triggers.install
      }.should_not raise_error
    end
  end

  context "when triggers are installed" do
    before do
      PgAuditLog::Triggers.create_for_table(TableWithTriggers.table_name)
    end

    describe ".uninstall" do
      it "should work" do
        ->{
          PgAuditLog::Triggers.uninstall
        }.should_not raise_error
      end
    end

    describe ".enable" do
      it "should not blow up" do
        ->{
          PgAuditLog::Triggers.enable
        }.should_not raise_error
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
        ->{
          PgAuditLog::Triggers.disable
        }.should_not raise_error
      end

      it "should not fire the audit" do
        PgAuditLog::Triggers.disable
        expect {
          TableWithTriggers.create!
        }.to_not change(PgAuditLog::Entry, :count)
      end
    end

  end


end

