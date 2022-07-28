* `for x in y reversed`
* `expr | filter: arg`
* `expr | image_url: width: 400`
* `if x contains y` (comparator? precedence?)
* Capture args correctly on for and tablerow (really in kwarglist)
* `liquid` tag semantics
* `for x in (a..b)`
* `tablerow x in (a..b)`
* hash comments
* parse strings
* Allow all valid tokens as ID (like `paginate`)
* More efficient allocation
* Actually free data
* Which tokens don't need to parse in Outputs?
* Where is fexpr vs expr actually allowed?
* Reentrant parser
* Expose as library
* Coalesce adjacent Text nodes
* Clean up handling of Text to prevent splitting on `{`
* Preserve locations
* Compile to Wasm
* Build DWARF info
