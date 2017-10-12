require 'ttfunk'
require 'plist'
require 'yaml'


module Gena

  class Fonts < Plugin

    desc 'fonts', 'Adds custom fonts to the projects and creates category'

    def fonts
      valid_fonts = add_fonts(font_paths)

      update_plist(valid_fonts)

      say "Fonts updated!", Color::GREEN
    end

    no_tasks do

      def self.plugin_config_defaults
        defaults = Hash.new
        defaults['category'] = 'Sources/Presentation/Common/Categories'
        fonts = `find . -iname '*.otf' -o -iname '*.ttf' -path Pods -prune`.strip.split('./')
        fonts_path = common_path(fonts)
        if fonts_path.empty?
          fonts_path = 'Resources/Fonts'
        end
        defaults['fonts_path'] = fonts_path
        defaults
      end

      def font_paths
        font_paths = []
        Dir.glob("#{self.plugin_config['fonts_path']}/**/*").each do |f|
          begin
            if File.file?(f)
              TTFunk::File.open(f)
              font_paths << f
            end
          rescue
            say "Skipping not font #{f}", Color::YELLOW
          end
        end
        return font_paths
      end

      def add_fonts(fonts)
        valid_names = []
        codegen = Codegen.new(self.plugin_config['category'], {})

        codegen.remove_from_project(self.plugin_config['fonts_path'])

        header = ''
        implementation = ''

        fonts.each do |f|
          file = TTFunk::File.open(f)

          if file.name.font_name
            font_name = file.name.font_name.last.gsub!("\000", '')
            method_name = method_name_from_font(font_name)

            header += codegen.render_template('Templates/method_header.liquid', { 'method_name' => method_name })
            implementation += codegen.render_template('Templates/method_impl.liquid', { 'method_name' => method_name, 'font_name' => font_name })

            say "Registered #{font_name}", Color::YELLOW

            valid_names << f
          else
            say "Font \"#{f}\" is invalid! Can't find font name. Skipping", Color::RED
            if File.extname(f) == '.ttc'
              say 'TTC fonts are not supported! Please unpack using http://transfonter.org/ttc-unpack', Color::RED
            end
          end
        end

        codegen.add_file('Templates/category.h.liquid', 'UIFont+CustomFonts.h', Filetype::SOURCE, { 'methods_header' => header})
        codegen.add_file('Templates/category.m.liquid', 'UIFont+CustomFonts.m', Filetype::SOURCE, { 'methods_impl' => implementation})

        valid_names.each do |font|
          codegen.add_file_to_project(font, Filetype::RESOURCE)
        end

        return valid_names
      end

      def update_plist(fonts)
        plist_path = File.expand_path(self.config['info_plist'])
        info_plist = Plist::parse_xml(plist_path)

        info_plist["UIAppFonts"] = fonts.map { |f| File.basename(f) }

        open(plist_path, 'w') { |f|
          f.puts info_plist.to_plist
        }
      end

      def method_name_from_font(font_name)
        font_name = font_name.dup
        font_name.gsub!("\000", '')
        font_name.encode!('utf-8')
        font_name.gsub!("_", "")
        font_name.gsub!("-", "")
        font_name.gsub!(" ", "")
        font_name.strip!
        config['prefix'].downcase + '_' + font_name[0,1].downcase + font_name[1..-1]
      end

    end
  end

end
