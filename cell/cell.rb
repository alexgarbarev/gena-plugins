module Gena

  class Cell < Plugin

    desc 'cell CELL_NAME', 'Generates cell and it\'s item to use with CCTableViewManager'
    method_option :path, :aliases => '-p', :desc => 'Specifies custom subdirectory'

    def cell(cell_name)

      path = self.plugin_config['path']
      path = File.join(path, options[:path]) if options[:path]
      path = File.join(path, cell_name)

      codegen = Codegen.new(path, {'cell_name' => cell_name})

      codegen.add_file('Code/CellViews/Cell.h.liquid', "#{self.config['prefix']}#{ cell_name}Cell.h", Filetype::SOURCE)
      codegen.add_file('Code/CellViews/Cell.m.liquid', "#{self.config['prefix']}#{ cell_name}Cell.m", Filetype::SOURCE)
      codegen.add_file('Code/CellItems/CellItem.h.liquid', "#{self.config['prefix']}#{ cell_name}CellItem.h", Filetype::SOURCE)
      codegen.add_file('Code/CellItems/CellItem.m.liquid', "#{self.config['prefix']}#{ cell_name}CellItem.m", Filetype::SOURCE)

    end

    no_tasks do
      def self.plugin_config_defaults
        {'path' => 'Presentation/UserStories'}
      end
    end
  end

end
