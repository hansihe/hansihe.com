
module Jekyll

	class SeriesSelectorTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      @series_id = markup.strip
    end

    def render(context)
      @site = context.registers[:site]
      @series_config = @site.config["series"][@series_id]

      series_posts = []

      @site.posts.docs.each do |item|
        series = item.data.fetch("series", nil)
        if series
          if series["id"] == @series_id
            series_posts << item
          end
        end
      end

      series_posts.sort { |a, b| a.data["series"]["part"] > b.data["series"]["part"] }

      part_list = ""
      series_posts.each do |item|
        short_title = item["series"].fetch("short_title", nil) || item["title"]
        part_list << "<div class=\"series_part\">\n"
        part_list << "#{short_title}"
        part_list << "</div>\n"
      end

      result = ""
      result << "<div class=\"series_container\">\n"
      result << part_list
      result << "</div>\n"

      return result
    end

  end

  class SeriesIndexGenerator < Generator

    def generate(site)
      series_posts = site.posts.docs.group_by { |post| post.data.fetch("series", {}).fetch("id", nil) }
      series_posts.delete(nil)

      series_posts.each { |key, value|
        series_posts[key] = value.sort_by { |item| item.data["series"]["part"] }
      }

      series_posts.each_value { |posts|
        posts.each { |post|
          post.data["series_posts"] = posts
        }
      }
    end

  end

end

Liquid::Template.register_tag('series_selector', Jekyll::SeriesSelectorTag)
