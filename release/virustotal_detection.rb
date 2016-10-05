require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize               
        super( {
            :guid        => '{CF35EE83-6024-46E5-9F01-7C8731A16629}',
            :name        => 'VirusTotal Detection Rate',
            :description => %q{
                Retrieve the last known detection rate from VirusTotal. You can supply you API key 
                via the /virustotal_apikey=KEY command line switch, which can be saved for later 
                use by this plugin if you set /virustotal_apikey_save=true
            },
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 
                'https://www.virustotal.com',
                'https://www.virustotal.com/en/about/terms-of-service/'
            ],
            :shortcuts   => { 
                :virustotal_report => 'Alt+V' 
            },
            :require     => {
                :files => [ 'date', 'digest/sha1', 'rubygems', 'json', 'rest-client' ]
            },
            :options     => {
                '/virustotal_apikey'      => nil,
                '/virustotal_apikey_save' => false
            }
        } )
    end

    def get_virustotal_report( apikey )
    
        if( apikey.nil? or current_model.nil? )
            return false 
        end
        
        analysis_sha1 = ::Digest::SHA1.hexdigest( current_model.buffer ) 

        if( analysis_sha1.nil? )
            raise 'Unable to retrive the Analysis SHA1'
        end

        result = ::RestClient.post( 
            'https://www.virustotal.com/vtapi/v2/file/report',
            'apikey'   => apikey,
            'resource' => analysis_sha1 
        )

        report = ::JSON.parse( result )
        
        if( report['response_code'] <= 0 )
            print_warning( report['verbose_msg'] )
            return false
        end
        
        current_model.synchronize_write do
            current_model.add_information(
                Relyze::FileModel::Information.new( {
                    :group => :security,
                    :title => 'VirusTotal',
                    :data  => "Detection rate on %s was %d/%d" % [ report['scan_date'], report['positives'], report['total'] ] ,
                    :view  => :internet,
                    :url   => report['permalink']
                } )
            )
        end
        
        return true
    end

    def get_apikey
        apikey = options[ '/virustotal_apikey' ]
        
        if( apikey.nil? )
            apikey = get_persistent_value( :apikey, '' )
            if( apikey.empty? )
                if( @relyze.gui? )
                    apikey = @relyze.input_dialog( @information[:name], 'Please enter your VirusTotal API key:' )
                end
            end    
        end
        
        if( not apikey or apikey.empty? )
            raise 'You must specify your API key first'
        end
        
        if( options[ '/virustotal_apikey_save' ].to_bool )
            set_persistent_value( :apikey, apikey )
        end
        
        return apikey
    end
    
    def virustotal_report
        get_virustotal_report( get_apikey )
        if( @relyze.gui? )
            @relyze.update_gui
        end
    end
    
    def pre_structure_analyze
        get_virustotal_report( get_apikey )
    end
    
    def run
        virustotal_report
    end
end