# frozen_string_literal: true

# Jekyll Plugin: Wikilinks to Post Links
#
# Resolves Obsidian-style [[wikilinks]] to Jekyll post URLs during build.
# Source .md files remain unchanged — transformation happens only in output.
#
# Supported syntax:
#   [[2026-02-19-hfb1stolenmount]]           -> [Post Title](/posts/slug/)
#   [[2026-02-19-hfb1stolenmount|custom text]] -> [custom text](/posts/slug/)
#   [[non-existing-note]]                     -> non-existing-note (plain text)
#
# Installation:
#   1. Copy this file to _plugins/wikilinks_to_posts.rb
#   2. Done. Jekyll loads it automatically during build.

module Jekyll
  class WikilinksToPostLinks
    WIKILINK_REGEX = /\[\[([^\]]+)\]\]/

    class << self
      def build_post_map(site)
        post_map = {}

        site.posts.docs.each do |post|
          # post.data['slug'] is the filename without date and extension
          slug = post.data['slug']
          # Full name without extension: 2026-02-19-hfb1stolenmount
          basename = File.basename(post.path, File.extname(post.path))
          title = post.data['title'] || basename
          url = post.url

          entry = { 'url' => url, 'title' => title }
          post_map[basename] = entry  # match by full filename
          post_map[slug] = entry      # match by slug only
        end

        post_map
      end

      def resolve(content, post_map)
        content.gsub(WIKILINK_REGEX) do
          inner = Regexp.last_match(1)

          if inner.include?('|')
            target, display = inner.split('|', 2)
          else
            target = inner
            display = nil
          end

          target = target.strip

          if post_map.key?(target)
            entry = post_map[target]
            link_text = display || entry['title']
            "[#{link_text}](#{entry['url']})"
          else
            # Not a published post — render as plain text
            display || target
          end
        end
      end
    end
  end
end

Jekyll::Hooks.register :posts, :pre_render do |post, payload|
  site = post.site
  # Build post map once per site build, cache on site.data
  unless site.data['_wikilink_post_map']
    site.data['_wikilink_post_map'] = Jekyll::WikilinksToPostLinks.build_post_map(site)
  end

  post_map = site.data['_wikilink_post_map']
  post.content = Jekyll::WikilinksToPostLinks.resolve(post.content, post_map)
end
