#
# Open this file in the Relyze Plugin Editor and simply select to Run it.
#
require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{4BB6CD79-531F-4592-A175-09165BEBFADE}',
            :name        => 'Color Structure items, functions, blocks or instructions.',
            :description => 'Simple example to show how to set the color of a models structure items, functions, blocks or instructions.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ]
        } )
    end

    def color_structure( struct )
        # set this structures color
        struct.color = @relyze.rgb( Random.rand(255), Random.rand(255), Random.rand(255) )
        # iterate over every item in this structure and set its color
        struct.items do | value |
            value.color = @relyze.rgb( Random.rand(255), Random.rand(255), Random.rand(255) )
        end
        # get every item in this structure which is a child structuer we can recure into and color it.
        struct.child_structures do | child |
            color_structure( child )
        end
    end

    def color_code
        # pick some colors to use
        func_color = @relyze.rgb( Random.rand(255), Random.rand(255), Random.rand(255) )

        non_func_block_color = @relyze.rgb( Random.rand(255), Random.rand(255), Random.rand(255) )

        mov_inst_color = @relyze.rgb( Random.rand(255), Random.rand(255), Random.rand(255) )

        # Iterate voer every functions and set its color
        cm.functions do | func |
            func.color = func_color
        end

        # Iterate over every code block
        cm.blocks do | block |
            next if not block.code?
            # test to see if this code block belongs to any function.
            # if not, then set its color
            if( cm.functions( block.rva ).nil? )
                block.color = non_func_block_color
            end
            # iterate over every instruction and color MOV instructions.
            block.instructions do | inst |
                if( inst.to_raw.mnemonic == :mov )
                    inst.color = mov_inst_color
                end
            end
        end
    end

    def run
        # Ensure we have a current model (Either the currently active analysis tab in
        # the GUI or the model which this plugin is being auto run against).
        if( cm.nil? )
            print_error( "Analyze a binary first." )
            return
        end

        print_message( "Starting." )

        color_structure( cm.structure )

        color_code

        if( @relyze.gui? )
            @relyze.update_gui 
        end

        print_message( "Finished." )
    end
end