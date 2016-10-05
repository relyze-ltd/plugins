# To use this plugin:
#   * Copy this plugin file to your Relyze Plugins folder (e.g. C:\Users\<username>\Documents\Relyze\Plugins\)
#   * Either restart Relyze.exe or right click in the Plugins view and select 'Reload all Plugins'
#   * Open the file you want to analyze and tick this plugin in the loader options 

require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid                    => '{2316E98E-03C5-4783-9066-DE80F8626912}',
            :name                    => 'Patch non executeable entry point section',
            :description             => %q{
                Patch the Characteristics of a PE section which contains the entry point 
                if that section is not already marked as executable.
            },
            :authors                 => [ 'Relyze Software Limited' ],
            :license                 => 'Relyze Plugin License',
            :require                 => {
                :type                => [ :pe ]
            },
            :min_application_version => '1.2.0'
        } )
    end
    
    IMAGE_SCN_CNT_CODE               = 0x00000020
    IMAGE_SCN_CNT_INITIALIZED_DATA   = 0x00000040
    IMAGE_SCN_CNT_UNINITIALIZED_DATA = 0x00000080
    IMAGE_SCN_MEM_EXECUTE            = 0x20000000

    def post_structure_analyze

        cm.synchronize_read do
            
            entry_point     = cm.structure['NT Header']['Optional Header']['EntryPoint'].value
        
            entry_section   = cm.structure['Section Header'][ cm.segment( entry_point ).name ]
            
            characteristics = entry_section['Characteristics'].value
            
            sizeofrawdata   = entry_section['SizeOfRawData'].value
            
            virtualsize     = entry_section['VirtualSize'].value
            
            if( ((characteristics & IMAGE_SCN_CNT_CODE) != IMAGE_SCN_CNT_CODE) and ((characteristics & IMAGE_SCN_MEM_EXECUTE) != IMAGE_SCN_MEM_EXECUTE) )
                characteristics |= IMAGE_SCN_MEM_EXECUTE
            end
            
            if( ((characteristics & IMAGE_SCN_CNT_INITIALIZED_DATA) != IMAGE_SCN_CNT_INITIALIZED_DATA) and (sizeofrawdata > 0) )
                characteristics |= IMAGE_SCN_CNT_INITIALIZED_DATA
            end    
            
            if( ((characteristics & IMAGE_SCN_CNT_UNINITIALIZED_DATA) != IMAGE_SCN_CNT_UNINITIALIZED_DATA) and (virtualsize > sizeofrawdata) )
                characteristics |= IMAGE_SCN_CNT_UNINITIALIZED_DATA
            end
            
            if( entry_section['Characteristics'].value != characteristics )
                cm.synchronize_write do
                    cm.write_buffer(
                        entry_section['Characteristics'].offset,
                        [ characteristics ].pack('V')
                    )
                    self.restart_analysis
                end
            end

        end
    end
    
end