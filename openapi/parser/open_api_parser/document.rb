module OpenApiParser
  class Document
    def self.resolve(path, file_cache=OpenApiParser::FileCache.new)
      file_cache.get(path) do
        content = YAML.load_file(path)
        Document.new(path, content, file_cache).resolve
      end
    end

    def initialize(path, content, file_cache)
      @path = path
      @content = content
      @file_cache = file_cache
    end

    def resolve
      #deeply_expand_refs(@content)
      @content
    end

    private

    def deeply_expand_refs(fragment)
      fragment = expand_refs(fragment)

      if fragment.is_a?(Hash)
        fragment.reduce({}) do |hash, (k, v)|
          hash.merge(k => deeply_expand_refs(v))
        end
      elsif fragment.is_a?(Array)
        fragment.map { |e| deeply_expand_refs(e) }
      else
        fragment
      end
    end

    def expand_refs(fragment)
      if fragment.is_a?(Hash) && fragment.has_key?("$ref")
        ref = fragment["$ref"]

        if ref =~ /\Afile:/
          expand_file(ref)
        else
          expand_pointer(ref)
        end
      else
        fragment
      end
    end

    def expand_file(ref)
      relative_path = ref.split(":").last
      absolute_path = File.expand_path(File.join("..", relative_path), @path)

      Document.resolve(absolute_path, @file_cache)
    end

    def expand_pointer(ref)
      pointer = OpenApiParser::Pointer.new(ref)
      fragment = pointer.resolve(@content)

      expand_refs(fragment)
    end
  end
end
