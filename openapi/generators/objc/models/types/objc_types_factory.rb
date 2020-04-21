require_relative 'objc_types'

require_relative '../../../../generators/objc/config/objc_value_transformers'
require_relative '../../../../generators/objc/models/registry/objc_model_registry'


class ObjcTypesFactory


  ### TODO: Rename property model to SchemaFragment
  def self.type_info(spec_property)


    # 1. Reference
    if spec_property.reference
      object = spec_property.load_reference($specification)
      if object.is_a? OpenApiParser::Specification::ModelObject
        return self.type_info_for_model(spec_property, object)
      elsif object.is_a? OpenApiParser::Specification::EnumObject
        return ObjcTypeInfoEnum.new(spec_property, object)
      else
        # TODO: Handle reference to array
        puts "Reference #{spec_property.reference}} to object #{object.inspect} is not handled".yellow
      end
    end

    # 2. Embedded (copy-pasted) enum in spec
    if spec_property.enum
      return ObjcTypeInfoEnum.new(spec_property, spec_property.as_enum)
    end

    if spec_property.format == $objc_config.generic_tag
      return ObjcTypeInfoGeneric.new(spec_property)
    end

    # 3. Value Transformers
    type = ObjcValueTransformers.type_info_for_property(spec_property)
    return type if type


    # 4. Primitives
    case spec_property.type
      when 'integer', 'long', 'float', 'number', 'boolean'
        return ObjcTypeInfoNumber.new(spec_property)
      when 'string'
        return ObjcTypeInfoString.new(spec_property)
      else
        puts "Unknown property: #{spec_property.inspect}".yellow
        return ObjcTypeInfoUnknown.new(spec_property)
    end

  end

  def self.type_info_for_model(spec_property, model)
    generics = {}
    spec_property.generic_properties.each do |key, value|
      generics[key] = ObjcType.new(value)
    end if spec_property.generic_properties
    return ObjcTypeInfoModel.new(spec_property, model, generics)
  end

end

class ObjcTypeInfoUnknown < ObjcTypeInfo

  def initialize(spec_property)

  end

  def declaration(header=true)
    'id '
  end

end