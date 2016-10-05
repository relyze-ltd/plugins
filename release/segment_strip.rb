require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{DB1E9DF7-F6E8-4C72-9310-226CDE04B0C1}',
            :name        => 'Segment Strip',
            :description => %q{
                Strip unwanted segments before code analysis. Default to stripping the .rsrc 
                and .reloc segments. You can pass arbitrary segment names to strip on the 
                plugin command line via the /strip switch, e.g. /strip=.rsrc;.reloc
            },
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :options     => {
                '/strip' => ".rsrc;.reloc"
            }
        } )
    end
    
    # We strip the segments before code analysis begins
    def pre_code_analyze
        # grab the section names we will strip
        return if not options[ '/strip' ]
        # split the string into an array of section names
        names = options[ '/strip' ].split( ';' )
        # don't bother to continue if we have no sections to strip
        return if names.empty?
        # we must hold the write lock while we delete segments...
        cm.synchronize_write do
            # grab the current auto_analyze value so we can restore it when we are done
            orig_auto_analyze = cm.auto_analyze
            # disable auto analysis so every time we call cm.delete_segment() we don't trigger
            # cm.analyze() not only would this incur an unnecessary performance hit, but as 
            # we are running pre_code_analyze we do not want to invoke the analyze at this
            # stage in the pipeline.
            cm.auto_analyze = false
            # keep an array of the segments we will delete
            del = []
            # iterate over every segment to see if we want to delete it
            cm.segments do | segment |
                if( names.include?( segment.name ) )
                    del << segment
                end
            end
            # delete every segment in our list
            del.each do | segment |
                cm.delete_segment( segment )
            end
            # restore the original auto_analyze value
            cm.auto_analyze = orig_auto_analyze
        end
    end
    
end
