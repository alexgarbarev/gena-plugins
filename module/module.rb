module Gena


  class Module < Plugin

    desc 'module MODULE_NAME', 'Generates VIPER module'
    method_option :path, :aliases => '-p', :desc => 'Specifies custom subdirectory (i.e. scope)'
    method_option :story, :aliases => '-s', :desc => 'Specifies story subfolder'
    method_option :view, :banner => 'VIEW_NAME', :desc => 'Specifies custom view name'
    method_option :interactor, :banner => 'INTERACTOR_NAME', :desc => 'Specifies custom interactor name'
    method_option :only_view, :type => :boolean, :desc => 'Generates reusable view only'
    method_option :only_interactor,:type => :boolean, :desc => 'Generates reusable interactor only'
    method_option :with_tests, :type => :boolean, :desc => 'Generate module with tests'

    def module(module_name)

      params = {
          'view' => options[:view] || module_name,
          'interactor' => options[:interactor] || module_name,
          'module_name' => module_name
      }

      codegen = Codegen.new(path_for_module(module_name), params)

      view_subpath = options[:only_view] ? '' : 'View/'
      interactor_subpath = options[:only_interactor] ? '' : 'Interactor/'

      if include_view?
        codegen.add_file('Code/View/view_input_output.h.liquid', "#{view_subpath}#{ config['prefix']}#{module_name}ViewInputOutput.h", Filetype::SOURCE)
        codegen.add_file('Code/View/viewcontroller.h.liquid', "#{view_subpath}#{ config['prefix']}#{module_name}ViewController.h", Filetype::SOURCE)
        codegen.add_file('Code/View/viewcontroller.m.liquid', "#{view_subpath}#{ config['prefix']}#{module_name}ViewController.m", Filetype::SOURCE)
      end

      if include_presenter?
        codegen.add_file('Code/Assembly/assembly.h.liquid', "Assembly/#{config['prefix']}#{module_name}Assembly.h", Filetype::SOURCE)
        codegen.add_file('Code/Assembly/assembly.m.liquid', "Assembly/#{config['prefix']}#{module_name}Assembly.m", Filetype::SOURCE)
        codegen.add_file('Code/Presenter/module_input.h.liquid', "Presenter/#{config['prefix']}#{module_name}ModuleInput.h", Filetype::SOURCE)
        codegen.add_file('Code/Presenter/presenter.h.liquid', "Presenter/#{config['prefix']}#{module_name}Presenter.h", Filetype::SOURCE)
        codegen.add_file('Code/Presenter/presenter.m.liquid', "Presenter/#{config['prefix']}#{module_name}Presenter.m", Filetype::SOURCE)
        codegen.add_file('Code/Router/router_input.h.liquid', "Router/#{config['prefix']}#{module_name}RouterInput.h", Filetype::SOURCE)
        codegen.add_file('Code/Router/router.h.liquid', "Router/#{config['prefix']}#{module_name}Router.h", Filetype::SOURCE)
        codegen.add_file('Code/Router/router.m.liquid', "Router/#{config['prefix']}#{module_name}Router.m", Filetype::SOURCE)
      end

      if include_interactor?
        codegen.add_file('Code/Interactor/interactor_input_output.h.liquid', "#{interactor_subpath}#{ config['prefix']}#{module_name}InteractorInputOutput.h", Filetype::SOURCE )
        codegen.add_file('Code/Interactor/interactor.h.liquid', "#{interactor_subpath}#{ config['prefix']}#{module_name}Interactor.h", Filetype::SOURCE )
        codegen.add_file('Code/Interactor/interactor.m.liquid', "#{interactor_subpath}#{ config['prefix']}#{module_name}Interactor.m", Filetype::SOURCE )
      end

      if options[:with_tests]
        if include_view?
          codegen.add_file('Tests/View/view_tests.m.liquid', "#{view_subpath}#{ config['prefix']}#{module_name}ViewControllerTests.m", Filetype::SOURCE)
        end

        if include_presenter?
          codegen.add_file('Tests/Assembly/assembly_tests.m.liquid', "Assembly/#{config['prefix']}#{module_name}AssemblyTests.m", Filetype::TEST_SOURCE)
          codegen.add_file('Tests/Assembly/assembly_testable.h.liquid', "Assembly/#{config['prefix']}#{module_name}Assembly_Testable.h", Filetype::TEST_SOURCE)
          codegen.add_file('Tests/Router/router_tests.m.liquid', "Router/#{config['prefix']}#{module_name}RouterTests.m", Filetype::TEST_SOURCE)
          codegen.add_file('Tests/Presenter/presenter_tests.m.liquid', "Presenter/#{config['prefix']}#{module_name}PresenterTests.m", Filetype::TEST_SOURCE)
        end

        if include_interactor?
          codegen.add_file('Tests/Interactor/interactor_tests.m.liquid', "#{interactor_subpath}#{ config['prefix']}#{module_name}InteractorTests.m", Filetype::TEST_SOURCE)
        end

      end

    end

    no_tasks do

      def self.plugin_config_defaults
        {
            'stories_path' => 'Presentation/UserStories',
            'common_views_path' => 'Presentation/Modules/Common/Views',
            'common_interactors_path' => 'Presentation/Modules/Common/Interactors',
            'modules_path' => 'Presentation/Modules',
        }
      end

      def path_for_module(module_name)
        if options[:story]
          result = File.join(self.plugin_config['stories_path'], options[:story])
        elsif options[:only_view]
          result = self.plugin_config['common_views_path']
        elsif options[:only_interactor]
          result = self.plugin_config['common_interactors_path']
        else
          result = self.plugin_config['modules_path']
        end
        if options[:path]
          result = File.join(result, options[:path])
        end
        File.join(result, module_name)
      end

      def include_view?
        !options[:custom_view] && !options[:only_interactor]
      end

      def include_interactor?
        !options[:custom_interactor] && !options[:only_view]
      end

      def include_presenter?
        !options[:only_view] && !options[:only_interactor]
      end


    end

  end

end
