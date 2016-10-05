#
# Run via the command line with the following command (Note: All paths must be absolute and plugin_commandline paths must be double slashed):
#
#   Save this plugin in the users plugins folder: C:\Users\USERNAME\Documents\Relyze\Plugins\multithreaded_folder_analysis.rb
#
#   "C:\Program Files\Relyze\relyze.exe" /run /plugin "{730CCFB0-CDC9-4B5C-90CA-D9BF39784868}" /log "C:\Testing\log.txt" /plugin_commandline "/path=C:\\samples /max_threads=12"
#
# Or you can specify an absolute path to the plugin instead of its GUID:
#
#   "C:\Program Files\Relyze\relyze.exe" /run /plugin "C:\path\to\multithreaded_folder_analysis.rb" /log "C:\Testing\log.txt" /plugin_commandline "/path=C:\\samples /max_threads=12"
#
# Or open this file in the Relyze Plugin Editor and simply select to Run it.
#

require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{730CCFB0-CDC9-4B5C-90CA-D9BF39784868}',
            :name        => 'Multithreaded Folder Analysis',
            :description => 'Example plugin to analyze all files in a folder and save them to the Relyze library.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ],
            :options     => {
                '/path'        => 'c:\\samples',
                '/max_threads' => 12
            }
        } )
        
        @lock  = ::Mutex.new
        @queue = []
    end

    def run

        print_message( "Starting..." )

        if( not ::Dir.exists?( options['/path'] ) )
            print_message( "Folder '#{options['/path']} does not exist." )
            return
        end

        # Add every file we want to process to a queue
        ::Dir.glob( "#{options['/path'].gsub( "\\", ::File::SEPARATOR )}/**/*").each do | file_path |
        
            if( ::File.size( file_path ) > 1024 * 256 )
                next
            end
            
            @queue << file_path
            
            if( @queue.length >= 100 )
                break
            end
        end

        print_message( "Processing #{@queue.length} files..." )

        threads = []
        
        # Spin up our worker threads to begin processing files from our work queue
        1.upto( options['/max_threads'] ) do
        
            threads << ::Thread.new do
            
                begin
                
                    while true do
                    
                        # Under a lock, grab the next file to process...
                        file_path = @lock.synchronize do
                             @queue.pop
                        end

                        break if file_path.nil?
                        
                        # Peek this file to see what file type it is (e.g. :ar, :elf, :pe, :coff or :flat)
                        peek = @relyze.analyze_peek_file( file_path )

                        # Ignore flat file types (Which are unknown file types)
                        next if peek.nil? or peek[:type] == :flat

                        # We can specify various analysis options and what plugins to run when we analyze a file.
                        opts = {
                            :analyze_code                 => true,
                            :static_library_analysis      => true,
                            :jump_table_analysis          => true,
                            :indirect_call_analysis       => true,
                            :propagate_function_datatypes => true,
                            :embedded_symbols             => true,
                            :precompiled_header_symbols   => true,
                            :seh_analysis                 => true,
                            :cpp_exception_analysis       => true,
                            :process_imports              => true,
                            :process_exports              => true,
                            :function_local_analysis      => true,
                            :pc_relative_analysis         => true,
                            :datatype_from_mangled_name   => true,
                            :plugins                      => [ @relyze.get_plugin_guid( 'Segment Strip' ) ],
                            :plugin_commandline           => "/strip=.rsrc;.reloc"
                        }
                        
                        # Analyze the file and get back a model for this file...
                        model = @relyze.analyze_file( file_path, opts )
                        
                        next if model.nil?

                        # XXX: Here we can interact with the model and access functions, basic blocks, instructions, references and so on.
                        
                        # We can save this model to the Relyze library, adding a custom description and tags.
                        @relyze.library.save(
                            model,
                            {
                                :tags        => [ 'multithread' ],
                                :description => 'This is a test!'
                            }
                        )

                        print_message( "Processed: #{model}" )

                    end
                rescue
                    print_message( "Exception in worker thread: #{$!}" )
                end
            end
        end
        
        # Wait for all threads to complete...
        threads.each do | thread |
            thread.join
        end

        print_message( "Finished." )
    end
end