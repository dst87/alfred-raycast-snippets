#!/usr/bin/env ruby
require "json"
require "optparse"
require "tmpdir"

def snippet_hash(json, affixes)
	prefix = affixes[0]
	suffix = affixes[1]
	alfred_data = JSON.parse(json)["alfredsnippet"]
	expand_this = alfred_data["dontautoexpand"] == nil
	expand_none = $options[:expand] == :none
	expand_all = $options[:expand] == :all
	item = Hash.new
	item["name"] = alfred_data["name"]
	item["text"] = alfred_data["snippet"]
	if (expand_this || expand_all) && !expand_none
		item["keyword"] = prefix + alfred_data["keyword"] + suffix
	end
	return item
end

def prefix_suffix_from_plist(path)
	begin
		plist_data = File.read(path + "info.plist")
	rescue Errno::ENOENT
		puts "No info.plist found. Keyword suffixes and prefixes will not be used."
		return ["", ""]
	else
		matches = plist_data.match /<key>snippetkeywordprefix<\/key>\n\t<string>(.*)<\/string>\n\t<key>snippetkeywordsuffix<\/key>\n\t<string>(.*)<\/string>/
		return [matches[1], matches[2]]
	end
end

def generate_json_from_folder(path)
	path = path + "/" unless path[-1] == "/"
	affixes = prefix_suffix_from_plist(path)
	raycast_snippets = []
	Dir.glob("*.json", base: path) { |filename| 
		filepath = path + filename
		json = File.read(filepath)
		raycast_hash = snippet_hash(json, affixes)
		raycast_snippets << raycast_hash
	}
	puts "Parsed #{raycast_snippets.count} snippets from Alfred."
	return JSON.pretty_generate(raycast_snippets)
end

def collection_name(path)
	regex = /([^\/]+).alfredsnippets/
	matches = path.match(regex)
	if matches == nil
		return "output"
	else
		return matches[1]
	end
end

$options = {}
optparse = OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} -i ~/path/to/snippets.alfredsnippets"
	
	opts.on("-i", "--input [filepath]", String, "Path to Alfred export") do |i|
		$options[:input] = i
	end
  	
	opts.on("-e", "--expand [all, none]", [:all, :none],
		"Ignore the exported snippet's autoexpand setting",
		"and include or exclude keyword for all snippets.") do |e|
		if e == nil
			puts "Error: --expand flag should be 'all', 'none' or omitted."
			puts opts
			exit
		end
		$options[:expand] = e
	end
		
	opts.on( '-h', '--help', 'Display this help information' ) do
		puts opts
		exit
	end
end

begin
  optparse.parse!
  mandatory = [:input]
  missing = mandatory.select{ |param| $options[param].nil? }
  unless missing.empty?
	raise OptionParser::MissingArgument.new(missing.join(', '))
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  exit
end

dir = Dir.mktmpdir
begin
	result = `unzip "#{$options[:input]}" -d #{dir}`
	if $?.success?
		json = generate_json_from_folder(dir)
		collection_name = collection_name($options[:input])
		File.write("#{collection_name}.json", json)
		puts "Import #{collection_name}.json to Raycast."
		puts "Docs: https://manual.raycast.com/snippets/how-to-import-snippets"
	else
		puts "Error extracting snippets from the Alfred export."
		puts "Ensure you use a .alfredsnippets file as input."
	end	
ensure
	FileUtils.remove_entry dir
end