#
# Save this plugin in the users plugins folder: C:\Users\USERNAME\Documents\Relyze\Plugins\binary_diff_compare.rb
#
#
# Run via the command line with the following command (Note: All paths must be absolute and plugin_commandline paths must be double slashed):
#
#   Save this plugin in the users plugins folder: C:\Users\USERNAME\Documents\Relyze\Plugins\binary_diff_compare.rb
#
#   "C:\Program Files\Relyze\relyze.exe" /run /plugin "{42AD2B34-B0DB-4326-84D1-B45C439998B2}" /log "C:\Testing\log.txt" /plugin_commandline "/fileA=C:\\Testing\\foo1.exe /fileB=C:\\Testing\\foo2.exe"
#
# Or you can specify an absolute path to the plugin instead of its GUID:
#
#   "C:\Program Files\Relyze\relyze.exe" /run /plugin "C:\path\to\binary_diff_compare.rb" /log "C:\Testing\log.txt" /plugin_commandline "/fileA=C:\\Testing\\foo1.exe /fileB=C:\\Testing\\foo2.exe"
#
# Example Output:
#
# [+] Starting.
# [+] Analysing file A 'C:\Testing\foo1.exe'...
# [+] Analysing file B 'C:\Testing\foo2.exe'...
# [+] Diffing file A and B...
# [+] File A and B are modified (difference 23.18%).
# Function 'func_0x5F8' was removed (difference 100.00%)
# Function 'func_0x680' was removed (difference 100.00%)
# Function 'func_0x718' was removed (difference 100.00%)
# Function 'func_0x4B8' was modified (difference 100.00%) compared to Function 'func_0x4B8'
# Function 'func_0xC54' was modified (difference 20.00%) compared to Function 'func_0xCC4'
# Function 'func_0xC5C' was modified (difference 20.00%) compared to Function 'func_0xCCC'
# Function 'call_weak_fn' was modified (difference 66.67%) compared to Function 'call_weak_fn'
# Function '_Z13Test_Switch_2i' was modified (difference 41.11%) compared to Function '_Z13Test_Switch_2i'
# Function '_Z13Test_Switch_1i' was modified (difference 48.81%) compared to Function '_Z13Test_Switch_1i'
# Function 'main' was modified (difference 75.59%) compared to Function 'main'
# [+] Finished.
#

require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{42AD2B34-B0DB-4326-84D1-B45C439998B2}',
            :name        => 'Binary Diff Comparison',
            :description => 'Perform a differential binary analysis against two executable files and report the difference.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :options     => {
                '/fileA' => nil,
                '/fileB' => nil,
            }
        } )
    end

    def run
    
        # If running from the command line, all prints will be logged to a file specified via the command 
        # line /log parameter (e.g. /log "C:\Testing\log.txt").
        print_message( "[+] Starting." )
        
        begin
            
            # Pull out the file paths which may have been supplied via the plugin command line
            # (e.g. /plugin_commandline "/fileA=C:\\Testing\\foo1.exe /fileB=C:\\Testing\\foo2.exe").
            fileA = options[ '/fileA' ]
            fileB = options[ '/fileB' ]
            
            # If we are running this plugin via the Relyze GUI, we can ask the user for the file paths.
            if( @relyze.gui? )
                fileA = @relyze.file_dialog( { :title => 'Select file A...', :button  => 'Select' } ) if fileA.nil?
                fileB = @relyze.file_dialog( { :title => 'Select file B...', :button  => 'Select' } ) if fileB.nil?
            end
            
            # Sanity check they exist.
            if( fileA.nil? or not ::File::exists?( fileA ) )
                raise "File '#{fileA}' does not exist."
            end            
            
            if( fileB.nil? or not ::File::exists?( fileB ) )
                raise "File '#{fileB}' does not exist."
            end
        
            # Here we can adjust the analysis options if we need to...
            analysis_options = {
                :load_symbols => true
            }
            
            # Analyze the first file, ensuring it is an executable...
            print_message( "[+] Analysing file A '#{fileA}'..." )
            
            modelA = @relyze.analyze_file( fileA, analysis_options )

            raise "Failed to analyze '#{fileA}'." if modelA.nil?
            
            raise "File '#{fileA}' is not an executable file." if modelA.class != Relyze::ExecutableFileModel

            # Analyze the second file, ensuring it is an executable...
            print_message( "[+] Analysing file B '#{fileB}'..." )
            
            modelB = @relyze.analyze_file( fileB, analysis_options )

            raise "Failed to analyze '#{fileB}'." if modelB.nil?
            
            raise "File '#{fileB}' is not an executable file." if modelB.class != Relyze::ExecutableFileModel

            # We can test if both files sha256 hash's match and avoid diffing if they do.
            fileA_sha256 = modelA.information do | info |
                break info.data if info.title == "File SHA256"
            end
            
            fileB_sha256 = modelB.information do | info |
                break info.data if info.title == "File SHA256"
            end
                
            if( fileA_sha256 == fileB_sha256 )
                print_message( "[+] File A and B are equal (difference 0%)." )
            else
                # Diff file B against file A...

                print_message( "[+] Diffing file A and B..." )
            
                dr_model = modelA.diff( modelB )

                raise "Failed to diff file A and B." if dr_model.nil?
                
                # No we have the results of the differential analysis, we report the overall percentage difference...
                print_message( "[+] File A and B are %s (difference %.2f%%)." % [ dr_model.type, ( dr_model.difference * 100 ) ] )
                
                dr_model.functions do | dr_func |
                
                    # skip functions that were found to be equal
                    next if dr_func.is_equal?
                    
                    text = "Function '%s' was %s (difference %.2f%%)" % [dr_func.name, dr_func.type, ( dr_func.difference * 100 ) ]
                    
                    # If this function from modelA was modified, pull out the corresponding function in modelB the diff algorithm matched it to.
                    if( dr_func.is_modified? )
                        text << " compared to Function '%s'" % [  dr_func.matched.name ]
                    end
                    
                    print_message( text )
                end
            end
        rescue
            print_exception( $! )
        end
        
        print_message( "[+] Finished." )
    end
end
