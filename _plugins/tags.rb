module SamplePlugin
  class CategoryPageGenerator < Jekyll::Generator
    safe true

    def generate(site)
      safs = site.collections['safs']
      saftags = safs.docs.map { |saf| saf.data['tags'] }
      flat = saftags.flatten
      
      groups = flat.group_by{ |doc| doc }.map {|k,v| [k, v.length]}

      sorted_groups = groups.sort_by {|k, v| [-v, k]}
      hashed_sorted_groups = sorted_groups.to_h

      counter = 4.2
      hashed_sorted_groups.each do |group, count|
        site.pages << CategoryPage.new(site, group, count, counter)
        counter += 0.01

      end
      
    end
  end

  # Subclass of `Jekyll::Page` with custom method definitions.
  class CategoryPage < Jekyll::Page
    def initialize(site, group, count, counter)
      #puts group
      @site = site             # the current site instance.
      @base = site.source      # path to the source directory.
      @dir  = "tags"

      # All pages have the same filename, so define attributes straight away.
      @basename = group      # filename without the extension.
      @ext      = '.html'      # the extension.
      @name     = group + '.html' # basically @basename + @ext.

      @excerpt = nil

      safs = site.collections['safs'].docs.map {|saf| saf.data['title']}

      @data = {
        'linked_docs' => "",
        "layout" => "page",
        "title" => group,
        "nav_order" => counter,
        "tag_name" => group,
        "tag_count" => count,
        "safs" => safs,
        }
        @content = "<div>" + group + ": " + count.to_s + "</div>"

        @content += "<div><ul>"
        site.collections['safs'].docs.each do |saf|
          if saf.data['tags'].include? group
            @content += "<li><a href=\"..#{saf.url}\">#{saf.data['title']}</a></li>"
          end
        end
        @content += "</ul></div>"
    end

    # Placeholders that are used in constructing page URL.
    def url_placeholders
      {
        :path       => @dir,
        :category   => @dir,
        :basename   => basename,
        :output_ext => output_ext,
      }
    end
  end
end