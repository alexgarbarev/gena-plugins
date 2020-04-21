class ObjcClassRegistry

  $written_apiname_per_class = {}


  def self.api_name_for_class(objc_class)
    name = $written_apiname_per_class[objc_class]
    if name
      return name
    else
      return api_name($specification)
    end
  end

  def self.render(objc_class, &block)

    if $written_apiname_per_class[objc_class]
      puts "#{objc_class} already rendered. Skipping..".yellow
    else
      block.call
      $written_apiname_per_class[objc_class] = api_name($specification)
    end

  end

end