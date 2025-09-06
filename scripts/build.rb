# build.rb - Update CSS files, switcher.js, and README.md
# Expects frameworks.yml in the same directory.
#
# Usage:
#   ruby build.rb           # Update all frameworks and collection themes
#   ruby build.rb foo bar   # Update specific frameworks and/or collection themes by key

#!/usr/bin/env ruby

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

def generate_switcher(data)
  frameworks = get_frameworks(data)
  collections = get_collections(data)
  coll_theme_keys = collections.values.flatten.reject { |theme_key| theme_key == "info" }
  switcher = "var frameworks = \"#{frameworks.sort.join(",")},#{coll_theme_keys.join(",")}\";"
end

def update_js(data)
  switcher_file = "../switcher.js"
  switcher_txt = File.read(switcher_file)

  switcher = generate_switcher(data)
  new_switcher_txt = switcher_txt.gsub(/var frameworks = [^;]*;/, switcher)
  File.open(switcher_file, "w") { |f| f << new_switcher_txt }
end

def frameworks_attribution(data)
  frameworks = get_frameworks(data)
  list = ""
  frameworks.sort.each do |fwk_key|
    root = data["frameworks"][fwk_key]
    list << process_attribution_root(fwk_key, root)
  end
  list
end

def collections_attribution(data)
  collections = get_collections(data)
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

def update_readme(data)
  readme_file = "../README.md"
  readme_txt = File.read(readme_file)

  frameworks_list = frameworks_attribution(data)
  collections_list = collections_attribution(data)

  header_f = "### List of frameworks\n\n"
  header_c = "### Theme collections\n\n"
  out_f = header_f + frameworks_list + "\n###"
  out_c = header_c + collections_list + "\n##"

  new_readme_txt = readme_txt
    .gsub(/#{header_f}.*?###/m, out_f)
    .gsub(/#{header_c}.*?##/m, out_c)

  File.open(readme_file, "w") { |f| f << new_readme_txt }
end

def switcher_routine(data)
  puts "- Updating switcher.js file..."
  update_js(data)
  puts "  Update complete."
  puts
end

def frameworks_routine(data, options)
  puts "- Updating CSS frameworks..."
  frameworks = get_frameworks(data)
  frameworks.each do |fwk_key|
    root = data["frameworks"][fwk_key]
    process_css_root(fwk_key, root, options)
  end
  puts "  Update complete."
  puts
end

def collections_routine(data, options)
  puts "- Updating CSS collections..."
  collections = get_collections(data)
  collections.each do |coll_key, themes|
    themes.each do |theme_key|
      if theme_key == "info" then next end
      root = data["collections"][coll_key][theme_key]
      process_css_root(theme_key, root, options)
    end
  end
  puts "  Update complete."
  puts
end

def process_css_root(key, root, options)
  url = root["url"]
  skip = root["skip"]
  if options.empty?
    update_css(key, url) unless skip
  elsif options.include?(key)
    update_css(key, url)
  end
end

def readme_routine(data)
  puts "- Updating readme file..."
  update_readme(data)
  puts "  Update complete."
  puts
end

def process_updates(data, options=[])
  frameworks_routine(data, options)
  collections_routine(data, options)
  switcher_routine(data)
  readme_routine(data)
end

data = YAML::load(File.read("frameworks.yml"))

if ARGV[0]
  options = ARGV
  process_updates(data, options)
else
  process_updates(data)
end
