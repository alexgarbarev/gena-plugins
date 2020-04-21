class ObjcRestClient


  def self.compose_value(property, type, instance, rest_client, error_object)
    value = property.compose_value(instance)
    if type.info.requires_trc_processing
      "[#{rest_client} convertThenValidateRequestObject:#{value} usingSchemaObject:#{type.schema_object} options:TRCTransformationOptionsNone error:#{error_object}]"
    else
      value
    end
  end

  def self.parse_value(type, instance, rest_client, error_object)
    response = "[#{rest_client} validateThenConvertResponseObject:#{instance} usingSchemaObject:#{type.schema_object} options:TRCTransformationOptionsNone error:#{error_object}]"
    unless type.info.requires_trc_processing
      response = instance
    end
    type.info.process_response(response)
  end


end