require 'relyze/core'

class Plugin < Relyze::Plugin::Loader

    def initialize
        super( {
            :guid        => '{C8191B5C-C6B3-4631-8182-71F710C8590E}',
            :name        => 'SREC',
            :description => 'Load Motorola S-Record (SREC) binaries',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 
                'https://en.wikipedia.org/wiki/SREC_(file_format)'
            ],
            :min_app_ver => '3.0.4'
        } )
    end
    
    def self.query( buffer )
        # quickly see if we have a leading header record and bail out if not found.
        return nil if not buffer.start_with?( 'S0' ) 
        # iterate over ever line and process the record
        base_address = nil
        buffer.lines do | line |
            # use a regex to pull out the records type, count and data characters
            m = line.match( /S(\d)(\w\w)(\w+)/ )
            if( m.nil? )
                RELYZE.console_print( nil, :error, "Unexpected S-Record line: #{line}" )
                return nil
            end
            # convert the first match into the type integer
            type = m[1].to_i( 16 )
            # convert the second match into the count integer
            count = m[2].to_i( 16 ) 
            # convert the third match into an array of 2 character values, then map those values to integers
            data = m[3].scan( /\w\w/ ).map { | char | char.to_i( 16 ) }
            # sanity check the count value matches the data length
            if( count != data.length )
                RELYZE.console_print( nil, :error, "Unexpected S-Record data length: #{count} != #{data.length}" )
                return nil
            end
            # compute the checksum
            checksum = count
            0.upto( data.length - 2 ) { | idx | checksum += data[idx] }
            # the checksum is the one's compliment of the low 8 bits, verify it
            # matches the checksum stored in the last data byte
            if( (((checksum & 0xFF) ^ ((1 << 8) - 1))) != data.pop )
                RELYZE.console_print( nil, :error, "Bad S-Record checksum in line: #{line}" )
                return nil
            end
            # pull out the address value from the current record, if any exists.
            # termination records have an optional address value, which may be 0 if unused.
            address = nil
            if( type == 0 )
                # header record
                return nil if data.length < 2
            elsif( type == 1 )
                # 16 bit address data record
                return nil if data.length < 2
                address = data.shift << 8 | data.shift
            elsif( type == 2 )
                # 24 bit address data record
                return nil if data.length < 3
                address = data.shift << 16 | data.shift << 8 | data.shift
            elsif( type == 3 )
                # 32 bit address data record
                return nil if data.length < 4
                address = data.shift << 24 | data.shift << 16 | data.shift << 8 | data.shift
            elsif( type == 4 or type == 5 or type == 6 )
                # ignore reserved and count records
            elsif( type == 7 )
                # 32 bit start address termination record
                return nil if data.length < 4
                address = data.shift << 24 | data.shift << 16 | data.shift << 8 | data.shift
                address = nil if address == 0
            elsif( type == 8 ) 
                # 24 bit start address termination record
                return nil if data.length < 3
                address = data.shift << 16 | data.shift << 8 | data.shift
                address = nil if address == 0
            elsif( type == 9 ) 
                # 16 bit start address termination record
                return nil if data.length < 2
                address = data.shift << 8 | data.shift
                address = nil if address == 0
            else
                # unknown
                RELYZE.console_print( nil, :error, "Unknown S-Record type: #{type}" )
                return nil
            end
            # if we have an address, keep the lowest address seen as a base address
            if( not address.nil? )
                base_address = address if base_address.nil? or (address < base_address)
            end
        end
        # we must bail out if we didn't find a base address
        if( base_address.nil? )
            RELYZE.console_print( nil, :error, "No S-Record base address found" )
            return nil
        end
        # SREC doesn't explicitly specify a target architecture, default to ARM, if
        # we have UI support, we can simply ask the user to pick one.
        arch = :arm
        if( RELYZE.gui? )
            arch = RELYZE.list_dialog( 'Motorola S-Record (SREC)', 'Select an architecture to load...', RELYZE.archs )  
            return nil if arch.nil?
        end
        # Success, return the information hash describing this loader...
        return {
            :title        => 'Motorola S-Record (SREC) ' + arch.to_s,
            :type         => :srec,
            :arch         => arch,
            :endian       => :little,
            :arch_mode    => :auto,
            :platform     => :unknown,
            :base_address => base_address
        }
    end
    
    def load
        # we load consecutive record data into a new segment,
        # track the current segments address, buffer and the expected next
        # address to load data into        
        current_segment_address = nil
        next_segment_address    = nil
        current_segment_buffer  = ''
        # create a helper lambda to add the current segment buffer into the model
        emit_current_segment = -> do
            if( not current_segment_address.nil? and not current_segment_buffer.nil? )
                # add a new segment RWX into the current model
                seg = cm.add_segment( 
                    ".text", 
                    cm.va2rva( current_segment_address ), 
                    current_segment_buffer.length, 
                    0, 
                    true, 
                    true, 
                    true 
                )
                # and write the current buffer into the new models segment
                seg.write_buffer( 0, current_segment_buffer )
            end
            # reset the current segments address/buffer so we can begin to laod
            # into a new segment if needed.
            current_segment_address = nil
            next_segment_address    = nil
            current_segment_buffer  = ''
        end
        # iterate over every line and process the record
        cm.buffer.lines do | line |
            # pull out the records type and data.
            # the checksum was verified during query so we ignore it here.
            m = line.match( /S(\d)(\w\w)(\w+)/ )
            return false if m.nil?
            type = m[1].to_i( 16 )
            data = m[3].scan( /\w\w/ ).map { | char | char.to_i( 16 ) }
            # pop off the unused checksum byte from the end of the data
            data.pop
            # process a header record
            if( type == 0 )
                # remove the unused address field
                data.shift
                data.shift
                # add in a model information entry for the headers contents
                cm.add_information(
                    Relyze::FileModel::Information.new( {
                        :group => :analysis,
                        :title => 'S-Record Header',
                        :data  => data.map { | byte | byte.chr }.join
                    } )
                )  
            end
            # pull out the current records address
            address = nil 
            if( type == 1 or type == 9 )
                # 16 bit address data or start address termination 
                address = data.shift << 8 | data.shift
            elsif( type == 2 or type == 8 )
                # 24 bit address data or start address termination 
                address = data.shift << 16 | data.shift << 8 | data.shift
            elsif( type == 3 or type == 7 )
                # 32 bit address data or start address termination 
                address = data.shift << 24 | data.shift << 16 | data.shift << 8 | data.shift
            end     
            # process 16/24/32 bit address data records
            if( type >= 1 and type <= 3 )
                # emit the current segment if this data record is not adjacent to the previous data record
                if( not next_segment_address.nil? and next_segment_address != address )
                    emit_current_segment.call
                end
                # record the current segments address the first time we see data
                current_segment_address = address if current_segment_address.nil?
                # append the current records data to the current segment
                data.each do | byte |
                    current_segment_buffer << byte.chr
                end
                # track the address we expect to see sequential data at for the next record we process.
                next_segment_address = address + data.length
            end           
            # process 16/24/32 bit start address termination records
            if( type >= 7 and type <= 9 )
                # emit the current segment as this is a termination record
                emit_current_segment.call
                # if we have a start address, add it to the analysis queue
                if( address != 0 )
                    cm.analysis_queue_push( :function, cm.va2rva( address ), "start" )
                end
            end
        end
        # emit the current segment in case no termination record was present
        emit_current_segment.call  
        return true
    end 
end