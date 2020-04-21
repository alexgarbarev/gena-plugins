require_relative '../utils/objc_utils'


class ObjcEnum

  attr_accessor :name
  attr_accessor :values

  def self.new(*args)
    if args.count == 1
      enum = args.first
      instance = instance_for_type(enum.type)
      instance.name = enum.name
      instance.values = enum.values
      return instance
    else
      return super
    end
  end

  def self.instance_for_type(type)
    if type == 'string'
      ObjcStringEnum.new
    else
      ObjcNumberEnum.new
    end
  end

  def schema_value
    "\"#{values.join('|')}\""
  end

  def enum_declaration
    "#{self.enum_name} *"
  end

  def enum_name
    "#{common_prefix}Enum#{self.name.capitalize_first}"
  end

  def value_name(value)
    "#{value.to_s.camel_case.capitalize_first}"
  end

  def value_null_name
    "#{self.enum_name}Null"
  end

  def process_response(response_value)
    "[#{self.enum_name} valueFromResponseValue:#{response_value}]"
  end

  def compose_request(request_value)
    "[#{self.enum_name} requestValueFromValue:#{request_value}]"
  end

  def value_method_name(value)
    "_#{value.camel_case.lowercase_first}"
  end

  def value_object(value)
    "@\"#{value}\""
  end

  def render_declaration
    result = []
    result << "@interface #{self.enum_name} : CCEnum"
    self.values.each do |value|
      result << "+ (instancetype _Nonnull)#{value_method_name(value)};"
    end
    self.values.each do |value|
      result << "- (BOOL)is#{value_name(value)};"
    end
    result << "@end"
    return result.join("\n")
  end

  def render_definition
    result = []

    result << "@implementation #{self.enum_name}"
    result << "static NSDictionary *#{self.enum_name}Values;"
    result << "+ (void)load\n{"
    result << "#{$code_tab}#{self.enum_name}Values = @{"
    self.values.each do |value|
      result << "#{$code_tab*2}#{value_object(value)} : [[#{self.enum_name} alloc] initWithValue:#{value_object(value)}],"
    end
    result << "#{$code_tab}};\n}"

    self.values.each do |value|
      result << "+ (instancetype _Nonnull)#{value_method_name(value)}\n{"
      result << "#{$code_tab}return #{self.enum_name}Values[#{value_object(value)}];\n}"
    end
    self.values.each do |value|
      result << "- (BOOL)is#{value_name(value)}\n{"
      result << "#{$code_tab}return self == #{self.enum_name}.#{value_method_name(value)};\n}"
    end

    result << "+ (NSArray *)allOptions\n{\n#{$code_tab}return [#{self.enum_name}Values allValues];\n}"

    result << "+ (instancetype _Nullable)fromResponseValue:(id _Nullable)value\n{\n#{$code_tab}return value ? #{self.enum_name}Values[value] : nil;\n}"

    result << "@end"
    return result.join("\n")
  end

  def self.enum_header_name
    "#{$plugin.config['prefix']}#{$plugin.plugin_config['prefix']}#{$specification.name}Enums"
  end

  def self.render(enums, codegen)
    result = []
    decls = ''
    defs = ''
    enums.each do |enum|
      objc_enum = ObjcEnum.new(enum)
      decls += objc_enum.render_declaration + "\n\n\n"
      defs += objc_enum.render_definition + "\n\n\n"
      result << objc_enum
    end
    model_params = {
        'enum_type' => ObjcEnum.enum_header_name,
        'enum_decl' => decls,
        'enum_def' => defs,
    }
    codegen.add_file('../code/enum.h.liquid', "Enumerations/#{ObjcEnum.enum_header_name}.h", Gena::Filetype::SOURCE, model_params)
    codegen.add_file('../code/enum.m.liquid', "Enumerations/#{ObjcEnum.enum_header_name}.m", Gena::Filetype::SOURCE, model_params)
    result
  end

  ######### IMPORTS ########

  def import_headers
    ["#import \"#{ObjcEnum.enum_header_name}.h\""]
  end

 end

class ObjcNumberEnum < ObjcEnum

  def schema_value
    "42"
  end



  def value_method_name(value)
    "_#{value}"
  end

  def value_object(value)
    "@(#{value})"
  end
end

class ObjcStringEnum < ObjcEnum




end

