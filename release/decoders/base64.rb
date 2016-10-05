require 'relyze/core'

class Plugin < Relyze::Plugin::Decoder

    def initialize
        super( {
			:guid        => '{76813F3A-6A43-456E-8CFF-D15ACAF74E20}',
            :name        => 'Base64',
            :description => 'Base64 Decoder a buffer',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
			:require     => {
				:files   => [ 'base64' ]
			}
        } )
    end

	def decode( buffer )
		return ::Base64.decode64( buffer )
	end
end
