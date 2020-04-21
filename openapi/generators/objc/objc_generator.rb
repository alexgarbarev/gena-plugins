require_relative '../client_generator'
require_relative 'models/objc_api_client'
require_relative 'models/objc_model'
require_relative 'models/objc_enum'
require_relative '../../generators/objc/models/registry/objc_model_registry'

class ObjcConfig

  attr_accessor :naming_replacements, :paths
  attr_accessor :generic_tag
  attr_accessor :models

  def initialize(specification)
    name = api_name(specification)
    self.naming_replacements = load_config('naming_replacements')
    self.models = load_config('models')

    self.paths = {}
    load_config('paths').each do |key, value|
      components = value.split('/')
      components.insert(-2, name)
      self.paths[key] = components.join('/')
    end

    self.generic_tag = 'x-generic'
  end


  def load_config(name)
    JSON.parse(File.read(File.expand_path("#{__FILE__}/../config/#{name}.json")))
  end

end

class ObjcGenerator < ClientGenerator

  def initialize(specification, api_plugin)
    $plugin = api_plugin
    @specification = specification

    $objc_config = ObjcConfig.new(@specification)
  end

  def generate()

    $specification = @specification

    delete_xcode_paths

    endpoints = @specification.make_endpoints
    requests = generate_requests(endpoints)

    enums = @specification.find_enums
    models = @specification.models(enums)
    generate_models(models, enums)

    generate_client(requests)

    write_server_urls

    $specification = nil

  end

  def delete_xcode_paths
    $objc_config.paths.each do |key, value|
      Gena::XcodeUtils.shared.delete_path "Sources/#{value}"
    end
  end

  def generate_requests(endpoints)
    requests = []
    codegen = Gena::Codegen.new($objc_config.paths['requests'], {})

    endpoints.each do |endpoint|
      request = ObjcRequest.new(endpoint)
      request.render(codegen)
      requests << request
    end
    requests
  end

  def generate_models(models, enums)

    mapping_codegen = Gena::Codegen.new($objc_config.paths['mappers'], {})

    codegen = Gena::Codegen.new($objc_config.paths['models'], {})

    all_objects_for_imports = []

    models.each do |spec_model|
      model = ObjcModelRegistry.objc_model(spec_model)
      model.render(codegen)
      model.render_mapper(mapping_codegen)
      all_objects_for_imports << model
    end

    objc_enums = ObjcEnum.render(enums, codegen)

    # all_objects_for_imports += objc_enums
    # codegen.add_file('./code/header.h.liquid', "#{$plugin.config['prefix']}#{$plugin.plugin_config['prefix']}Models.h", Gena::Filetype::SOURCE, {'content' => imports(all_objects_for_imports, false, true)})

  end

  def generate_client(requests)
    codegen = Gena::Codegen.new($objc_config.paths['api_client'], {})

    client = ObjcApiClient.new(requests, @specification)
    client.render(codegen)

  end

  def write_server_urls

    envs = $plugin.plugin_config['envs']

    unless envs
      return
    end

    available_envs = $specification.raw['servers'].map {|item| item['x-env-name']}


    envs.each_key do |env_name|

      server = $specification.raw['servers'].first

      if available_envs.include? env_name
        server = $specification.raw['servers'].find {|item| item['x-env-name'] == env_name}
      end

      url = server['url']

      if url.include? 'http'
        path = envs[env_name]
        content = Plist::parse_xml(path)
        content[env_key($specification)] = server['url']
        File.open(path, 'w') {|f| f.write content.to_plist}
      else
        puts "Can't find server's url for #{$specification.name} client".red
      end
    end
  end


end
