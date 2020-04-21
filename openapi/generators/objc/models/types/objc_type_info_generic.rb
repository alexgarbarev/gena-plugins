

class ObjcTypeInfoGeneric < ObjcTypeInfo

  attr_accessor :name

  def initialize(spec_property)
    self.name = spec_property.label.capitalize_first
  end

  def generic_name
    "Generic#{self.name}"
  end

  def declaration(header = true)
    header ? "#{generic_name} " : 'id'
  end

end