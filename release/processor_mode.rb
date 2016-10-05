require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid                     => '{FF5D7775-55F9-449F-8A86-DA46B540FF7F}',
            :name                     => 'Processor Mode',
            :description              => 'Get or set the processor mode at the currently selected location.',
            :authors                  => [ 'Relyze Software Limited' ],
            :license                  => 'Relyze Plugin License',  
            :shortcuts                => { 
                :get_processor_mode   => nil,                                 
                :set_processor_mode   => nil
            },
            :min_application_version => '2.0.0'
        } )
    end
                            
    def get_processor_mode
        
        rva = @relyze.tab_current_rva( cm )
        
        if( rva.nil? )
            @relyze.message_dialog( self.name, "Please select a location first.", [ :Ok ], :error )
            return
        end
        
        mode = cm.get_processor_mode( rva )
        
        message = "Processor mode at 0x%08X is '%s'" % [ cm.rva2address( rva ), mode.nil? ? 'normal' : mode ]
        
        @relyze.message_dialog( self.name, message, [ :Ok ] )
    end
    
    def set_processor_mode
        
        modes = nil
        
        if( cm.arch == :arm )
            modes = [ :arm, :thumb ]
        end    
            
        if( modes.nil? )
            @relyze.message_dialog( self.name, "No alternative processor modes available for this architecture.", [ :Ok ] )
            return
        end
        
        rva = @relyze.tab_current_rva( cm )
        
        if( rva.nil? )
            @relyze.message_dialog( self.name, "Please select a location first.", [ :Ok ], :error )
            return
        end
    
        mode = @relyze.list_dialog( self.name, "Set processor mode at 0x%08X" % [ cm.rva2address( rva ) ], modes )
    
        if( mode.nil? or mode == cm.get_processor_mode( rva ) )
            return
        end
        
        if( not cm.set_processor_mode( rva, mode ) )
            @relyze.message_dialog( self.name, "Failed to set the processor mode.", [ :Ok ], :error )
        elsif( @relyze.gui? )
            @relyze.update_gui
        end
    end
        
    def run
        print_message( "To run this plugin, right click on some code in the GUI and select Plugins -> Processor Mode" )
    end
end                                               
