#
# Save this plugin in the users plugins folder: C:\Users\USERNAME\Documents\Relyze\Plugins\test_entrypoints.rb
#
# When analyzing a file in the GUI, tick to enable this plugin in the plugin options before analysis begins. 
#
# After analysis you can invoke this plugin either via its keyboard short cut or through the right click pop-up menu on the code view.
#
# You can load this plugin in the plugin editor and simply choose to run it.
#

require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{75A2197C-4A3C-4B29-A526-5DCE6BE63EFD}',
            :name        => 'Test Plugin Entrypoints',
            :description => 'Test the various entrypoints of an Analysis plugin, including manually running the plugin, invoking the plugin via a keyboard or popup menu shortcut or via the analysis pipeline.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ],
            :shortcuts                => { 
                :my_plugin_shortcut   => 'Alt+X',
            },
        } )
    end

    # Run this method when the plugin is manually run, either via the plugin 
    # editor (E.g. pressing F5 to run) or by right clicking on this plugin in 
    # the application Plugins view and selecting to run it.
    def run
        print_message( "Hello via run" )
    end
    
    # Run this method when the user presses 'Alt+X' or right click in GUI and selects Plugins->Test Plugin Entrypoints->my_plugin_shortcut.
    def my_plugin_shortcut
        print_message( "Hello via my_plugin_shortcut" )
    end
    
    # Hook into the analysis pipeline at the pre structure analysis stage.
    def pre_structure_analyze
        print_message( "Hello via pre_structure_analyze" )
        return true
    end

    # Hook into the analysis pipeline at the post structure analysis stage.
    def post_structure_analyze
        print_message( "Hello via post_structure_analyze" )
        return true
    end

    # Hook into the analysis pipeline at the pre code analysis stage.
    def pre_code_analyze
        print_message( "Hello via pre_code_analyze" )
        return true
    end

    # Hook into the analysis pipeline at the post code analysis stage.
    def post_code_analyze
        print_message( "Hello via post_code_analyze" )
        return true
    end

end