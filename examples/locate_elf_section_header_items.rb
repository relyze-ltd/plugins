#
# Open this file in the Relyze Plugin Editor and simply select to Run it.
#
require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{7A2D4231-A87D-4A02-90F4-DB66CA7F70FE}',
            :name        => 'Locate ELF Section Header Items.',
            :description => 'Simple helper script to locate an entry in an ELF relocation or symbol section',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ]
        } )
    end

    def locate_elf_section_item( type, title, value )
        cm.structure['Ident']['Header']['Section Headers'].child_structures do | section |
            if( section['type'].comment !~ type )
                next
            end
            section.child_structures do | entry |
                if( entry[title].value == value or entry[title].comment =~ value )
                    print_message( "Section: %s" % section.name )
                    entry.items do | item |
                        print_message( "\t%8s - 0x%-16X ; %s" % [ item.name, item.value, item.comment ] )
                    end
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
        
        print_message( "[+] Starting." )

        # To test, look for any symbols for printf.
        locate_elf_section_item( /SHT_DYNSYM|SHT_SYMTAB/, 'name', /printf/ )

        # To test, look for relocations for a specific address.
        locate_elf_section_item( /SHT_REL/, 'offset', cm.rva2va( 0x000018F8 ) )

        print_message( "[+] Finished." )
    end
end
