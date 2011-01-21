require File.join(File.dirname(__FILE), "pg_audit_log_spec_helper")

describe PgAuditLog do
  include PgAuditLogSpecHelper

  describe "logging for all models" do
    get_all_klasses.each do |klass|
      it "logs inserts for #{klass} (#{klass.table_name})" do
        object, columns = create_object_for_klass(klass)

        log_entries = PgAuditLog::Entry.find :all, :conditions => {:table_name => klass.table_name, :operation => "INSERT"}
        columns.each do |column|
          selected_entries = log_entries.select {|entry| entry.field_name == column.name}

          selected_entries.size.should >= 1

          entry = selected_entries.detect {|entry| entry.primary_key == object.id.to_s}
          entry.field_value_old.should be_nil
          entry.field_value_new.should == get_data(column, true).to_s
        end

        log_entries.map(&:field_name).uniq.should =~ columns.map(&:name)
      end

      it "logs updates for #{klass}" do
        klass.delete_all
        klass.count.should == 0
        object, columns = create_object_for_klass(klass, [klass.primary_key, "type", "updated_at", "deleted_at"])
        object.reload # needed for Rails bug around create_without_callbacks + boolean value going from true to false
        columns.each do |column|
          object.send("#{column.name}=", get_diff_data(column))
        end

        object.send(:update_without_callbacks)
        log_entries = PgAuditLog::Entry.find :all, :conditions => ["table_name = ? AND operation = ? AND field_name != ?",  klass.table_name, "UPDATE", "updated_at"]
        columns.each do |column|
          selected_entries = log_entries.select {|entry| entry.field_name == column.name}

          selected_entries.size.should equal(1), "Expected to find entry for #{column.name} (#{column.type}) but found none!"

          entry = selected_entries.first
          entry.field_value_old.should == get_data(column, true).to_s
          entry.field_value_new.should == get_diff_data(column, true).to_s
        end

        log_entries.map(&:field_name).should =~ columns.map(&:name)
      end

      it "logs deletes for #{klass}" do
        object, columns = create_object_for_klass(klass)

        ActiveRecord::Base.connection.execute("DELETE FROM #{klass.quoted_table_name} WHERE #{klass.primary_key} = #{object.id}")

        log_entries = PgAuditLog::Entry.find :all, :conditions => {:table_name => klass.table_name, :operation => "DELETE"}
        columns.each do |column|
          next if column.name == "update_at"
          selected_entries = log_entries.select {|entry| entry.field_name == column.name}
          selected_entries.size.should equal(1), "Expected to find entry for #{column.name} (#{column.type}) but found none!"

          entry = selected_entries.first
          entry.field_value_old.should == get_data(column, true).to_s
          entry.field_value_new.should be_nil
        end

        log_entries.map(&:field_name).should =~ columns.map(&:name)
      end

    end

  end
end
