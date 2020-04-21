require_relative '../objc_type'

class ObjcTypeInfoNumber < ObjcTypeInfo

  def initialize(spec_property)

  end

  def declaration(header=true)
    return 'NSNumber *'
  end

  def schema_value
    return '33'
  end

  def requires_trc_processing
    false
  end

end