class String
  def underscore
    self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr("-", "_").
        downcase
  end
end

module Gena

  class Mapping < Plugin

    desc 'mapping CLASS_NAME', 'Generates model mapping for TyphoonRestClient'
    method_option :path, :aliases => '-p', :desc => 'Specifies custom subdirectory (i.e. scope)'
    method_option :with_request, :aliases => '-p', :desc => 'Adds stub for request composing, not only response parsing'
    method_option :name, :aliases => '-n', :desc => 'Specifies custom name for mapping'

    def mapping(class_name)

      @class_name = class_name

      name = options[:name] || class_name.gsub(config['prefix'], '')

      path = File.join(self.plugin_config['path'], options[:path] || '', name)

      puts "name: #{name}, path: #{path}"


      mapping = ''
      header_properties.each do |name|
        mapping << "    instance.#{name} = responseObject[@\"#{name.underscore}\"];\n"
      end
      composing = ''
      header_properties.each do |name|
        composing << "    requestDict[@\"#{name.underscore}\"] = ValueOrNull(object.#{name});\n"
      end

      params = {
          'properties_parsing' => mapping,
          'properties_composing' => composing,
          'class_name' => class_name,
          'mapping_tag' => "{#{name.underscore.gsub('_', '-')}}",
          'name' => name
      }
      if include_request?
        params['include_request'] = true
      end

      codegen = Codegen.new(path, params)


      file_name = "#{config['prefix']}#{name}Mapping"


      codegen.add_file('Code/mapping.h.liquid', "#{file_name}.h", Filetype::SOURCE)
      codegen.add_file('Code/mapping.m.liquid', "#{file_name}.m", Filetype::SOURCE)
      if include_request?
        codegen.add_file('Code/mapping.json.liquid', "#{file_name}.request.json", Filetype::RESOURCE)
      end
      codegen.add_file('Code/mapping.json.liquid', "#{file_name}.response.json", Filetype::RESOURCE)


    end

    no_tasks do

      def self.plugin_config_defaults
        {'path' => 'BusinessLogic/Network/Mappings'}
      end


      def class_name
        @class_name
      end

      def path_to_class_header
        sources_dir = self.config['sources_dir']
        source_path = `find ./#{sources_dir} -name "#{class_name}.h"`
        source_path.gsub!(/\s+/, ' ').strip!
        source_path
      end

      def header_content
        unless path_to_class_header
          return ''
        end
        content = IO.read(path_to_class_header)

        groups = content.match(/@interface\s*?#{class_name}.*?\n(.*)/m).captures

        groups.first
      end

      def header_properties
        header = header_content
        properties = []
        header.scan(/@property.*?(?<name>[\w]*);\n/m).each do |match|
          properties << match.first
        end
        return properties
      end

      def include_request?
        options[:with_request]
      end


    end

  end

end
