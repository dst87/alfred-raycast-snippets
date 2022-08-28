# alfred-raycast Snippet Converter

A tool to convert snippet collections exported from [Alfred](https://www.alfredapp.com) to a format that can be imported into [Raycast](https://www.raycast.com).

## Usage

```
Usage: ./alfred-raycast.rb -i ~/path/to/snippets.alfredsnippets
-i, --input [filepath]           Path to Alfred export
-e, --expand [all, none]         Ignore the exported snippet's autoexpand setting
								 and include or exclude keyword for all snippets.
-h, --help                       Display this help information
```

A JSON file will be written to your current working directory that can be exported into Raycast.

## Auto-expansion

In Alfred you can set an expansion keyword for all snippets and then choose whether to enable or disable auto-expansion on a per-snippet basis. Raycast does not have this granularity; if an expansion keyword is included, it will always be enabled.

By default, this tool will include the keyword for all snippets for which auto-expansion was turned on in Alfred.  To include the keyword for all snippets, use the `-e all` modifier.  To exclude the keyword for all snippets, use `-e none`.