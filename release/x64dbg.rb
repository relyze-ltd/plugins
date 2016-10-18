require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{155E5668-13D4-46FE-A41F-2A21996CF18B}',
            :name        => 'x64dbg',
            :description => 'Import or export x64dbg databases, including bookmarks, comments and labels.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'http://x64dbg.com' ],
            :shortcuts   => { 
                :import_db => nil,
                :export_db => nil
            },
            :require     => {
                :type    => [ :pe ],
                :files   => [ 'json' ]
            },
            :min_application_version => '2.1.0'
        } )
    end

    def import_db
    
        db_file = @relyze.file_dialog( { 
                :file    => nil,
                :title   => 'Import Database...',
                :button  => 'Import',
                :display => 'All Files',
                :mask    => ('*.dd%d' % cm.bits)
            } )
           
        return if db_file.nil?
        
        db = nil
        
        ::File.open( db_file, 'r' ) do | f |
            db = ::JSON.parse( f.read( f.stat.size ) )
        end
        
        return if db.nil?
        
        bookmark_count = 0
        
        if( db.has_key?( 'bookmarks' ) )
        
            db['bookmarks'].each do | bookmark |
            
                next if bookmark['module'].downcase != cm.origional_file_name.downcase

                next if not cm.add_bookmark( bookmark['address'].to_i( 16 ), 'x64dbg bookmark %d' % (bookmark_count + 1) )
                 
                bookmark_count += 1
            end
        end
        
        comment_count = 0
        
        if( db.has_key?( 'comments' ) )
        
            db['comments'].each do | comment |
            
                next if comment['module'].downcase != cm.origional_file_name.downcase
                
                next if not cm.add_comment( comment['address'].to_i( 16 ), comment['text'] )
                
                comment_count += 1
            end
        end
        
        label_count = 0
        
        if( db.has_key?( 'labels' ) )
        
            db['labels'].each do | label |
            
                next if label['module'].downcase != cm.origional_file_name.downcase
            
                rva = label['address'].to_i( 16 )
                
                block = cm.block( rva )
                
                next if block.nil?
                
                if( block.rva != rva )
                
                    block = block.split( rva, block.type )
                    
                    next if block.nil?
                end
                
                block.name = label['text']
                
                label_count += 1
            end
        end
        
        print_message( "Finished. Imported %d bookmarks, %d comments and %d labels." % [ bookmark_count, comment_count, label_count ] )
    end
    
    def export_db
    
        db_file = @relyze.file_dialog( { 
            :file    => ( '%s.dd%d' % [ cm.origional_file_name, cm.bits ] ),
            :title   => 'Export Database...',
            :button  => 'Export',
            :display => 'All Files',
            :mask    => ('*.dd%d' % cm.bits)
        } )
           
        return if db_file.nil?
        
        db = {}
        
        bookmark_count = 0
        
        cm.bookmarks do | rva, description |
        
            if( not db.has_key?( 'bookmarks' ) )
                db['bookmarks'] = []
            end
            
            db['bookmarks'] << { 'module' => cm.origional_file_name, 'address' => ( '0x%X' % rva ), 'manual' => true }
            
            bookmark_count += 1
        end
        
        comment_count = 0
        
        cm.comments do | rva, description |
        
            if( not db.has_key?( 'comments' ) )
                db['comments'] = []
            end

            db['comments'] << { 'module' => cm.origional_file_name, 'address' => ( '0x%X' % rva ), 'manual' => true, 'text' => description.gsub( "\r\n", " " ) }
            
            comment_count += 1
        end
        
        label_count = 0
        
        cm.blocks do | block |
            
            next if not block.custom_name?
            
            if( not db.has_key?( 'labels' ) )
                db['labels'] = []
            end 
            
            db['labels'] << { 'module' => cm.origional_file_name, 'address' => ( '0x%X' % block.rva ), 'manual' => true, 'text' => block.name }
            
            label_count += 1
        end
        
        ::File.open( db_file, 'w' ) do | f |
            f.write( ::JSON.generate( db ) )
        end
        
        print_message( "Finished. Exported %d bookmarks, %d comments and %d labels." % [ bookmark_count, comment_count, label_count ] )
    end
    
    def run
        print_message( "Run this plugin via the right click menu in the code view." )
    end
end