
class ObjcTypeInfo

  def generics
    {}
  end

  #####

  def requires_trc_processing
    true
  end

  def is_pointer_type
    true
  end


  def declaration(header = true)

  end

  def comment

  end

  def schema_value

  end

  ######

  def process_response(response_value)
    response_value
  end

  def compose_request(request_value)
    request_value
  end

  ######

  def import_headers
    []
  end

  def import_classes
    []
  end

end

class ObjcTypeInfoData < ObjcTypeInfo

  attr_accessor :declaration
  attr_accessor :comment
  attr_accessor :schema_value
  attr_accessor :import_headers
  attr_accessor :import_classes

  def declaration(header = true)
    @declaration
  end

  def import_headers
    @import_headers || []
  end

  def import_classes
    @import_classes || []
  end

end

