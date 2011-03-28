require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe PgAuditLog do
  describe "a model that is audited" do
    with_model :audited_model do
      table do |t|
        t.string :str
        t.text :txt
        t.integer :int
        t.date :date
        t.datetime :dt
        t.boolean :bool
      end
    end

    before do
      AuditedModel.connection.execute(<<-SQL)
            CREATE TRIGGER audit_audited_models
            AFTER INSERT OR UPDATE OR DELETE
            ON #{AuditedModel.quoted_table_name}
            FOR EACH ROW
              EXECUTE PROCEDURE audit_changes()
          SQL
    end

    after do
      AuditedModel.connection.execute("DROP TRIGGER audit_audited_models ON #{AuditedModel.quoted_table_name};")
      PgAuditLog::Entry.connection.execute("TRUNCATE #{PgAuditLog::Entry.quoted_table_name}")
    end

    let(:attributes) { { :str => "foo", :txt => "bar", :int => 5, :date => Date.today, :dt => Time.now.midnight } }

    context "on create" do

      before do
        AuditedModel.create!(attributes)
      end

      describe "the audit log record" do
        subject { PgAuditLog::Entry.last(:conditions => { :field_name => "str" }) }

        it { should be }
        its(:occurred_at) { should be }
        its(:table_name) { should == AuditedModel.table_name }
        its(:field_name) { should == "str" }
        its(:primary_key) { should == AuditedModel.last.id.to_s }
        its(:operation) { should == "INSERT" }

        context "when a user is present" do
          before do
            Thread.current[:current_user] = stub(:id => 1, :unique_name => "my current user")
            AuditedModel.create!
          end

          after { Thread.current[:current_user] = nil }

          its(:user_id) { should == 1 }
          its(:user_unique_name) { should == "my current user" }
        end

        context "when no user is present" do
          its(:user_id) { should == -1 }
          its(:user_unique_name) { should == "UNKNOWN" }
        end

        it "captures all new values for all fields" do
          attributes.each do |field_name, value|
            if field_name == :dt
              PgAuditLog::Entry.last(:conditions => { :field_name => field_name }).field_value_new.should == value.strftime("%Y-%m-%d %H:%M:%S")
            else
              PgAuditLog::Entry.last(:conditions => { :field_name => field_name }).field_value_new.should == value.to_s
            end
            PgAuditLog::Entry.last(:conditions => { :field_name => field_name }).field_value_old.should be_nil
          end
        end

      end
    end

    context "on update" do
      before do
        @model = AuditedModel.create!(attributes)
      end

      context "when going from a value to a another value" do
        before { @model.update_attributes!(:str => "bar") }
        subject { PgAuditLog::Entry.last(:conditions => { :field_name => "str" }) }

        its(:operation) { should == "UPDATE" }
        its(:field_value_new) { should == "bar" }
        its(:field_value_old) { should == "foo" }
      end

      context "when going from nil to a value" do
        let(:attributes) { {:txt => nil} }
        before { @model.update_attributes!(:txt => "baz") }
        subject { PgAuditLog::Entry.last(:conditions => { :field_name => "txt" }) }

        its(:field_value_new) { should == "baz" }
        its(:field_value_old) { should be_nil }
      end

      context "when going from a value to nil" do
        before { @model.update_attributes!(:str => nil) }
        subject { PgAuditLog::Entry.last(:conditions => { :field_name => "str" }) }

        its(:field_value_new) { should be_nil }
        its(:field_value_old) { should == "foo" }
      end

      context "when the value does not change" do
        before { @model.update_attributes!(:str => "foo") }
        subject { PgAuditLog::Entry.last(:conditions => { :field_name => "str", :operation => "UPDATE" }) }

        it { should_not be }
      end

      context "when the value is nil and does not change" do
        let(:attributes) { {:txt => nil} }
        before { @model.update_attributes!(:txt => nil) }
        subject { PgAuditLog::Entry.last(:conditions => { :field_name => "txt", :operation => "UPDATE" }) }

        it { should_not be }
      end

      context "when the value is a boolean" do

        context "going from nil -> true" do
          before { @model.update_attributes!(:bool => true) }
          subject { PgAuditLog::Entry.last(:conditions => { :field_name => "bool", :operation => "UPDATE" }) }

          its(:field_value_new) { should == "true" }
          its(:field_value_old) { should be_nil }
        end

        context "going from false -> true" do
          let(:attributes) { {:bool => false} }
          before do
            @model.update_attributes!(:bool => true)
          end
          subject { PgAuditLog::Entry.last(:conditions => { :field_name => "bool", :operation => "UPDATE" }) }

          its(:field_value_new) { should == "true" }
          its(:field_value_old) { should == "false" }
        end

        context "going from true -> false" do
          let(:attributes) { {:bool => true} }

          before do
            @model.update_attributes!(:bool => false)
          end
          subject { PgAuditLog::Entry.last(:conditions => { :field_name => "bool", :operation => "UPDATE" }) }

          its(:field_value_new) { should == "false" }
          its(:field_value_old) { should == "true" }
        end

      end
    end

    context "on delete" do
      before do
        @model = AuditedModel.create!(attributes)
        @model.delete
      end

      subject { PgAuditLog::Entry.last(:conditions => { :field_name => "str" }) }

      its(:operation) { should == "DELETE" }

      it "captures all new values for all fields" do
        attributes.each do |field_name, value|
          if field_name == :dt
            PgAuditLog::Entry.last(:conditions => { :field_name => field_name }).field_value_old.should == value.strftime("%Y-%m-%d %H:%M:%S")
          else
            PgAuditLog::Entry.last(:conditions => { :field_name => field_name }).field_value_old.should == value.to_s
          end
          PgAuditLog::Entry.last(:conditions => { :field_name => field_name }).field_value_new.should be_nil
        end
      end
    end
  end

end
