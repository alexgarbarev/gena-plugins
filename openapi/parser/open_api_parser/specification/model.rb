module OpenApiParser
  module Specification

    class ModelProperty

      attr_accessor :raw

      attr_accessor :key
      attr_accessor :label

      attr_accessor :type
      attr_accessor :is_required
      attr_accessor :descr
      attr_accessor :example
      attr_accessor :enum
      attr_accessor :format
      attr_accessor :items

      attr_accessor :reference

      attr_accessor :generic_properties

      # When reference is enum, set to enum type
      attr_accessor :enum_reference_type

      # Returns properties from schema
      def self.from_request_schema(request_body_schema, specification)

        properties = []

        unless request_body_schema
          return [], serialization
        end

        if request_body_schema['allOf']
          request_body_schema['allOf'].each do |schema|
            properties += self.from_request_schema(schema, specification)
          end
        else
          if request_body_schema['properties'] && request_body_schema['properties'].count > 0
            # If multiple properties as root
            properties += ModelObject.properties_from_schema(request_body_schema, specification)
          else
            # If single model or array of model as root
            properties << property_from_schema(nil, request_body_schema, true, nil)
          end
        end

        return properties
      end

      def self.from_response_schema(response_schema, specification)

        if response_schema['content']


          serialization_and_body = response_schema['content'].select{|s, value| s.include? 'json'}.first
          unless serialization_and_body
            serialization_and_body = response_schema['content'].first
          end

          serialization, body = serialization_and_body

          if body
            description = response_schema['description']
            if description.nil? || description.length == 0
              description = response_schema['summary']
            end

            body['description'] = description
            property = from_response_body_schema(body['schema'], specification)
            property.descr = description
            return property, serialization
          end
        end

        puts "Can't find response body in schema: #{response_schema}".yellow
        # abort ''
        return nil
      end

      def self.generic_with_name(schemas, generic_name, specification)
        schemas.each do |schema|
          if schema['type'] == 'object' && schema['properties'].include?(generic_name)
            return from_response_body_schema(schema['properties'][generic_name], specification)
          end
        end
        return nil
      end

      def self.from_response_body_schema(response_body, specification)

        if response_body['allOf']

          response_body['allOf'].each do |schema|
            property = property_from_schema(nil, schema, true, nil)
            if property.reference

              is_generic = false
              model = specification.schema_at_ref(property.reference)
              model['properties'].each do |p_name, p_content|
                if p_content['type'] == 'object' && p_content['format'] == 'x-generic'
                  found_generic_value = self.generic_with_name(response_body['allOf'], p_name, specification)
                  if found_generic_value
                    found_generic_value.is_required = model['required'].include? p_name if model['required']
                    property.generic_properties = {} unless property.generic_properties
                    property.generic_properties[p_name] = found_generic_value
                    is_generic = true
                  end
                end
              end

              if is_generic
                return property
              end

            end

          end

          return self.from_response_body_schema(response_body['allOf'][0], specification)
        else
          return property_from_schema(nil, response_body, true, nil)
        end

      end

      def self.property_from_schema(p_key, p_content, p_required = false, p_label = nil)

        property = ModelProperty.new
        property.key = p_key
        property.label = p_label
        property.is_required = p_required

        if p_content['$ref']
          property.type = 'object'

          description = p_content['description']
          if description.nil? || description.length == 0
              description = p_content['summary']
          end
          property.descr = description

          property.reference = p_content['$ref']
        else
          property.type = p_content['type']

          description = p_content['description']
          if description.nil? || description.length == 0
            description = p_content['summary']
          end
          property.descr = description

          property.example = p_content['x-example'] || p_content['example']
          property.enum = p_content['enum']
          property.format = p_content['format']

          if p_content['items']
            if p_content['items']['$ref']
              property.reference = p_content['items']['$ref']
            end
            property.items = self.property_from_schema('', p_content['items'], false)
            if property.type != 'array'
              puts 'Warning: items specified for non-array type.. fixing.'
              property.type = 'array'
            end
          end
        end


        if !property.label && property.reference
          property.label = property.reference.split('/')[-1]
        end

        property
      end

      def load_reference(specification)
        schema = specification.schema_at_ref(self.reference)
        model_name = self.reference.split('/')[-1]
        if schema['enum']
          return EnumObject.new(model_name, schema, specification)
        else
          return ModelObject.new(model_name, schema, specification)
        end
      end

      def as_enum
        enum_name = self.key.capitalize_first
        return EnumObject.new(enum_name, {'type' => self.type, 'enum' => self.enum}, nil)
      end

    end

    class ModelObject

      attr_accessor :name
      attr_accessor :properties

      def initialize(name, content, spec)
        self.name = name
        self.properties = ModelObject.properties_from_schema(content, spec)
      end

      def self.properties_from_schema(schema, spec)

        result = []

        if schema['allOf']

          schema['allOf'].each do |subschema|


            properties_to_override = properties_from_schema(subschema, spec)
            keys_to_override = properties_to_override.map { |p| p.key }

            result.reject! do |prop|
              keys_to_override.include? prop.key
            end

            result.push *properties_to_override
          end

        else

          if schema['$ref']
            schema = spec.schema_at_ref(schema['$ref'])
          end

          if schema.key?('properties')
            schema['properties'].each do |p_name, p_content|
              is_required = false
              is_required = schema['required'].include? p_name if schema['required']
              result << ModelProperty.property_from_schema(p_name, p_content, is_required, p_name)
            end
          end

        end

        result
      end

      def add_references_to_enums(enums_hash)
        self.properties.each do |property|
          if property.reference
            ref_name = property.reference.split('/')[-1]
            enum = enums_hash[ref_name]
            if !enum
              next
            end
            property.enum_reference_type = enum.type
          end
        end
      end
    end

    class EnumObject

      attr_accessor :name
      attr_accessor :type
      attr_accessor :values

      def initialize(name, content, spec)
        self.name = name
        self.type = content['type']
        self.values = enum_values_from_schema(content, spec)
      end

      def enum_values_from_schema(schema, spec)

        enum = schema['enum']
        if !enum
          return
        end

        result = []

        enum.each do |value|
          result.push value
        end

        result
      end
    end
  end
end
