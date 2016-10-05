require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{6264A3EE-44EF-416A-94AE-C42D60B47E57}',
            :name        => 'PE Import Hash',
            :description => %q{
                Generate an IMPHASH for a PE file. You can also list all the archives in 
                the current library which have matching IMPHASH hashes.
            },
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'https://www.mandiant.com/blog/tracking-malware-import-hashing/' ],
            # We can manually invoke the generate_hash or list_hash_groups methods from the GUI via a keyboard short cut.
            :shortcuts   => { 
                :generate_hash    => 'Alt+I',
                :list_hash_groups => 'Shift+Alt+I'
            },
            # For this plugin to run we require the file 'digest/md5' be available. We override
            # can_run? for more control for each individual action.
            :require     => {
                :type    => [ :pe ],
                :files   => [ 'digest/md5' ]
            }
        } )
    end

    def gen_imphash
        # while holding the models read lock, generate the import string 
        imports_string = current_model.synchronize_read do  
            # sanity check this model has an import directory
            break nil if current_model.structure['Import Directory'].nil?
            imports_array = []
            # iterate over the import directory modules...
            current_model.structure['Import Directory'].child_structures do | mod |  
                # for each imported module, iterate over the function imports...
                mod.child_structures do | imp |
                    # for compatibility with other IMPHASH implementations, we must rewrite 
                    # function names imported by ordinals from "ordinal123" to "ord123"
                    m = /^ordinal([\d]{1,})$/i.match( imp.name.downcase )                                                            
                    if( m.nil? )                    
                        imports_array << "%s.%s" % [ ::File.basename( mod.name.downcase, ::File.extname( mod.name.downcase ) ), imp.name.downcase  ]    
                    else                  
                        imports_array << "%s.ord%s" % [ ::File.basename( mod.name.downcase, ::File.extname( mod.name.downcase ) ), m[1] ]    
                    end
                end
            end                                                                                                                                  
            imports_array.join( ',' )
        end                       
        # fail gracefully if we didn't generate an import string
        return false if imports_string.nil?    
        # generate the MD5 hash of the import string while we don't hold the lock
        imphash = ::Digest::MD5.hexdigest( imports_string ).upcase
        # while holding the write lock we update the model by adding in the new
        # information about the IMPHASH we just generated
        current_model.synchronize_write do
            current_model.add_information(
                Relyze::FileModel::Information.new( {
                    :group => :hash,
                    :title => 'IMPHASH',  
                    :data  => imphash
                } )                        
            )
        end
        return true
    end                                                                  

    # group all matching IMPHASH archives from the library and list them to the console.
    def list_hash_groups
        print_message( "[%s] Listing groups..." % self.name )
        imp_hashes = {}

        @relyze.library.archives do | archive |
            archive.hashes do | hash_name, hash_value |
                if( hash_name == 'IMPHASH' )
                    if( imp_hashes[hash_value].nil? )
                        imp_hashes[hash_value] = [ archive ]
                    else
                        imp_hashes[hash_value] << archive
                    end
                    break
                end
            end
        end

        imp_hashes.each do | hash_value, archives |
            next if archives.length <= 1
            print_message( "\tIMPHASH '%s' has %d matches" % [ hash_value, archives.length ] )
            archives.each do | archive |
                print_message( "\t\t%-40s (%s)" % [ archive.name, archive.path ] )
            end
        end
        print_message( "[%s] Finished." % self.name )
    end
    
    # prevent this plugin running generate_hash() against anything that is not a PE
    # however allow list_hash_groups() to run regardless as this action does not
    # require a model object.
    def can_run?( action=nil )
        return false if not super( action )
        if( action == :generate_hash )    
            if( current_model.nil? or current_model.type != :pe )
                return false
            end
        end
        return true
    end
    
    # override the base class post_structure_analyze method (as a public method) in 
    # order to make this plugin available to run at the post structure analysis 
    # stage in the analysis pipeline.
    def post_structure_analyze
        gen_imphash
    end
    
    def generate_hash
        if( gen_imphash and @relyze.gui? )
            @relyze.update_gui
        end
    end
    
    # The run method is called when manually invoking the analysis plugin.
    def run
        list_hash_groups
    end
end

