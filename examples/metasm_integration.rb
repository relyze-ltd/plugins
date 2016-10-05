# Grab the latest version of metasm and store it in "c:\metasm" or similar.
# >cd c:\
# >git clone https://github.com/jjyg/metasm.git
#
# In the Relyze Application options dialog, select the Plugins tab.
# Add the folder "c:\metasm" as an additional library path.
# Restart Relyze.
#
# Open this file in the Relyze Plugin Editor and select to Run it.
#
require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{F109191F-66E8-4A27-8569-B92E99A90C67}',
            :name        => 'Example Metasm library integration',
            :description => 'Test loading and using the Metasm library.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ],
            :require     => {
                :files   => [ 'metasm' ]
            }
        } )
    end

    def run
        cpu = ::Metasm::Ia32.new( 64 )

        data= ::Metasm::Shellcode.assemble( cpu, "nop" ).encode_string

        print_message( data.inspect )
    end
end