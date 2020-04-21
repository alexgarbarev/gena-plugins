
$code_tab = '    '
$schema_tab = '   '


def ivar_name(label, is_boolean = false)

  unless label
    return ''
  end


  name = label.camel_case.lowercase_first

  name = name.gsub('.', '')

  if is_boolean
    name = 'is' + name.capitalize_first
  end

  name = $objc_config.naming_replacements[name] || name

  if name =~ /^(new|copy)/
    name = 'a' + name.capitalize_first
  end

  name
end

def indent_code_lines(lines, level = 1)
  lines.map{|l| "#{$code_tab*level}#{l}" }
end

def name_from_ref(ref)
  unless ref
    return nil
  end
  class_name(ref.split('/')[-1])
end

def class_name(model_name)
  "#{common_prefix}#{model_name.capitalize_first}"
end

def common_prefix
  "#{$plugin.config['prefix']}#{$plugin.plugin_config['prefix']}#{$specification.prefix}"
end

def client_class_name
  "#{$plugin.config['prefix']}#{$plugin.plugin_config['prefix']}#{api_name($specification)}Client"
end

## Returns headers string that needs to be included as dependecies for source
## source should be object that implements `import_classes` and/or `import_headers` methods
## source can be also array of that objects
## if include_sources is yes, then it includes imports to source itself (e.g. not only dependencies of Model, but Model itself)
def imports(source, forward_declarations = false, include_source = false)

  import_lines = []
  import_classes = []

  if source.respond_to?(:each)
    source.each do |object|
      headers, classes = imports_from_object(object, include_source)
      import_lines.concat headers if headers
      import_classes.concat classes if classes
    end
  else
    headers, classes = imports_from_object(source, include_source)
    import_lines.concat headers if headers
    import_classes.concat classes if classes
  end

  unless forward_declarations
    import_classes.uniq.each do |clazz|
      import_lines << "#import \"#{clazz}.h\""
    end
    import_classes = []
  end

  result = import_lines.uniq.join("\n")

  if import_classes.count > 0
    result += "\n\n\n"
    import_classes.uniq.each do |clazz|
      result += "@class #{clazz};\n"
    end
  end

  return result
end

def imports_from_object(object, include_self = false)
  headers = []
  classes = []
  if object.respond_to?(:import_headers)
    headers = object.import_headers
  end
  if object.respond_to?(:import_classes)
    classes = object.import_classes
  end
  if include_self && object.is_a?(ObjcModel)
    classes << object.model_class
  end
  if include_self && object.is_a?(ObjcRequest)
    classes << object.request_class
  end

  headers.reject! { |header| header == "#import \"NSObject.h\""}
  return headers, classes
end

def api_name(specification)
  specification.name
end

class String

  def delete_first_if_matches(symbol)
    if self.slice(0, symbol.length) == symbol
      return self.slice(symbol.length..-1)
    end
    self
  end

  def downcase_first()
    self[0].downcase + self[1..-1]
  end

  def camel_case
    underscores = self.split('_')
    result = self
    if underscores.count > 1
      result = underscores.map { |e| e.capitalize }.join
    end
    result
  end
end


class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end