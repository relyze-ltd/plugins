#
# Open this file in the Relyze Plugin Editor and simply select to Run it.
#
require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{19CC3CEA-B1AA-4A15-8540-97A4398E3F66}',
            :name        => 'Count Unique Instruction Mnemonics',
            :description => 'Count the unique instruciton in the current analysis model based on their mnemonics and display the unique mnemonics from high to low.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ]
        } )
    end

    def unique_instructions
        total     = 0
        mnemonics = Hash.new
        # Grab the models read lock while we iterate over every block and instruction.
        cm.synchronize_read do
            # Iterate over every block in the model
            cm.blocks do | block |
                # Skip blocks that are node code
                next if not block.code?
                # Iterate over every instruction in this code block
                block.instructions do | inst |
                    # pull out the instruction raw decoded data and grab the mnemonic
                    m = inst.to_raw.mnemonic
                    # Update the mnemonics hash for this mnemonic
                    if( mnemonics.has_key?( m ) )
                        mnemonics[m] += 1
                    else
                        mnemonics[m] = 1
                    end
                    total += 1
                end
            end
        end
        return total, ::Hash[ mnemonics.sort_by{ | k, v | v }.reverse ]
    end

    def run
        # Ensure we have a current model (Either the currently active analysis tab in 
        # the GUI or the model which this plugin is being auto run against).
        if( cm.nil? )
            print_error( "Analyze a binary first." )
            return
        end
        total, mnemonics = unique_instructions
        print_message( "%s" % cm )
        print_message( "%d unique instructions - %d total." % [ mnemonics.length, total ] )
        print_message( mnemonics )
        print_message( "" )
    end
end
