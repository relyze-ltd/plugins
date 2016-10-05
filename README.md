Relyze Plugins
==============

Release
-------
These plugins are shipped with [Relyze](https://www.relyze.com).

 * [release/call_highlight.rb](release/call_highlight.rb) - Highlight every call instruction in the current function.
 
 * [release/diff_copy_data.rb](release/diff_copy_data.rb) - After a differential analysis has been performed, copy block names and comments from all matched functions in the current analysis over to the diffed analysis.
 
 * [release/pe_import_hash.rb](release/pe_import_hash.rb) - Generate an IMPHASH for a PE file. You can also list all the archives in the current library which have matching IMPHASH hashes.
 
 * [release/processor_mode.rb](release/processor_mode.rb) - Get or set the processor mode at the currently selected location.
 
 * [release/segment_strip.rb](release/segment_strip.rb) - Strip unwanted segments before code analysis.
 
 * [release/static_library_analysis.rb](release/static_library_analysis.rb) - A simple GUI plugin to manually query and apply static library packages against all non library functions. You can also color known static library functions.
 
 * [release/virustotal_detection.rb](release/virustotal_detection.rb) - Retrieve the last known detection rate from VirusTotal.
 
 * [release/decoders/base64.rb](release/decoders/base64.rb) - Base64 Decoder a buffer.
 
 * [release/decoders/bitwise_not.rb](release/decoders/bitwise_not.rb) - Bitwise Not a buffers bytes.
 
 * [release/decoders/xor.rb](release/decoders/xor.rb) - Xor a buffers bytes.
 
 * [release/decoders/zlib_decompress.rb](release/decoders/zlib_decompress.rb) - Decompress a buffer via Zlib inflate

Examples
--------
These plugins are simple examples to demonstrate various capabilities.

 * [examples/binary_diff_compare.rb](examples/binary_diff_compare.rb) - Analyze two binaries and perform a differential analysis against them. Displays the percentage difference of the two binaries and what function were modified, by how much and their corresponding matched function.

 * [examples/count_unique_instructions.rb](examples/count_unique_instructions.rb) - Iterate over every instruction in every code block and count the number of unique instructions based on their mnemonic.

 * [examples/disassemble_arbitrary_bytes.rb](examples/disassemble_arbitrary_bytes.rb) - Example to disassemble an arbitrary byte stream for the various supported architectures.

 * [examples/locate_elf_section_header_items.rb](examples/locate_elf_section_header_items.rb) - Example to traverse a models structure in order to search for some data.

 * [examples/module_dependency_graph.rb](examples/module_dependency_graph.rb) - Example to analyse multiple binaries and generate a dependency graph based each binaries module imports. The graph is either displayed in the GUI or saved as an SVG file.

 * [examples/multithreaded_folder_analysis.rb](examples/multithreaded_folder_analysis.rb) - Example to perform analysis on multiple binaries in parallel and then save them to the Relyze library.

 * [examples/add_model_info.rb](examples/add_model_info.rb) - Add some example information to a model which is displayed in the overview.
 
 * [examples/colors.rb](examples/colors.rb) - Simple example to show how to set the color of a models structure items, functions, blocks or instructions.
 
 * [examples/test_entrypoints.rb](examples/test_entrypoints.rb) - Test the various entrypoints of an Analysis plugin, including manually running the plugin, invoking the plugin via a keyboard or popup menu shortcut or via the analysis pipeline.
 
Support:
--------

Visit our [Relyze Plugin SDK](https://www.relyze.com/docs/SDK/index.html) documentation for a complete description of the plugin framework.

Visit our [Help Centre](http://support.relyze.com/help_center) to find answers to common questions.

If you require further assistance, [contact us](https://www.relyze.com/contact.html) directly.

License
-------
All plugins are made available under a 3 clause BSD license. Please see [LICENSE.txt](LICENSE.txt) for more information.