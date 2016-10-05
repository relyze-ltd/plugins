require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid                    => '{273AFF27-6C32-4231-93AC-896311411246}',
            :name                    => 'Diff Copy Data',
            :description             => %q{
                After a differential analysis has been performed, copy block names and comments 
                from all matched functions in the current analysis over to the diffed analysis.
            },
            :authors                 => [ 'Relyze Software Limited' ],
            :license                 => 'Relyze Plugin License',  
            :shortcuts               => { 
                :diff_copy_data      => 'Alt+D'                             
            },
            :require                 => {
                :files               => [ 'set' ]
            },
            :min_application_version => '1.2.0'
        } )
    end

    def diff_copy_data
    
        copy = @relyze.list_dialog(
            self.name,
            'Select what to copy:',
            [ 'Names and comments', 'Names only', 'Comments only' ]
        )
        
        return if copy.nil?
        
        copy_names    = false
        copy_comments = false
        
        if( copy == 'Names and comments' )
            copy_names    = true
            copy_comments = true
        elsif( copy == 'Names only' )
            copy_names = true
        elsif( copy == 'Comments only' )
            copy_comments = true
        end
        
        diff_copy( copy_names, copy_comments )
    end
    
    def run
        diff_copy_data
    end
    
    def diff_copy( copy_names, copy_comments )
        
        return if cm.nil?
        
        print_message( "Starting..." )
        
        processed_names    = ::Set.new
        processed_comments = ::Set.new
        
        cm.synchronize_read do
            
            dr = @relyze.tab_current_diff
            
            if( dr.nil? )
                print_error( "No diff results." )
                break
            end
            
            # swap the DiffModelResults to the other side if we need to, e.g. the 
            # user right clicked on the B view and ran this plugin rather than
            # the A view.
            if( dr.model != cm )
                dr = dr.matched
            end
            
            print_message( "Copying comments from '#{dr.name}' to '#{dr.matched.name}'..." )
            
            dr.functions do | dr_func |
            
                next if dr_func.is_removed? or dr_func.is_added?
                
                dr_func.blocks do | dr_block |
                    
                    next if dr_block.is_removed? or dr_block.is_added?
                    
                    if( copy_names and dr_block.block.custom_name? )
                    
                        if( not processed_names.include?( dr_block.rva ) )
                        
                            dr.matched.model.synchronize_write do 
                            
                                dr_block.matched.block.name = dr_block.name
                                
                                processed_names << dr_block.rva
                            end
                        end
                    end
                    
                    if( copy_comments )
                    
                        dr_block.instructions do | dr_inst |
                        
                            next if dr_inst.is_removed? or dr_inst.is_added?
                            
                            next if not dr.model.comment?( dr_inst.rva )

                            next if processed_comments.include?( dr_inst.rva )
                            
                            dr.matched.model.synchronize_write do
                                
                                commentA = dr.model.get_comment( dr_inst.rva )

                                if( dr.matched.model.comment?( dr_inst.matched.rva ) )
                                
                                    commentB = dr.matched.model.get_comment( dr_inst.matched.rva )
                                    
                                    break if commentA == commentB
                                    
                                    commentA << "\r\n\r\nPrevious Comment:#{ commentB }"
                                end
                                
                                dr.matched.model.add_comment( dr_inst.matched.rva, commentA )
                            
                                processed_comments << dr_inst.rva
                            end
                        end
                    end
                end
            end
        end
        
        print_message( "Finished. Copied #{processed_names.length} names and #{processed_comments.length} comments." )
        
        if( @relyze.gui? )
            @relyze.update_gui
        end
    end

end
