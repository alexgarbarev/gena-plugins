require_relative 'types/objc_types'

class ObjcType

  attr_accessor :info # [ObjcTypeInfo]

  attr_accessor :descr
  attr_accessor :example

  attr_accessor :is_required
  attr_accessor :is_array

  def initialize(spec_property)
    if spec_property
      self.is_required = spec_property.is_required
      self.is_array = spec_property.items != nil

      if spec_property.type == 'array' && !self.is_array
        puts "Array! #{spec_property.label}".red
        puts "P: #{spec_property.inspect}".red
      end

      self.descr = spec_property.descr
      self.example = spec_property.example

      property_for_info = self.is_array ? spec_property.items : spec_property
      self.info = ObjcTypesFactory.type_info(property_for_info)
    else
      self.info = ObjcTypeInfoUnknown.new(spec_property)
      self.descr = 'Unknown'
    end
  end

  def declaration(header = true)
    decl = self.info.declaration(header) || 'id '
    if self.is_array
      return "NSArray<#{decl}> *"
    end

    return decl
  end

  def schema_value
    value = info.schema_value
    if self.is_array
      value = "[ #{value} ]"
    end
    return value
  end

  def schema_object
    schema_object = "@#{info.schema_value}"
    if self.is_array
      schema_object = "@[#{schema_object}]"
    end
    return schema_object
  end

  def comment
    comment_lines = []
    comment_lines.push("#{self.descr}.") if self.descr
    comment_lines.push(self.info.comment) if self.info.comment

    if self.example
      comment_lines.push('Example:')
      comment_lines.push("#{self.example}")
    end

    comment = ''
    if comment_lines.length > 0
      comment = "/** \n"
      comment_lines.each do |line|
        comment << " * #{line}\n"
      end
      comment << ' */'
    end
    comment
  end

  def is_generic
    return self.info.is_a? ObjcTypeInfoGeneric
  end

  def is_primitive
    return self.info.is_a?(ObjcTypeInfoNumber) || self.info.is_a?(ObjcTypeInfoString)
  end

  ### Headers

  def import_headers
    unless self.info
      puts "!!! #{self.inspect}"
    end
    self.info.import_headers
  end

  def import_classes
    self.info.import_classes
  end

  #########

  def self.image
    type = ObjcType.new(nil)
    type.is_required = true
    type.is_array = false
    type.info = ObjcTypeInfoData.new
    type.info.declaration = 'UIImage *'
    type.info.schema_value = nil
    return type
  end

  def self.data
    type = ObjcType.new(nil)
    type.is_required = true
    type.is_array = false
    type.info = ObjcTypeInfoData.new
    type.info.declaration = 'NSData *'
    type.info.schema_value = nil
    return type
  end

  def self.string
    type = ObjcType.new(nil)
    type.is_required = true
    type.is_array = false
    type.info = ObjcTypeInfoData.new
    type.info.declaration = 'NSString *'
    type.info.schema_value = nil
    return type
  end

end


