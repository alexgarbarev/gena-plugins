module Gena

  class Test < Plugin

    desc 'test CLASS_NAME', 'Generates template for unit test and puts into correct path'

    def test(class_name)

      filepath = `find #{self.sources_path} -name "#{class_name}.m"`

      if filepath.empty?
        say "Can't find path for file '#{class_name}.m'", Color::RED
        abort
      end

      say "Found class at path #{filepath}", Color::GREEN if $verbose

      relative_dir = self.source_dir_from_file_path(filepath)

      params = {
          'class_name' => class_name
      }

      codegen = Codegen.new(relative_dir, params)

      if class_name.downcase.include? 'assembly'
        codegen.add_file('Tests/tests_assembly.m.liquid', "#{class_name}Tests.m", Filetype::TEST_SOURCE)
      else
        codegen.add_file('Tests/tests.m.liquid', "#{class_name}Tests.m", Filetype::TEST_SOURCE)
        codegen.add_file('Tests/testable_category.h.liquid', "#{class_name}_Testable.h", Filetype::TEST_SOURCE)
      end

    end

    no_tasks do
      def source_dir_from_file_path(filepath)
        filepath["#{self.sources_path}/"] = ''
        filepath.gsub!(/\s+/, ' ').strip!
        File.dirname(filepath)
      end
    end
  end
end
