# Jekyll GalleryTag
# 
# Automatically creates thumbnails for a directory of images.
# Adds a "gallery" Liquid tag
# 
# Author: Matt Harzewski
# Copyright: Copyright 2013 Matt Harzewski
# License: GPLv2 or later
# Version: 1.1.0


require "rmagick"

module Jekyll

	class GalleryTag < Liquid::Block

	 	def initialize(tag_name, markup, tokens)
			super
			@gallery_name = markup
		end

		def render(context)

			@config = context.registers[:site].config['gallerytag']
			columns = (@config['columns'] != nil) ? @config['columns'] : 4
			images = gallery_images

			images_html = ""
			images.each_with_index do |image, key|
				images_html << "<dl class=\"gallery-item\">\n"
				images_html << "<a class=\"gallery-link\" rel=\"#{@gallery_name}\" href=\"#{image['url']}\" title=\"#{image['caption']}\" data-lightbox=\"#{@gallery_name}\">"
				images_html << "<img src=\"#{image['thumbnail']}\" class=\"thumbnail\" width=\"150\" height=\"150\" />\n"
				images_html << "</a>\n"
				images_html << "</dl>\n\n"
			end
			images_html << "<br style=\"clear: both;\">" if images.count % 4 != 0
			gallery_html = "<div class=\"gallery\">\n\n#{images_html}\n\n</div>\n"

			return gallery_html

		end

		def gallery_images
			input_data = block_contents
			gallery_data = []
			input_data.each do |item|
				hsh = {
					"url" => "#{@config['url']}/#{item[0]}",
					"thumbnail" => GalleryThumbnail.new(item[0], @config), #this should be url to a generated thumbnail, eventually
					"caption" => item[1]
				}
				gallery_data.push(hsh)
			end
			return gallery_data
		end

		def block_contents
			text = @nodelist[0]
			lines = text.split(/\n/).map {|x| x.strip }.reject {|x| x.empty? }
			lines = lines.map { |line|
				line.split(/\s*::\s*/).map(&:strip)
			}
			return lines
		end

	end

	class GalleryThumbnail

	 	def initialize(image_filename, config)
	 		@img_filename = image_filename
	 		@config = config
	 	end

	 	def to_s
	 		get_url
	 	end

	 	def get_url
	 		filename = File.path(@img_filename).sub(File.extname(@img_filename), "-thumb#{File.extname(@img_filename)}")
	 		"#{@config['url']}/#{filename}"
	 	end

	end

  class ThumbStaticFile < StaticFile

    def dest_name
      ext = File.extname(@name)
      @name.sub(ext, "-thumb#{ext}")
    end

    def destination(dest)
      @site.in_dest_dir(*[dest, destination_rel_dir, dest_name].compact)
    end

    def write(dest)
      dest_path = destination(dest)

      return false if File.exist?(dest_path) && !modified?
      self.class.mtimes[path] = mtime

      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.rm(dest_path) if File.exist?(dest_path)

      img = Magick::Image::read(path).first
      thumb = img.resize_to_fill(
        @site.config["gallerytag"]["thumb_width"],
        @site.config["gallerytag"]["thumb_height"]
      )
      thumb.write dest_path

      FileUtils.touch dest_path, :mtime => mtime

      true
    end

  end

	class ThumbGenerator < Generator

    def generate(site)
      if Jekyll.configuration({}).has_key?('slideshow')
        config = Jekyll.configuration({})['slideshow']
      else
        config = Hash["width", 100, "height", 100]
      end
      to_thumb = Array.new

      site.static_files.each do |file|
        if (file.extname == ('.jpg' || '.png'))
          to_thumb.push(file)
        end
      end

      to_thumb.each do |file|
        site.static_files << ThumbStaticFile.new(
          site,
          file.instance_variable_get(:@base),
          file.instance_variable_get(:@dir),
          file.instance_variable_get(:@name),
          file.instance_variable_get(:@collection)
        )
      end
    end

  end

end

Liquid::Template.register_tag('gallery', Jekyll::GalleryTag)
