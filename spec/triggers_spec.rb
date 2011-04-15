require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe PgAuditLog::Triggers do
  before :each do
    PgAuditLog::Triggers.uninstall rescue nil
  end

  with_model :table_with_triggers do
    table {}
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
      PgAuditLog::Triggers.install
    end

    describe ".uninstall" do
      it "should work" do
        ->{
          PgAuditLog::Triggers.uninstall
        }.should_not raise_error
      end
    end

    describe ".enable" do
      it "should work" do
        ->{
          PgAuditLog::Triggers.enable
        }.should_not raise_error
      end
    end

    describe ".disable" do
      it "should work" do
        ->{
          PgAuditLog::Triggers.disable
        }.should_not raise_error
      end
    end

  end


end

