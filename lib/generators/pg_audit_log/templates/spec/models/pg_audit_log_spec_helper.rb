module PgAuditLogSpecHelper
  EXCLUDED_CLASSES = [ActiveRecord::Base, PgAuditLog::Entry]
  EXCLUDED_COLUMNS = ["last_accessed_at"]

  def included(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def self.find_all_constants(constant)
      constant.constants.find_all.select do |constant|
        klass = constant.is_a?(String) ? constant.constantize : constant
        klass.respond_to?(:ancestors) &&
        klass.ancestors.include?(ActiveRecord::Base) &&
        !klass.abstract_class? &&
        !EXCLUDED_CLASSES.include?(klass)
      end.sort
    end

    def self.get_all_klasses
      return @all_klasses if @all_klasses
      @all_klasses ||= find_all_constants(Module).map(&:constantize)
    end
  end

  module InstanceMethods
    def get_data(column, format_without_timezone = false)
      case column.type
      when :boolean
        true
      when :date
        Date.parse("1/1/2000")
      when :datetime
        if format_without_timezone
          DateTime.parse("1/1/2000 1pm").utc.strftime("%Y-%m-%d %H:%M:%S")
        else
          DateTime.parse("1/1/2000 1pm").utc.to_s
        end
      when :integer
        7
      when :decimal
        "7.1234567891"
      when :float
        7.1234
      when :string
        if column.name == "type"
          "Object"
        else
          "Happy"
        end

      when :text
        "Happy text"
      else
        raise "I don't know how to make data for '#{column.type}'!"
      end
    end

    def get_diff_data(column, format_without_timezone = false)
      case column.type
      when :boolean
        false
      when :date
        Date.parse("12/1/2000")
      when :datetime
        if format_without_timezone
          DateTime.parse("12/1/2000 1pm").utc.strftime("%Y-%m-%d %H:%M:%S")
        else
          DateTime.parse("12/1/2000 1pm").utc.to_s
        end
      when :integer
        9
      when :decimal
        "9.1234567891"
      when :float
        9.1234
      when :string
        if column.name == "type"
          "Object"
        else
          "Sad"
        end
      when :text
        "Sad text"
      else
        raise "I don't know how to make data for '#{column.type}'!"
      end
    end

    def create_object_for_klass(klass, exclude_columns = [])
      exclude_columns = exclude_columns | EXCLUDED_COLUMNS

      object = klass.new
      columns = klass.columns.reject {|column| exclude_columns.include? column.name }
      columns.each do |column|
        object.send("#{column.name}=", get_data(column))
      end

      object.send(:create_without_callbacks)
      [object, columns]
    end
  end

end