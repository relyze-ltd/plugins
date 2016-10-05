Example Relyze Plugins
======================

 * examples/binary_diff_compare.rb - Analyze two binaries and perform a differential analysis against them. Displays the percentage difference of the two binaries and what function were modified, by how much and their corresponding matched function.

 * examples/count_unique_instructions.rb - Iterate over every instruction in every code block and count the number of unique instructions based on their mnemonic.

 * examples/disassemble_arbitrary_bytes.rb - Example to disassemble an arbitrary byte stream for the various supported architectures.

 * examples/locate_elf_section_header_items.rb - Example to traverse a models structure in order to search for some data.

 * examples/module_dependency_graph.rb - Example to analyse multiple binaries and generate a dependency graph based each binaries module imports. The graph is either displayed in the GUI or saved as an SVG file.

 * examples/multithreaded_folder_analysis.rb - Example to perform analysis on multiple binaries in parallel and then save them to the Relyze library.

License
-------
All plugins are made available under a 3 clause BSD license. Please see LICENSE.txt for more information.