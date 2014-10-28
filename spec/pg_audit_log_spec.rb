require 'spec_helper'

describe PgAuditLog do
  let(:connection) { ActiveRecord::Base.connection }

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

    with_model :audited_model_without_primary_key do
      table :id => false do |t|
        t.string :str
        t.text :txt
        t.integer :int
        t.date :date
        t.datetime :dt
        t.boolean :bool
      end
    end

    after do
      PgAuditLog::Entry.connection.execute("TRUNCATE #{PgAuditLog::Entry.quoted_table_name}")
    end

    let(:attributes) { { :str => 'foo', :txt => 'bar', :int => 5, :date => Date.current, :dt => Time.current.midnight } }

    describe "on create" do
      context "the audit log record with a primary key" do
        subject { PgAuditLog::Entry.where(:field_name => 'str').last }

        context "recording changes" do
          before do
            AuditedModel.create!(attributes)
          end

          it { should be }
          its(:occurred_at) { should be }
          its(:table_name) { should == AuditedModel.table_name }
          its(:field_name) { should == 'str' }
          its(:primary_key) { should == AuditedModel.last.id.to_s }
          its(:operation) { should == 'INSERT' }
        end

        context "when a user is present, having just been changed" do
          before do
            record = AuditedModel.new
            Thread.current[:current_user] = double('User', :id => 1, :unique_name => 'my current user')
            ActiveRecord::Persistence.instance_method(:save).bind(record).call # call save without transaction
          end

          after { Thread.current[:current_user] = nil }

          its(:user_id) { should == 1 }
          its(:user_unique_name) { should == 'my current user' }
        end

        context "when no user is present" do
          before { AuditedModel.create!(attributes) }

          its(:user_id) { should == -1 }
          its(:user_unique_name) { should == 'UNKNOWN' }
        end

        it "captures all new values for all fields" do
          AuditedModel.create!(attributes)

          attributes.each do |field_name, value|
            entry = PgAuditLog::Entry.where(:field_name => field_name).last
            if field_name == :dt
              entry.field_value_new.should == value.strftime("%Y-%m-%d %H:%M:%S")
            else
              entry.field_value_new.should == value.to_s
            end
            entry.field_value_old.should be_nil
          end
        end
      end

      context "the audit log record without a primary key" do
        before do
          AuditedModelWithoutPrimaryKey.create!(attributes)
        end

        subject { PgAuditLog::Entry.where(:field_name => 'str').last }

        it { should be }
        its(:field_name) { should == 'str' }
        its(:primary_key) { should be_nil }
      end
    end

    describe "on update" do
      context "the audit log record with a primary key" do
        before do
          @model = AuditedModel.create!(attributes)
        end

        context "when a user is present, having just been changed" do
          subject { PgAuditLog::Entry.where(:field_name => 'str').last }
          before do
            Thread.current[:current_user] = double('User', :id => 1, :unique_name => 'my current user')
            @model.str = 'foobarbaz'
            # @model.class.connection.execute "select * from #{AuditedModel.table_name}"
            ActiveRecord::Persistence.instance_method(:save).bind(@model).call # call save without transaction
          end
          after { Thread.current[:current_user] = nil }

          its(:user_id) { should == 1 }
          its(:user_unique_name) { should == 'my current user' }
        end

        context "when going from a value to a another value" do
          before { @model.update_attributes!(:str => 'bar') }
          subject { PgAuditLog::Entry.where(:field_name => 'str').last }

          its(:operation) { should == 'UPDATE' }
          its(:field_value_new) { should == 'bar' }
          its(:field_value_old) { should == 'foo' }
        end

        context "when going from nil to a value" do
          let(:attributes) { {:txt => nil} }
          before { @model.update_attributes!(:txt => 'baz') }
          subject { PgAuditLog::Entry.where(:field_name => 'txt').last }

          its(:field_value_new) { should == 'baz' }
          its(:field_value_old) { should be_nil }
        end

        context "when going from a value to nil" do
          before { @model.update_attributes!(:str => nil) }
          subject { PgAuditLog::Entry.where(:field_name => 'str').last }

          its(:field_value_new) { should be_nil }
          its(:field_value_old) { should == 'foo' }
        end

        context "when the value does not change" do
          before { @model.update_attributes!(:str => 'foo') }
          subject { PgAuditLog::Entry.where(:field_name => 'str', :operation => 'UPDATE').last }

          it { should_not be }
        end

        context "when the value is nil and does not change" do
          let(:attributes) { {:txt => nil} }
          before { @model.update_attributes!(:txt => nil) }
          subject { PgAuditLog::Entry.where(:field_name => 'txt', :operation => 'UPDATE').last }

          it { should_not be }
        end

        context "when the value is a boolean" do
          context "going from nil -> true" do
            before { @model.update_attributes!(:bool => true) }
            subject { PgAuditLog::Entry.where(:field_name => 'bool', :operation => 'UPDATE').last }

            its(:field_value_new) { should == 'true' }
            its(:field_value_old) { should be_nil }
          end

          context "going from false -> true" do
            let(:attributes) { {:bool => false} }
            before do
              @model.update_attributes!(:bool => true)
            end
            subject { PgAuditLog::Entry.where(:field_name => 'bool', :operation => 'UPDATE').last }

            its(:field_value_new) { should == 'true' }
            its(:field_value_old) { should == 'false' }
          end

          context "going from true -> false" do
            let(:attributes) { {:bool => true} }

            before do
              @model.update_attributes!(:bool => false)
            end
            subject { PgAuditLog::Entry.where(:field_name => 'bool', :operation => 'UPDATE').last }

            its(:field_value_new) { should == 'false' }
            its(:field_value_old) { should == 'true' }
          end
        end
      end

      context "the audit log record without a primary key" do
        before do
          AuditedModelWithoutPrimaryKey.create!(attributes)
          AuditedModelWithoutPrimaryKey.update_all(:str => 'bar')
        end

        subject { PgAuditLog::Entry.where(:field_name => 'str').last }

        its(:primary_key) { should be_nil }
      end
    end

    describe "on delete" do
      context "the audit log record with a primary key" do
        before do
          model = AuditedModel.create!(attributes)
          model.delete
        end

        subject { PgAuditLog::Entry.where(:field_name => 'str').last }

        its(:operation) { should == 'DELETE' }

        it "captures all new values for all fields" do
          attributes.each do |field_name, value|
            entry = PgAuditLog::Entry.where(:field_name => field_name).last
            if field_name == :dt
              entry.field_value_old.should == value.strftime('%Y-%m-%d %H:%M:%S')
            else
              entry.field_value_old.should == value.to_s
            end
            entry.field_value_new.should be_nil
          end
        end
      end

      it "records with the correct user after just changing the user" do
        record = AuditedModel.create!
        Thread.current[:current_user] = double('User', :id => 1, :unique_name => 'my current user')
        record.delete
        expect(PgAuditLog::Entry.order(:occurred_at).last.user_id).to eq 1
      end

      context "the audit log record without a primary key" do
        before do
          AuditedModelWithoutPrimaryKey.create!(attributes)
          AuditedModelWithoutPrimaryKey.delete_all
        end

        subject { PgAuditLog::Entry.where(:field_name => 'str').last }

        its(:primary_key) { should be_nil }
      end
    end

    describe "performance" do
      xit "should perform well" do
        require 'benchmark'
        results = Benchmark.measure do
          1000.times do
            AuditedModel.create!(attributes)
          end
        end
        puts results.real
        puts results.real / 1000.0
      end
    end
  end

  describe "during migrations" do
    before do
      connection.drop_table('test_table') rescue nil
      connection.drop_table('new_table') rescue nil
    end

    after do
      connection.drop_table('test_table') rescue nil
    end

    describe "when creating the table" do
      it "should automatically create the trigger" do
        PgAuditLog::Triggers.tables_with_triggers.should_not include('test_table')
        connection.create_table('test_table')
        PgAuditLog::Triggers.tables_with_triggers.should include('test_table')
      end
    end

    describe "when dropping the table" do
      it "should automatically drop the trigger" do
        connection.create_table('test_table')
        connection.drop_table('test_table')
        PgAuditLog::Triggers.tables_with_triggers.should_not include('test_table')
      end
    end

    describe "when renaming the table" do
      def trigger_names
        connection.select_values <<-SQL
          SELECT triggers.tgname as trigger_name
          FROM pg_trigger triggers
          WHERE triggers.tgname LIKE '#{PgAuditLog::Triggers.trigger_prefix}%'
        SQL
      end

      it "should automatically drop and create the trigger" do
        new_table_name = "new_table_#{Time.current.to_i}"
        connection.create_table('test_table')
        connection.rename_table('test_table', new_table_name)

        trigger_names.should_not include('audit_test_table')
        trigger_names.should include("audit_#{new_table_name}")
        PgAuditLog::Triggers.tables_with_triggers.should include(new_table_name)

        connection.drop_table(new_table_name) rescue nil
      end

      context "and the new table name is ignored on the ignore list" do
        it "should not create a new trigger" do
          PgAuditLog::IGNORED_TABLES << /ignored_table/
          new_table_name = "ignored_table_#{Time.current.to_i}"
          connection.create_table('ignored_table')
          connection.rename_table('ignored_table', new_table_name)

          trigger_names.should_not include('audit_ignored_table')
          trigger_names.should_not include("audit_#{new_table_name}")
          PgAuditLog::Triggers.tables_with_triggers.should_not include(new_table_name)

          connection.drop_table(new_table_name) rescue nil
        end
      end
    end
  end

  describe "temporary tables" do
    context "when creating them" do
      it "should be ignored" do
        connection.create_table('some_temp_table', :temporary => true)
        PgAuditLog::Triggers.tables_with_triggers.should_not include('some_temp_table')
        connection.drop_table('some_temp_table')
      end
    end

    context "when dropping them" do
      it "should be ignored" do
        connection.create_table('some_temp_table', :temporary => true)
        connection.drop_table('some_temp_table')
        PgAuditLog::Triggers.tables_with_triggers.should_not include('some_temp_table')
      end
    end
  end

  describe "when the function does not yet exist" do
    before do
      PgAuditLog::Function.uninstall
    end

    context "when creating a table" do
      it "should install the function then enable the trigger on the table" do
        connection.create_table('some_more_new_table')
        PgAuditLog::Triggers.tables_with_triggers.should include('some_more_new_table')
        connection.drop_table('some_more_new_table')
      end
    end
  end

  describe "when the entry table does not yet exist" do
    before do
      PgAuditLog::Entry.uninstall
    end

    context "when creating a table" do
      it "should install the entry table then enable the trigger on the table" do
        PgAuditLog::Entry.installed?.should be_false
        connection.create_table('another_table')
        PgAuditLog::Entry.installed?.should be_true
        connection.drop_table('another_table')
      end
    end
  end

  describe "ignored tables" do
    context "when creating one of those tables" do
      it "should not automatically create a trigger for it" do
        PgAuditLog::IGNORED_TABLES << 'ignored_table'
        connection.create_table('ignored_table')
        PgAuditLog::Triggers.tables_with_triggers.should_not include('ignored_table')
        connection.drop_table('ignored_table')
      end
    end

    context "when creating one of those tables that matches a regexp" do
      it "should not automatically create a trigger for it" do
        PgAuditLog::IGNORED_TABLES << /ignored_table/
        connection.create_table('second_ignored_table')
        PgAuditLog::Triggers.tables_with_triggers.should_not include('second_ignored_table')
        connection.drop_table('second_ignored_table')
      end
    end
  end
end
