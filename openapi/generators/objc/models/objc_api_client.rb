class ObjcApiClient

  attr_accessor :requests
  attr_accessor :specification

  attr_accessor :name
  attr_accessor :descr
  attr_accessor :version


  def initialize(requests, specification)
    self.requests = requests

    self.name = api_name(specification)
    self.descr = specification.raw['info']['description']
    self.version = specification.raw['info']['version']

  end


  def render(codegen)

    import_sources = []
    requests.each do |request|
      import_sources.concat request.input_properties
      import_sources << request.response_type
    end
    import_sources << self

    codegen.add_file('../code/client.h.liquid', "#{client_class_name}.h", Gena::Filetype::SOURCE, {
        'class_name' => client_class_name,
        'imports' => imports(import_sources, false, false),
        'name' => "#{self.name} (#{self.version})",
        'description' => self.descr,
        'header_methods' => method_declarations
    })
    codegen.add_file('../code/client.m.liquid', "#{client_class_name}.m", Gena::Filetype::SOURCE, {
        'class_name' => client_class_name,
        'imports_m' => imports(requests, false, true),
        'impl_methods' => method_definitions
    })

  end

  def import_classes
      [ "CCAPIClient" ]   # [ "#{$plugin.config['prefix']}#{$plugin.plugin_config['prefix']}Models"]
  end

  def method_declarations

    result = ''
    previous_root_path = nil

    self.requests.each do |request|

      root_path = request.path.split('/')[0]
      if root_path != previous_root_path
        result += "\n//-------------------------------------------------------------------------------------------\n"
        result += "#pragma mark - #{root_path}\n"
        result += "//-------------------------------------------------------------------------------------------\n\n"
        previous_root_path = root_path
      end

      result += "/**\n"
      result += " * #{request.descr}.\n"
      result += " *\n"
      result += " * #{request.method.upcase} #{request.path}.\n"
      result += " */\n"
      result += "#{method_signature(request)};\n\n"

    end

    result

  end

  def method_definitions
    result = ''


    self.requests.each do |request|
      result += "#{method_signature(request)}\n{\n"

      result += "#{$code_tab}#{request.request_class} *request = [#{request.request_class} new];\n"
      request.input_properties.each do |prop|
        result += "#{$code_tab}request.#{prop.name} = #{prop.name};\n"
      end
      result += "#{$code_tab}request.restClient = self.restClient;\n"

      result += "#{$code_tab}[self.restClient sendRequest:request completion:completion];\n"

      result += "}\n\n"

    end

    result += self.spec_info

    result
  end

  def method_signature(request)

    method_name = request.name.downcase_first.gsub('set', 'setup')

    input = ''

    request.input_properties.each_with_index do |prop, index|

      if prop.nil? || prop.name.nil? || prop.name.length == 0
        next
      end

      joint = index == 0 ? 'with' : ''
      property_label = index == 0 ? prop.name.capitalize_first : prop.name

      if index == 0
        lastWord = method_name.underscore.split('_').last
        argumentLastWord = prop.name.underscore.split('_').last
        if lastWord.downcase == argumentLastWord.downcase
          joint = ''
          property_label = ''
        end
      end
      input += "#{joint}#{property_label}:(#{prop.type.declaration})#{prop.name} "
    end
    if input.length > 1
      input = input.capitalize_first
    end

    completion = input.length == 0 ? 'WithCompletion' : 'completion'

    response_name = "response"

    "- (void)#{method_name}#{input}#{completion}:(void(^)(#{request.response_type.declaration}#{response_name}, NSError *error))completion"
  end

  def spec_info

    result = ''

    unless $specification.raw['servers'].empty?
      result += "+ (NSArray<CCAPIClientURL *> *)availableUrls\n{\n#{$code_tab}return @[\n"
      $specification.raw['servers'].each do |server|
        name = server['x-env-name'] ? "@\"#{server['x-env-name']}\"" : 'nil'
        descr = server['description'] ? "@\"#{server['description']}\"" : 'nil'
        url = server['url']
        unless url[-1] == '/'
          url << '/'
        end

        result += "#{$code_tab*2}[CCAPIClientURL withUrl:@\"#{url}\" name:#{name} description:#{descr}],\n"
      end
      result += "#{$code_tab}];\n}\n\n"
    end


    result += "+ (NSString *)name\n{\n#{$code_tab}return @\"#{api_name($specification)}\";\n}"



    result
  end

end