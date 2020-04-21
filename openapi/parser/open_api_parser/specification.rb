module OpenApiParser
  module Specification
    META_SCHEMA_PATH = File.expand_path("../../swagger_meta_schema.json", __FILE__)

    def self.resolve(path, validate_meta_schema: true)
      raw_specification = Document.resolve(path)

      if validate_meta_schema
        meta_schema = JSON.parse(File.read(META_SCHEMA_PATH))
        #JsonSchema.parse!(meta_schema).validate!(raw_specification)
      end

      OpenApiParser::Specification::Root.new(raw_specification)
    end
  end
end
