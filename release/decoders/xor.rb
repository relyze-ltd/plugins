require 'relyze/core'

class Plugin < Relyze::Plugin::Decoder

    def initialize
        super( {
            :guid        => '{0A4DEB51-56FB-4648-B51C-654CE8C94ADD}',
            :name        => 'Xor',
            :description => 'Xor a buffers bytes',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License'
        } )
    end
    
    def can_run?
        return false if not super
        # as this decoder requires the GUI to ask the user the xor key, we must be in GUI mode.
        return false if not @relyze.gui?
        return true
    end
    
    def decode( buffer )
        xor_key = @relyze.input_dialog( self.name, 'Please enter an XOR key:', '0x41' ).to_i( 16 )
        
        key_parts = []
        while( xor_key > 0 ) do 
            key_parts.unshift( (xor_key & 0xFF) )
            xor_key >>= 8
        end
                
        result = ''
        index  = 0
        
        buffer.each_byte do | b |
            result << [ (b ^ key_parts[index]) ].pack( 'C' )
            index += 1
            if( index >= key_parts.length )
                index = 0
            end
        end
        
        return result
    end
end
