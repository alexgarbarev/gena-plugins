module OpenApiParser
  module Specification
    class Root
      attr_reader :raw
      attr_accessor :name
      attr_accessor :prefix

      def initialize(raw)
        @raw = raw
      end

      def endpoint(path, request_method)
        uri = URI.parse(path)
        requested_path = uri.path.gsub(/\..+\z/, "")

        matching_path_details = @raw["paths"].detect do |path_name, path|
          requested_path =~ to_pattern(path_name) &&
              path.keys.any? { |method| matching_method?(method, request_method) }
        end
        return nil if matching_path_details.nil?

        matching_name, matching_path = matching_path_details

        method_details = matching_path.detect do |method, schema|
          matching_method?(method, request_method)
        end

        Endpoint.new(matching_name, method_details.first, method_details.last, self)
      rescue URI::InvalidURIError
        nil
      end

      # Find enums globally as they can be part of request, response, model or standalone component
      def find_enums
        output = []
        deep_find_enums(@raw, [], output)
        output
      end

      def deep_find_enums(obj, path = [], stack = [], output)
        key = 'enum'
        if obj.respond_to?(:key?) && obj.key?(key)

          enum_name = path.last
          if enum_name == 'items'
            enum_name = path[-2] #.singularize
          end
          # in case of request parameter
          if enum_name == 'schema'
            enum_name = stack[-3]['name']
          end
          enum_name = enum_name.capitalize_first

          already_declared_enum = output.find { |enum| enum.name == enum_name }
          if !already_declared_enum
            enum = EnumObject.new(enum_name, obj, self)
            output << enum
          else
            if already_declared_enum.values != obj[key]
              # Trying to create another name
              if path[-2] == 'properties' && path[0] == 'components' # If inside object, inside components
                model_name = path[-3]
                enum = EnumObject.new("#{model_name}Enum", obj, self)
                output << enum
              else
                puts "Found two enums with name '#{enum_name}', but different values:\n#{already_declared_enum.values} != #{obj[key]}".red
                puts "Path: #{path}"
                abort
              end
            end
          end

          return obj[key]
        elsif obj.respond_to?(:each)
          r = nil
          obj.find_all do |*a|
            deep_path = path.dup
            deep_stack = stack.dup
            if a.last.is_a? Array
              if a.last.count == 2
                deep_path << a.last.first
              end
            end

            deep_stack << a.last

            r = deep_find_enums(a.last, deep_path, deep_stack, output)
          end
          return r
        end
      end


      def make_endpoints

        endpoints = []

        unsupported_attr_keys = ["servers"]
        common_attr_keys = ["parameters", "servers", "summary"]

        @raw['paths'].each do |name, details|
          unless details.nil?

            common_content = {}
            common_keys = common_attr_keys & details.keys
            if common_keys.count > 0
              if (unsupported_attr_keys & common_keys).count > 0
                puts "#{unsupported_attr_keys & common_keys} are not supported yet. Skipping.".yellow
              end
              common_keys.each do |key|
                common_content[key] = details[key]
                details.delete(key)
              end
            end

            details.each do |method, content|

              begin
              # merging content with common_content
              content = common_content.merge(content)
              rescue => exception
                puts "Unable to merge #{method}: #{content} with #{common_content}"
              end

              endpoints << Endpoint.new(name, method, content, self)
            end
          end
        end

        endpoint_per_id = {}

        endpoints = endpoints.reject do |element|
          should_reject = false
          begin
            unless element.raw
              raise "Empty content"
            end
            unless element.raw['operationId']
              raise "OperationId is misssing"
            end

            if endpoint_per_id[element.raw['operationId']] != nil
              existing = endpoint_per_id[element.raw['operationId']]
              puts 'Duplicated operationId for two operations:'.red
              puts "-#{existing.operation_id}, #{existing.method}, #{existing.path}".red
              puts "-#{element.operation_id}, #{element.method}, #{element.path}\n".red

              should_reject = true
            end
            endpoint_per_id[element.raw['operationId']] = element
          rescue => exception
            puts "Exception: #{exception}\n#{{element.path => {element.method => element.raw}}.to_yaml}".red
            abort
          end
          should_reject
        end

        endpoints
      end

      def models(enums_array)

        enums_hash = Hash.new

        enums_array.each do |enum|
          enums_hash[enum.name] = enum
        end

        models = []
        @raw['components']['schemas'].each do |name, content|
          if content['type'] == 'object' || content['allOf']
            models << ModelObject.new(name, content, self)
          end
          if content['type'] == 'array'
            puts "Standalone arrays are not supported in components! Found: #{content}".red
            abort('')
          end
        end

        models.each do |model|
          model.add_references_to_enums(enums_hash)
        end

        return models
      end

      def schema_at_ref(ref)

        components = ref.split('/')

        if components[0] != '#'
          abort('References to documents other than current are not supported yet')
        end
        # Skip document reference..
        components = components[1..-1]

        ref = @raw

        (0...components.count).each do |index|
          ref = ref[components[index]]
        end

        ref
      end

      def to_json
        JSON.generate(@raw)
      end

      private

      def matching_method?(method, request_method)
        method.to_s == request_method.downcase
      end

      def to_pattern(path_name)
        Regexp.new("\\A" + path_name.gsub(/\{[^}]+\}/, "[^/]+") + "\\z")
      end
    end
  end
end
