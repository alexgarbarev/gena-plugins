require_relative 'objc_types'

class ObjcTypeInfoString < ObjcTypeInfo

  def initialize(spec_property)
    @format = spec_property.format
  end

  def declaration(header=true)
    return 'NSString *'
  end

  def schema_value
    return '"text value"'
  end

  def requires_trc_processing
    false
  end

end