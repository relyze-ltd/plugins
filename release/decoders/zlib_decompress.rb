require 'relyze/core'

class Plugin < Relyze::Plugin::Decoder

    def initialize
        super( {
			:guid                  => '{D8A53BFA-87EA-4F73-BD50-502B75E79D99}',
            :name                  => 'Zlib Decompress',
            :description           => 'Decompress a buffer via Zlib inflate',
            :authors               => [ 'Relyze Software Limited' ],
            :license               => 'Relyze Plugin License',
            :references            => [ 'http://www.zlib.net/' ],
			:require               => {
				:files             => [ 'zlib' ]
			},
			# if we want to peek at the encoded data, we must decode all of it rather then a small chunk.
            :decoder_min_peek_size => -1
        } )
    end
	
	def decode( buffer )
		return ::Zlib::Inflate.inflate( buffer )
	end
end
