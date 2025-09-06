# build.rb - Update CSS files, switcher.js, and README.md
# Expects frameworks.yml in the same directory.
#
# Usage:
#   ruby build.rb           # Update all frameworks and collection themes
#   ruby build.rb foo bar   # Update specific frameworks and/or collection themes by key

#!/usr/bin/env ruby

# frozen_string_literal: true

require 'yaml'

require_relative 'minify.rb'

def get_frameworks(data)
  frameworks = []
  data["frameworks"].each do |f|
    fwk_key = f[0]
    frameworks << fwk_key
  end
  frameworks
end

def get_collections(data)
  collections = {}
  data["collections"].each do |f|
    coll_key = f[0]
    collections[coll_key] = []
    f[1].each do |n|
      theme_key = n[0]
      collections[coll_key] << theme_key
    end
  end
  collections
end

def generate_switcher(frameworks, collections)
  coll_theme_keys = collections.values.flatten.reject { |theme_key| theme_key == "info" }
  switcher = "var frameworks = \"#{frameworks.sort.join(",")},#{coll_theme_keys.join(",")}\";"
end

def update_js(frameworks, collections)
  switcher_file = "../switcher.js"
  switcher_txt = File.read(switcher_file)

  switcher = generate_switcher(frameworks, collections)
  new_switcher_txt = switcher_txt.gsub(/var frameworks = [^;]*;/, switcher)
  File.open(switcher_file, "w") { |f| f << new_switcher_txt }
end

def frameworks_attribution(frameworks, data)
  list = ""
  frameworks.sort.each do |fwk_key|
    root = data["frameworks"][fwk_key]
    list << process_attribution_root(fwk_key, root)
  end
  list
end

def collections_attribution(collections, data)
  list = ""
  collections.each do |coll_key, themes|
    themes.each do |theme_key|
      root = data["collections"][coll_key][theme_key]
      list << process_attribution_root(theme_key, root, coll_key, "  ")
    end
  end
  list
end

def process_attribution_root(key, root, collection="", padding="")
  author = root["author"]
  repo = root["repo"]
  license = root["license"]
  license_url = root["license_url"]
  name = root["name"] || key
  if key == "info"
    "* **[#{collection}](#{repo})** by @#{author}:\n"
  else
    "#{padding}* [#{name}](#{repo}) by @#{author} ([Preview](https://dohliam.github.io/dropin-minimal-css/?#{key}) · [#{license}](#{license_url}))\n"
  end
end

def update_readme(frameworks, collections, data)
  readme_file = "../README.md"
  readme_txt = File.read(readme_file)

  frameworks_list = frameworks_attribution(frameworks, data)
  collections_list = collections_attribution(collections, data)

  header_f = "### List of frameworks\n\n"
  header_c = "### Theme collections\n\n"
  out_f = header_f + frameworks_list + "\n##"
  out_c = header_c + collections_list + "\n##"

  new_readme_txt = readme_txt
    .gsub(/#{header_f}.*?##/m, out_f)
    .gsub(/#{header_c}.*?##/m, out_c)

  File.open(readme_file, "w") { |f| f << new_readme_txt }
end

def switcher_routine(frameworks, collections)
  puts "- Updating switcher.js file..."
  update_js(frameworks, collections)
  puts "  Update complete."
  puts
end

def frameworks_routine(frameworks, data, specified_keys)
  puts "- Updating CSS frameworks..."
  frameworks.each do |fwk_key|
    root = data["frameworks"][fwk_key]
    process_css_root(fwk_key, root, specified_keys)
  end
  puts "  Update complete."
  puts
end

def collections_routine(collections, data, specified_keys)
  puts "- Updating CSS collections..."
  collections.each do |coll_key, themes|
    themes.each do |theme_key|
      if theme_key == "info" then next end
      root = data["collections"][coll_key][theme_key]
      process_css_root(theme_key, root, specified_keys)
    end
  end
  puts "  Update complete."
  puts
end

def process_css_root(key, root, specified_keys)
  url = root["url"]
  skip = root["skip"]
  if specified_keys.empty?
    update_css(key, url) unless skip
  elsif specified_keys.include?(key)
    update_css(key, url)
  end
end

def readme_routine(frameworks, collections, data)
  puts "- Updating readme file..."
  update_readme(frameworks, collections, data)
  puts "  Update complete."
  puts
end

def process_updates(data, args=[])
  frameworks = get_frameworks(data)
  collections = get_collections(data)
  frameworks_routine(frameworks, data, args)
  collections_routine(collections, data, args)
  switcher_routine(frameworks, collections)
  readme_routine(frameworks, collections, data)
end

data = YAML::load(File.read("frameworks.yml"))

if ARGV[0]
  args = ARGV
  process_updates(data, args)
else
  process_updates(data)
end
