
require_relative '../objc_type'
require_relative '../../models/objc_model'

# reference to the model
class ObjcTypeInfoModel < ObjcTypeInfo

  attr_accessor :model
  attr_accessor :generic_values #Hash (ObjcProperty => ObjcType)

  def initialize(spec_property, spec_model, generics)
    self.model = ObjcModelRegistry.objc_model(spec_model)
    self.generic_values = generics
  end

  def generics_declarations(header)
    result = ''

    if model.generic_properties.count > 0 && self.generic_values.count > 0
      values = model.generic_properties.map { |p| self.generic_values[p.name].declaration(header)}
      result = "<#{values.join(', ')}>"
    end
    result
  end

  def generics
    hash = {}
    if model.generic_properties.count > 0 && self.generic_values.count > 0
      model.generic_properties.each do |p|
        hash[p] = self.generic_values[p.name]
      end
    end
    hash
  end

  def declaration(header=true)
    "#{self.model.model_class}#{generics_declarations(header)} *"
  end

  def schema_value
    return "\"#{self.model.mapping_tag}\""
  end

  def import_classes
    result = [self.model.model_class]
    self.generic_values.each do |key, value|
      result.concat value.import_classes
    end
    result
  end

end