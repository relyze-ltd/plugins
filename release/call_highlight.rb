require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid                     => '{574BEFEA-2982-4EFB-BE73-67AA97EC495D}',
            :name                     => 'Call Highlight',
            :description              => 'Highlight every call instruction in the current function',
            :authors                  => [ 'Relyze Software Limited' ],
            :license                  => 'Relyze Plugin License',  
            :shortcuts                => { 
                :call_highlight_set   => 'Alt+H',                                 
                :call_highlight_clear => 'Shift+Alt+H'
            },
            :require                  => {
                :arch                 => [ :x86, :x64, :arm ]
            }
        } )
    end
                            
    def call_highlight_set
        call_highlight( @relyze.rgb( 140, 140, 240 ) )
    end
    
    def call_highlight_clear
        call_highlight( nil )
    end
    
    def call_highlight( color )    
        # hold the current models write lock while we run this
        success = cm.synchronize_write do
            success = false
            # pull out the current function being displayed in the gui
            func = cm.function( @relyze.tab_current_function_rva )
            # test if a function is not being displayed
            if( not func.nil? )                       
                # iterate over every block in the function
                func.blocks do | block |      
                    # iterate over every instruction in the current block
                    block.instructions do | inst | 
                        # test if this instruction is a call and if so
                        # either set of clear the color.
                        if( inst.branch? and inst.branch_type == :call ) 
                            inst.color = color 
                            success    = true
                        end
                    end
                end  
            end
            success
        end    
        # refresh the gui if we succeeded in highlighting at least one instruction  
        if( success and @relyze.gui? )
            @relyze.update_gui
        end
    end   
    
end                                               
