require_relative 'objc_property'
require_relative 'types/objc_types'
require_relative 'objc_rest_client'

class ObjcRequest

  attr_accessor :name
  attr_accessor :descr
  attr_accessor :path
  attr_accessor :path_properties
  attr_accessor :body_properties
  attr_accessor :request_serialization
  attr_accessor :method
  attr_accessor :base_class

  attr_accessor :response_type
  attr_accessor :response_serialization

  def initialize(endpoint)


    self.name = endpoint.operation_id.capitalize_first
    if self.name.include? "_"
      self.name = self.name.camel_case
    end

    description = endpoint.raw['description']
    if description.nil? || description.length == 0
      description = endpoint.raw['summary']
    end
    self.descr = description

    self.path = endpoint.path.delete_first_if_matches('/')
    self.method = endpoint.method
    self.base_class = "#{$plugin.config['prefix']}Request"

    self.path_properties = endpoint.request_path_properties.map { |sp| ObjcProperty.new(sp) }


    request_properties, request_serialization = endpoint.request_body_properties

    self.body_properties = request_properties.map { |sp| ObjcProperty.new(sp) }
    self.request_serialization = serialization_from_mime(request_serialization)

    response_property, response_serialization = endpoint.response_property
    self.response_type = ObjcType.new(response_property)
    self.response_serialization = serialization_from_mime(response_serialization)
    self.adjust_response_type_for_serialization

  end


  def render(codegen)

    request_params = {
        'full_prefix' => common_prefix,
        'request_name' => "Request#{self.name}",
        'base_class' => self.base_class,
        'description' => self.descr,
        'path' => self.path,
        'http_method' => self.method.capitalize_first,
        'input_properties' => ObjcProperty.declarations(self.path_properties + self.body_properties),
        'path_params' => path_properties_composing,
        'imports' => imports(self.path_properties + self.body_properties + [self.response_type] + [self]),
        'request_body_serializarion' => self.request_serialization,
        'request_body' => self.request_body_code,
        'response_body' => self.response_body_code,
        'response_body_serialization' => self.response_serialization,
        'response_class' => self.response_type.declaration,
        'response_descr' => self.response_type.comment
    }

    group = self.path.split('/').first.capitalize_first

    base_path = "#{group}/#{self.name}/#{common_prefix}Request#{self.name}"

    codegen.add_file('../code/request.h.liquid', "#{base_path}.h", Gena::Filetype::SOURCE, request_params)
    codegen.add_file('../code/request.m.liquid', "#{base_path}.m", Gena::Filetype::SOURCE, request_params)


    request_schema = self.request_schema_content
    if request_schema
      codegen.add_file('../code/request.json.liquid', "#{base_path}.request.json", Gena::Filetype::RESOURCE, {'content' => request_schema})
    end

    path_schema = self.path_schema_content
    if path_schema
      codegen.add_file('../code/request.json.liquid', "#{base_path}.path.json", Gena::Filetype::RESOURCE, {'content' => path_schema})
    end

    response_schema = self.response_schema_content
    if response_schema
      codegen.add_file('../code/request.json.liquid', "#{base_path}.response.json", Gena::Filetype::RESOURCE, {'content' => response_schema})
    end
  end

  def input_properties
    self.body_properties + self.path_properties
  end

  def request_class
    "#{common_prefix}Request#{self.name.capitalize_first}"
  end

  ######### IMPORTS ########

  def import_headers
    ["#import \"#{self.base_class}.h\""]
  end

  ######### UTILS #########

  def serialization_from_mime(mime)

    unless mime
      return nil
    end

    case mime
      when 'application/json', 'text/json', 'text/javascript'
        return 'TRCSerializationJson'
      when 'application/x-plist'
        return 'TRCSerializationPlist'
      when 'multipart/form-data'
        return 'TRCSerializationRequestMultipart'
      else
        if mime.start_with?('image')
          return 'TRCSerializationResponseImage'
        elsif mime.start_with?('text')
          return 'TRCSerializationString'
        else
          # return 'TRCSerializationData'
          return 'TRCSerializationJson'
        end
    end
  end

  def adjust_response_type_for_serialization
    replacement = nil
    case self.response_serialization
      when 'TRCSerializationData'
        replacement = ObjcType.data
      when 'TRCSerializationString'
        replacement = ObjcType.string
      when 'TRCSerializationResponseImage'
        replacement = ObjcType.image
      else
        # no need to change
    end

    if replacement
      replacement.descr = self.response_type.descr
      replacement.example = self.response_type.example
      self.response_type = replacement
    end
  end

  def response_schema_content
    if self.response_type.info.generics.count > 0
      return nil
    end
    response_schema_content = nil
    response_schema_value = self.response_type.schema_value
    if response_schema_value
      response_schema_content = "{\n#{$schema_tab}\"{root}\": #{response_schema_value}\n}"
    end
    response_schema_content
  end

  def request_schema_content
    result = nil

    if self.body_properties.count == 1
      # Key is nil, then it's single root value
      first = self.body_properties.first
      if first.schema_key == nil
        result = "{\n#{$schema_tab}\"{root}\": #{first.type.schema_value}\n}"
      end
    end

    unless result
      lines = []
      self.body_properties.each do |p|
        if p.schema_key
          lines << p.schema_line
        end
      end
      result = "{\n#{lines.join(",\n")}\n}" if lines.count > 0
    end

    result
  end

  def path_schema_content
    if self.path_properties.count > 0
      lines = ObjcProperty.schema_lines(self.path_properties)
      if lines.length > 0
        return "{\n#{lines}\n}"
      end
    end
    return nil
  end

  def path_properties_composing
    return nil if self.path_properties.count == 0
    result = ''
    last_index = self.path_properties.count - 1
    self.path_properties.each_with_index do |property, index|
      result << "#{$code_tab}#{$code_tab}@\"#{property.schema_key}\" : #{property.compose_value('self')}"
      if index != last_index
        result << ",\n"
      end
    end
    result
  end

  ###### RESPONSE PARSING #######

  def response_body_code
    if self.response_type.info.generics.count > 0
      manual_parsing_code(self.response_type, 'responseBody', 'parseError')
    else
      "#{$code_tab}return responseBody;"
    end
  end

  def manual_parsing_code(type, response_object, error_object)
    lines = ["#{type.declaration}response = #{ObjcRestClient.parse_value(type, response_object, 'self.restClient', error_object)};"]

    lines.concat exit_if_error(error_object)
    lines.concat generics_parse('response', response_object, type, error_object)

    lines << 'return response;'
    lines.map! { |l| "#{$code_tab}#{l}" }
    lines.join("\n")
  end

  def generics_parse(instance, response_object, type, error_object)
    lines = []
    generics_hash = type.info.generics
    generics_hash.each do |property, subtype|
      response_object_with_key = "#{response_object}[@\"#{property.schema_key}\"]"
      instance_with_property = "#{instance}.#{property.name}"
      sub_lines = []

      sub_lines << "#{instance}.#{property.name} = #{ObjcRestClient.parse_value(subtype, response_object_with_key, 'self.restClient', error_object)};"
      sub_lines.concat exit_if_error(error_object)
      lines.concat validate_not_nil(property, response_object_with_key, error_object, sub_lines)
      lines.concat generics_parse(instance_with_property, response_object_with_key, subtype, error_object)
    end

    lines
  end

  def exit_if_error(error_object)
    lines = ["if (*#{error_object}) {"]
    lines << "#{$code_tab}return nil;"
    lines << '}'
    lines
  end

  def validate_not_nil(property, response_object, error_object, input_lines)
    lines = ["if (#{response_object} && ![#{response_object} isKindOfClass:[NSNull class]]) {"]
    lines.concat indent_code_lines(input_lines)
    if property.type.is_required
      lines << '} else {'
      key = response_object.scan(/\[@\"(.*?)\"\]/).join('.')
      lines << "#{$code_tab}*#{error_object} = [NSError errorWithDomain:@\"TyphoonRestClientErrors\" code:104 userInfo:@{ NSLocalizedDescriptionKey : @\"Can't find value for required key '#{key}'.\"];"
      lines << "#{$code_tab}return nil;"
      lines << '}'
    else
      lines << '}'
    end
    lines
  end

  ###### REQUEST COMPOSING #######

  def request_body_code

    if self.body_properties.count == 0
      return nil
    end

    #In case of single root property - use root mapper in schema
    if self.body_properties.count == 1
      first = self.body_properties.first
      if first.schema_key == nil
        return "#{$code_tab}return self.#{first.name};"
      end
    end

    has_root_properties = self.body_properties.find { |p| p.schema_key == nil }
    if has_root_properties
      result = "#{$code_tab}NSMutableDictionary *values = [#{self.composing_dictionary(self.body_properties)} mutableCopy];\n\n"
      self.body_properties.each do |prop|
        unless prop.schema_key
          result += "#{$code_tab}if (self.#{prop.name}) {\n"

          result += "#{$code_tab*2}NSDictionary *#{prop.name}Values = #{ObjcRestClient.compose_value(prop, prop.type, 'self', '[self restClient]', 'nil')};\n"
          result += "#{$code_tab*2}[values addEntriesFromDictionary:#{prop.name}Values];\n"
          result += "#{$code_tab}}\n"
        end
      end
      result += "#{$code_tab}return values;"
      return result

    else
      #In case of other properties
      result = "#{$code_tab}return #{self.composing_dictionary(self.body_properties)};"
      return result
    end

  end

  def composing_dictionary(properties)
    result = "@{\n"
    lines = []
    properties.each do |prop|
      lines << "@\"#{prop.schema_key}\": #{prop.compose_value('self')}" if prop.schema_key
    end
    result += indent_code_lines(lines, 2).join(",\n")
    result += "\n#{$code_tab}}"
    return result
  end

  ################################


end