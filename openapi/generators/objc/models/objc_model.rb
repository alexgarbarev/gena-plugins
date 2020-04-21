require_relative 'objc_property'
require_relative 'registry/objc_classes_registry'

class ObjcModel

  attr_accessor :name
  attr_accessor :properties
  attr_accessor :base_class

  attr_accessor :should_generate_constructor

  @spec_properties = {}

  def initialize(spec_model)
    self.name = spec_model.name
    self.base_class = self.model_config['base'] || "#{$plugin.config['prefix']}NetModel"
    @spec_properties = spec_model.properties
  end

  def load_properties
    self.properties = @spec_properties.map { |p| ObjcProperty.new(p) }
    self.should_generate_constructor = (self.properties.count <= 4)
  end

  def model_config
    base_config = $objc_config.models['all'] || {}
    specific_config = $objc_config.models[model_class] || {}
    result = base_config.dup
    specific_config.each do |key, value|
      result[key] = value
    end
    result
  end

  def model_class
    class_name(self.name)
  end

  def generic_properties
    self.properties.find_all { |p| p.type.is_generic }
  end

  def render(codegen)
    class_name = class_name(self.name)

    config = model_config
    if config
      puts "Model config: #{config.inspect}"
    end

    model_params = {
        'model_class' => class_name(self.name),
        'model_base_class' => self.base_class,
        'properties' => ObjcProperty.declarations(self.properties),
        'imports' => imports(self, true),
        'constructor' => self.should_generate_constructor ? self.constructor_declaration : nil,
        'constructor_m' => self.should_generate_constructor ? self.constructor_definition : nil,
        'generics' => self.generics_declaration,
        'shared' => self.model_config['shared'],
        'id_property' => self.model_config['id'],
        'description' => self.description_method
    }

    ObjcClassRegistry.render(class_name) do
      codegen.add_file('../code/model.h.liquid', "#{self.name.capitalize_first}/#{class_name}.h", Gena::Filetype::SOURCE, model_params)
      codegen.add_file('../code/model.m.liquid', "#{self.name.capitalize_first}/#{class_name}.m", Gena::Filetype::SOURCE, model_params)
    end

  end

  def generics_declaration
    names = self.generic_properties.map { |p| p.type.info.generic_name }
    if names.count > 0
      "<#{names.join(', ')}>"
    else
      ''
    end
  end

  def constructor_declaration
    args = []

    self.properties.each do |property|
      args << "with#{property.name.capitalize_first}:(#{property.nullability} #{property.type.declaration})#{property.name}"
    end

    "+ (nonnull instancetype)#{args.join(' ')};"
  end

  def constructor_definition
    args = []
    self.properties.each do |property|
      args << "with#{property.name.capitalize_first}:(#{property.nullability} #{property.type.declaration(false)})#{property.name}"
    end

    method_definition = "+ (nonnull instancetype)#{args.join(' ')}\n{\n"

    method_definition += "#{$code_tab}#{self.model_class} *instance = [#{self.model_class} new];\n"
    self.properties.each do |prop|
      method_definition << "#{$code_tab}instance.#{prop.name} = #{prop.name};\n"
    end
    method_definition += "#{$code_tab}return instance;\n}"
    method_definition
  end

  def description_method
    result = "- (NSString *)description\n{\n"

    result += "#{$code_tab}NSMutableString *description = [NSMutableString stringWithFormat:@\"<%@: \", NSStringFromClass([self class])];\n"
    index = 0
    self.properties.each do |prop|
      prefix = index == 0 ? "" : ", "
      result += "#{$code_tab}[description appendFormat:@\"#{prefix}self.#{prop.name}=%@\", self.#{prop.name}];\n"
      index += 1
    end

    # [description appendFormat:@"self.states=%@", states];
    # [description appendFormat:@", self.kind=%@", self.kind];
    # [description appendFormat:@", self.uploadName=%@", self.uploadName];
    # [description appendFormat:@", self.extension=%@", self.extension];
    # [description appendFormat:@", self.mime=%@", self.mime];
    # [description appendFormat:@", self.filePath=%@", self.filePath];
    # [description appendFormat:@", self.originalImage=%@", self.originalImage];
    # [description appendString:@">"];
    result += "#{$code_tab}return description;\n"
    result += "}\n"
    result
  end

  ######### IMPORTS ########

  def import_headers
    result = []
    self.properties.each { |p| result.concat p.import_headers }
    result << "#import \"#{self.base_class}.h\""
    result
  end

  def import_classes
    result = []
    self.properties.each { |p| result.concat p.import_classes }
    result
  end

  ######### MAPPING ########

  def mapping_name
    self.name.capitalize_first
  end

  def mapping_tag
    "{#{self.name.underscore}}"
  end

  def response_mapping
    if self.model_config['shared']
      response_properties = self.properties.reject { |p| p.name == self.model_config['id'] }
      ObjcProperty.mapping_parsing(response_properties, 2)
    else
      ObjcProperty.mapping_parsing(self.properties)
    end
  end

  def id_schema_key
    if self.model_config['shared']
      property = self.properties.find { |p| p.name == self.model_config['id'] }
      unless property
        puts "Can't find property with name '#{self.model_config['id']}' for model #{self.model_class}. Properties: #{self.properties.map { |p| p.name }.join(', ')}'".red
        abort ''
      end
      property.schema_key
    end
  end

  def render_mapper(codegen)

    model_params = {
        'class_name' => class_name(self.name),
        'full_prefix' => "#{common_prefix}",
        'name' => "Mapping#{mapping_name}",
        'mapping_tag' => mapping_tag,
        'client_class' => client_class_name,
        'properties_parsing' => response_mapping,
        'properties_composing' => ObjcProperty.mapping_composing(self.properties),
        'shared' => self.model_config['shared'],
        'id_key' => id_schema_key
    }

    class_name = "#{common_prefix}Mapping#{mapping_name}"

    ObjcClassRegistry.render(class_name) do
      codegen.add_file('../code/mapping.h.liquid', "#{mapping_name}/#{class_name}.h", Gena::Filetype::SOURCE, model_params)
      codegen.add_file('../code/mapping.m.liquid', "#{mapping_name}/#{class_name}.m", Gena::Filetype::SOURCE, model_params)

      params = {
          'content' => "{\n#{ObjcProperty.schema_lines(self.properties)}\n}"
      }
      codegen.add_file('../code/request.json.liquid', "#{mapping_name}/#{class_name}.json", Gena::Filetype::RESOURCE, params)
    end

  end

end