require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{EC932197-6588-480D-A724-52566A72E581}',
            :name        => 'Static Library Analysis',
            :description => 'A simple GUI plugin to manually query and apply static library packages against all non library functions. You can also color known static library functions.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :shortcuts   => {
                :apply_package           => nil,
                :query_package           => nil,
                :apply_any_package       => nil,
                :query_any_package       => nil,
                :color_library_functions => nil
            },
            :min_application_version => '3.0.2'
        } )
    end

    def apply_package
        self._apply_package( @relyze.static_library_packages.select { |p| p.type != :shared and p.applicable?( cm ) } )
    end

    def apply_any_package
        self._apply_package( @relyze.static_library_packages )
    end
    
    def query_package
        self._query_package( @relyze.static_library_packages.select { |p| p.type != :shared and p.applicable?( cm ) } )
    end

    def query_any_package
        self._query_package( @relyze.static_library_packages )
    end
    
    def color_library_functions
        color = nil
        count = 0
        cm.functions do | func |
            if( func.library? )
                if( color.nil? )
                    color = @relyze.color_dialog()
                    break if color.nil?
                end
                func.color = color
                count     += 1
            end
        end
        @relyze.message_dialog( self.name, "Colored %d static library functions." % [ count ], [ :Ok ] )
        if( count > 0 and @relyze.gui? )
            @relyze.update_gui 
        end
    end
    
    def run
        print_message( "This plugin is run from the GUI. Right click in the code view and select 'Plugins' -> '#{self.name}' to run this plugin." )
    end
    
    protected
    
    def _apply_package( packages )
        package = @relyze.list_dialog( self.name, "Apply Package:", packages.sort! { |x, y| x.name <=> y.name } )
        if( not package.nil? )
            count = package.apply( cm, nil )
            @relyze.message_dialog( self.name, "Applied %d signatures from package '%s'." % [ count, package.name ], [ :Ok ] )
            if( count > 0 and @relyze.gui? )
                @relyze.update_gui 
            end
        end
    end
    
    def _query_package( packages )
        package = @relyze.list_dialog( self.name, "Query Package:", packages.sort! { |x, y| x.name <=> y.name } )
        if( not package.nil? )
            @relyze.message_dialog( self.name, "Package '%s' has a similarity of %2.2f%%." % [ package.name, package.query( cm, nil ) * 100.0 ], [ :Ok ] )
        end
    end

end