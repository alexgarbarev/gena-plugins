
require_relative '../utils/objc_utils'
require_relative 'objc_type'

class ObjcProperty


  attr_accessor :name
  attr_accessor :schema_key

  attr_accessor :type


  def initialize(spec_property)
    self.name = ivar_name(spec_property.label)
    self.schema_key = spec_property.key

    self.type = ObjcType.new(spec_property)
  end

  def nullability
    if self.type.info.is_pointer_type
      return self.type.is_required ? 'nonnull' : 'nullable'
    end
  end

  def declaration
    result = ''

    attributes = ['nonatomic']
    attributes << nullability
    attributes.compact!

    result << self.type.comment + "\n"
    result << "@property (#{attributes.join(', ')}) #{self.type.declaration}#{self.name};\n"
    result
  end

  def comment
    ''
  end

  def schema_line
    value = self.type.schema_value
    if value
      return "#{$schema_tab}\"#{self.schema_key}#{self.type.is_required ? '' : '{?}'}\": #{value}"
    end
    return nil
  end

  def compose_value(instance)
    return "ValueOrNull(#{self.type.info.compose_request("#{instance}.#{self.name}")})"
  end

  def parse_value(instance)
    return self.type.info.process_response("#{instance}[@\"#{self.schema_key}\"]")
  end

  ####### Headers

  def import_headers
    self.type.import_headers
  end

  def import_classes
    self.type.import_classes
  end

  ####### Handy class methods to handle collections

  def self.declarations(properties)
    return properties.map { |p| p.declaration }.join("\n")
  end

  def self.schema_lines(properties)
    lines = properties.map { |p| p.schema_line }
    return lines.compact.join(",\n")
  end

  def self.mapping_parsing(properties, indent_level = 1)
    lines = properties.map do |p|
      "#{$code_tab*indent_level}instance.#{p.name} = #{p.parse_value('responseObject')};"
    end
    lines.join("\n")
  end

  def self.mapping_composing(properties)

    lines = properties.map do |p|
      abort if p.schema_key == 'all'
      "#{$code_tab}requestDict[@\"#{p.schema_key}\"] = #{p.compose_value('object')};"
    end
    lines.join("\n")
  end

  #######

end