require_relative 'objc_types'
require_relative '../../models/objc_enum'

class ObjcTypeInfoEnum < ObjcTypeInfo

  attr_accessor :enum

  def initialize(spec_property, spec_enum)
    self.enum = ObjcEnum.new(spec_enum)
  end

  def is_pointer_type
    true
  end

  def declaration(header=true)
    self.enum.enum_declaration
  end

  def schema_value
    self.enum.schema_value
  end

  def process_response(response_value)
    self.enum.process_response(response_value)
  end

  def compose_request(request_value)
    self.enum.compose_request(request_value)
  end

  def import_headers
    ["#import \"#{ObjcEnum.enum_header_name}.h\""]
  end

  def requires_trc_processing
    false
  end

end