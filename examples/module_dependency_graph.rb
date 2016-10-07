#
# Open this file in the Relyze Plugin Editor and simply select to Run it.
#
require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{51EA98B6-2BC5-48F2-AA9D-8DF46EF78375}',
            :name        => 'Generate PE Module Dependency Graph',
            :description => 'An example plugin to demonstrate basic parallel file analysis using the plugin framework as well as graph generation. This plugin will traverse a PE modules import directory and construct a module dependency graph.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ],
            :options     => {
                '/svg_file_path'      => nil,
                '/root_file_path'     => nil,
                '/lib_paths'          => nil,
                '/node_default_color' => '#4ECDC4',
                '/node_lib_color'     => '#FF6B6B',
                '/edge_default_color' => '#1A535C',
                '/max_threads'        => 12
            }
        } )
        @lock         = ::Mutex.new
        @queue        = []
        @search_paths = []
        @graph        = nil
    end

    def run

        print_message( "Starting..." )
        
        if( options['/root_file_path'].nil? or not ::File::exists?( options['/root_file_path'] ) )
            options['/root_file_path'] = @relyze.file_dialog( { 
                :file    => nil,
                :title   => 'Select a File...',
                :button  => 'Select',
                :display => 'All Files',
                :mask    => '*.*'
            } )
            if( options['/root_file_path'].nil? )
                print_message( "Finished. No root file provided." )
                return
            end
        end
        
        options['/root_file_path'].gsub!( "\\", ::File::SEPARATOR )

        @queue << options['/root_file_path']
        
        @search_paths << ::File.dirname( options['/root_file_path'] )
        
        if( not options['/lib_paths'].nil? )
            
            options['/lib_paths'].gsub!( "\\", ::File::SEPARATOR )
            
            @search_paths.concat( options['/lib_paths'].split( ';' ) )
        end
        
        # Crete a new graph object and specify some default display options...
        @graph = ::Relyze::Graph::DirectedGraph.new( 
            'Module Dependency Graph', 
            { 
                :node_shape            => :ellipse,
                :font_justify          => :center,
                :node_background_color => options['/node_lib_color'],
                :node_spacing          => 200
            }
        )
        
        threads = []
        
        # Spin up several threads to begin processing the modules...
        1.upto( options['/max_threads'] ) do
        
            threads << ::Thread.new do
            
                begin
                
                    while true do
                    
                        # Pull out the next file to analyze
                        file_path = @lock.synchronize do
                             @queue.pop
                        end

                        break if file_path.nil?

                        # Peek this files type and skip non PE binaries
                        peek = @relyze.analyze_peek_file( file_path )

                        next if peek.nil? or peek[:type] != :pe

                        # We dont need to do code analysis to inspect the binaries import table
                        analysis_options = {
                           :analyze_code => false
                        }
    
                        model = @relyze.analyze_file( file_path, analysis_options )
                           
                        next if model.nil?
                                          
                        # process this binaries import directory in order to generate the dependency graph
                        self.process_imports( model, model.structure['Import Directory'], options['/edge_default_color'] )
                        
                        print_message( "Processed: #{model.to_s}" )
                    end
                    
                rescue
                    print_message( "Exception in worker thread: #{$!}" )
                end
            end
        end
        
        threads.each do | thread |
            thread.join
        end

        # Perform a hierarchical layout on this graph before we display it
        @graph.layout( { :layout => :hierarchical } )
        
        # We can simply export the grpah to SVG and save it to a file
        if( not options['/svg_file_path'].nil? )
            ::File.open( options['/svg_file_path'], 'w' ) do | f |
                f.write( @graph.to_svg )
            end
        end
        
        # Or if We are using the relyze GUI, we can display the graph in the UI and interact with it (find nodes or paths, highlight connected neighbours and so on).
        if( @relyze.gui? )
            @relyze.graph_dialog( @graph )
        end
        
        print_message( "Finished." )
    end
    
    def process_imports( model, imports, edge_color )
        
        return if imports.nil?
        
        # As we are operating on the global @graph object, do so under a lock.
        @lock.synchronize do
        
            # Find the existing graph node for this module or create a new one if it doesn't already exist.
            source_node = @graph.find_or_create_node( model.origional_file_name.downcase )

            # We color nodes differently if they originate from the root file folder
            if( ::File.dirname( model.origional_file_path ) == ::File.dirname( options['/root_file_path'] ) )
                source_node.display[:node_background_color] = options['/node_default_color']
            end
            
            # If we are processing the root file, set it as the graphs root node and ad in some extra search paths 
            # so we can locate modules in system directories.
            if( options['/root_file_path'] == model.origional_file_path and @graph.root.nil? )
                
                @graph.root = source_node
                
                if( model.arch == :x64 )
                    @search_paths << ( ::Dir.exists?('c:/windows/system32') ? 'c:/windows/system32' : 'c:/windows/syswow64' )
                else
                    @search_paths << ( ::Dir.exists?('c:/windows/syswow64') ? 'c:/windows/syswow64' : 'c:/windows/system32' )
                end
            end
            
            # Iterate over every import in this binary
            imports.child_structures do | import |
            
                next if import.nil?

                # Normalize an imported module name to lower case (Windows is case insensitive for module loading).
                module_name = import.name.downcase
                
                # Some linkers omit the .dll portion
                if( not module_name.include?( '.' ) )
                    module_name << '.dll'
                end
                
                # Fint the existing graph node for this module or create a new one if it doesn't already exist.
                target_node = @graph.find_or_create_node( module_name )
                
                # If this is the first time we added this node (then it will have no edges), then
                # we perform a search in our search path for this file and when found, add it
                # to the queue for analysis so that we can go on and find its module dependencies.
                if( target_node.edges.empty? )
                
                    @search_paths.each do | lib_path |
                    
                        lib_file_path = ::File.join( lib_path, module_name )

                        if( File::exists?( lib_file_path ) )
                            @queue << lib_file_path
                            break
                        end
                    end
                end
                
                # Create an edge between the two module nodes, indicating a dependency between them.
                edge = @graph.create_edge( source_node, target_node )
                
                edge.display[:color] = edge_color
            end
        end
    end
end