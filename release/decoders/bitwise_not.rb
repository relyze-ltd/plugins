require 'relyze/core'

class Plugin < Relyze::Plugin::Decoder

    def initialize
        super( {
			:guid        => '{4BE1917F-D5E0-499D-A26A-304E22F59E75}',
            :name        => 'Bitwise Not',
            :description => 'Bitwise Not a buffers bytes',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License'
        } )
    end
	
	def decode( buffer )
		result = ''
		buffer.each_byte do | b |
			result << [ ~b ].pack( 'C' )
		end
		return result
	end
end
