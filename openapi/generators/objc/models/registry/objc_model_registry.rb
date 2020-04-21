require_relative '../../models/objc_model'

class ObjcModelRegistry

  $models_for_name = {}

  def self.cleanup
    $models_for_name = {}
  end

  def self.objc_model(spec_model)
    model = $models_for_name[spec_model.name]
    unless model
      model = ObjcModel.new(spec_model)
      $models_for_name[spec_model.name] = model
      model.load_properties
    end
    return model
  end

end