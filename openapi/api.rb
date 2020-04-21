require_relative 'parser/open_api_parser'
require_relative 'generators/client_generator'

require 'fileutils'

class Hash
  def at_key(dotted_path)
    parts = dotted_path.split '.', 2
    match = self[parts[0]]
    if !parts[1] or match.nil?
      return match
    else
      return match.at_key(parts[1])
    end
  end
end

module Gena


  class OpenAPI < Plugin


    @specification


    desc 'open_api', 'Generates API stack from OpenAPI specification'

    def open_api

      api_urls = plugin_config['specs']

      api_urls.each_key do |api_name|

        api_url = nil
        prefix = nil
        if api_urls[api_name].is_a? Hash
          api_url = api_urls[api_name]['url']
          prefix = api_urls[api_name]['prefix']
        elsif api_urls[api_name].is_a? String
          api_url = api_urls[api_name]
          prefix = api_name
        end

        spec_path = File.expand_path(api_url)

        unless File.exists? spec_path
          puts "Unable to open spec at path: \"#{spec_path}\"".red
          abort
        end


        @specification = OpenApiParser::Specification.resolve(File.expand_path(api_url).strip)
        @specification.name = api_name
        @specification.prefix = prefix
        generator = ObjcGenerator.new(@specification, self)
        generator.generate
      end

    end

    no_tasks do

      def self.plugin_config_defaults
        path = `find . -name api.yaml`
        path = `find . -name api.yml` if path.empty?
        path = 'api.yaml' if path.empty?
        {
            'specs' => {
                "Main" => {
                    "prefix" => "",
                    "url" => path,
                }

            },
            'prefix' => 'Net'
        }
      end

      def self.dependencies
        return {
            "humanize" => "1.7",
            "json" => "2.1",
            "addressable" => "2.5",
            "json_schema" => "0.15"
        }
      end

      def is_remote?(url)
        regexp = /(https?:\/\/)([\w\d]+\.)?[\w\d]+\.\w+\/?.+/
        regexp =~ url
      end

      def specification
        @specification
      end

    end


  end

end
