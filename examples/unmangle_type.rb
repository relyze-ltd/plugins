#
# Open this file in the Relyze Plugin Editor and simply select to Run it.
#
# Example Output:
#
#    Starting.
#      Type:             private: long __cdecl ShStrW::_SetStr( unsigned short * param1, unsigned long param2 )
#      Type Size:        0
#      Ptr to Type:      private: long (__cdecl *)( unsigned short * param1, unsigned long param2 )
#      Ptr to Type Size: 4
#    Finished.
#

require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{3D60A319-0146-4F07-9268-11C16F682385}',
            :name        => 'Unmange a mangled name',
            :description => 'Unmange a (Microsoft, LLVM or Borland) mangled name and generate a corresponding data type for it and for example generate a poionter to this type.',
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

        print_message( "Starting." )

        mangled_name = @relyze.input_dialog( 'Unmangle', 'Enter a mangled name', '?_SetStr@ShStrW@@AAAJPBGK@Z' )

        # Use the current models (cm) data type manager (dtm) to unmangle a mangled name and pull out the name portion.
        name = cm.dtf.unmangle_name( mangled_name )
        
        # Now use the dtm to unmangle a mangled name and pull out a DataType object which describes this type.
        type = cm.dtf.unmangle_type( mangled_name )

        # We can create a pointer to this type
        ptr2type = cm.dtf.create_pointer( type )

        # Inspect the results...
        print_message( "  Type:             #{type.to_s( name )}" )

        print_message( "  Type Size:        #{type.size}" )

        print_message( "  Ptr to Type:      #{ptr2type}" )

        print_message( "  Ptr to Type Size: #{ptr2type.size}" )

        # XXX: Now we could set a basic blocks data type to this type.

        print_message( "Finished." )
    end
end