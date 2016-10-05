#
# Open this file in the Relyze Plugin Editor and simply select to Run it.
#
require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{180CA050-1981-4759-8774-3F0936894F07}',
            :name        => 'Add Model Info',
            :description => 'Add some example information to a model which is displayed in the overview',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ]
        } )
    end

    def run
        # Ensure we have a current model (Either the currently active analysis tab in
        # the GUI or the model which this plugin is being auto run against).
        if( cm.nil? )
            print_error( "Analyze a binary first." )
            return
        end

        # Hold the models write lock while we update it.
        cm.synchronize_write do

            text = %q{Vestibulum mollis, erat eget vulputate luctus, enim nisi porta odio, ut semper eros tortor ac justo. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Donec eu enim eget magna placerat pretium. Sed in consectetur risus, sed iaculis eros. Pellentesque fringilla malesuada enim eget lacinia. Ut consectetur ante tortor, vehicula porttitor leo suscipit ac. Fusce pellentesque ipsum neque, vitae egestas metus malesuada eget.

Donec bibendum augue porttitor mauris bibendum, ut varius orci convallis. Sed sed erat at enim blandit ultrices. Donec efficitur ac diam nec commodo. Morbi a sodales nisl. Sed elit leo, sodales nec elit eget, consequat cursus elit. Mauris aliquet ante vitae iaculis rutrum. Nulla facilisi. Nunc placerat molestie lectus quis venenatis. Sed justo augue, malesuada dictum blandit vitae, iaculis id est. Vivamus accumsan commodo elit, vel mattis orci fermentum nec. Curabitur erat ante, dapibus eget sollicitudin quis, scelerisque nec felis. Donec ac lectus lacus. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
            }

            # Add in a blob of text which will be displayed beside the entropy view in the Overview.
            cm.add_auxiliary_text( 'Lorem Ipsum', text )

            # Add a new line of info to the overview, we can specify the category and optionally
            # link this info to a web address, offset in the structure of an address if the code view.
            # If the user double clicks the linked info item, they goto  that location.
            cm.add_information(
                Relyze::FileModel::Information.new( {
                    :group => :general,
                    :title => 'Relyze',
                    :data  => 'Visit us online!',
                    :view  => :internet,
                    :url   => 'https://www.relyze.com/'
                    }
                )
            )

            if( not cm.entry_point.nil? )
            
                cm.add_information(
                    Relyze::FileModel::Information.new( {
                        :group  => :analysis,
                        :title  => 'Entry Point',
                        :data   => 'This is where the entry point is.',
                        :view   => :code,
                        :offset => cm.entry_point
                        }
                    )
                )
            end
        end

    end
end