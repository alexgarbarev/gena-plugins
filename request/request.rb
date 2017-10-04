module Gena

  class Request < Plugin


    desc 'request REQUEST_NAME', 'Generates API call for TyphoonRestClient'
    method_option :method, :aliases => '-m', enum: ['GET', 'POST', 'PUT', 'DELETE'], :desc => 'HTTP method'
    method_option :path, :aliases => '-p', :desc => 'Specifies custom subdirectory'

    def request(request_name)


      method = http_method(request_name)

      say "HTTP Method: #{method}", Color::YELLOW

      path = File.join(self.plugin_config['path'], options[:path] || '', request_name)

      params = {
          'http_method' => method.to_s.downcase.capitalize_first,
          'request_name' => request_name
      }

      if include_request_scheme?(method)
        say "Include BODY"
        params['include_request_body'] = true
      else
        say "WITHOUT BODY"
        params['include_request_path'] = true
      end

      codegen = Codegen.new(path, params)

      codegen.add_file('Code/Request/request.h.liquid', "#{ config['prefix'] }RequestTo#{request_name}.h", Filetype::SOURCE)
      codegen.add_file('Code/Request/request.m.liquid', "#{ config['prefix'] }RequestTo#{request_name}.m", Filetype::SOURCE)
      if include_request_scheme?(method)
        codegen.add_file('Code/Request/request.json.liquid', "#{ config['prefix'] }RequestTo#{request_name}.request.json", Filetype::RESOURCE)
      end
      codegen.add_file('Code/Request/request.json.liquid', "#{ config['prefix'] }RequestTo#{request_name}.response.json", Filetype::RESOURCE)



    end

    no_tasks do

      def self.plugin_config_defaults
        {'path' => 'BusinessLogic/Network/Requests'}
      end

      def http_method(name)
        return options[:method] unless options[:method].nil?
        downcase_name = name.downcase
        return :POST if downcase_name.include_one_of? ['post', 'create']
        return :GET if downcase_name.include_one_of? ['get', 'read']
        return :PUT if downcase_name.include_one_of? ['put', 'update']
        return :DELETE if downcase_name.include_one_of? ['delete', 'remove']
        return :GET
      end

      def include_request_scheme?(method)
        method.to_s == 'POST' || method.to_s == 'PUT'
      end
    end

  end

end
