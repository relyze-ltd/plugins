#
# Open this file in the Relyze Plugin Editor and simply select to Run it.
#
require 'relyze/core'

class Plugin < Relyze::Plugin::Analysis

    def initialize
        super( {
            :guid        => '{DDB96384-E696-4FF8-97AC-E5D74EBD8728}',
            :name        => 'Disassemble Arbitrary Bytes',
            :description => 'Simple example to disassemble arbitrary bytes and inspect the decoded instructions raw properties.',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License',
            :references  => [ 'www.relyze.com' ]
        } )
    end

    def disassemble( data, arch, pc=0, mode=nil )

        raw = Relyze::ExecutableFileModel::Instruction::disassemble( data, arch, pc, mode )

        return nil, nil if raw.nil?

        asm = Relyze::ExecutableFileModel::Instruction::to_asm( raw )

        return raw, asm
    end

    def run
        raw, asm = self.disassemble( "\x66\x0F\x3A\xDF\x01\x08", :x86 )
        print_message( "%s\r\n\r\n\t%s\r\n" % [ asm, raw ] )

        raw, asm = self.disassemble( "\x44\x0F\x38\xC8\x00", :x64 )
        print_message( "%s\r\n\r\n\t%s\r\n" % [ asm, raw ] )

        raw, asm = self.disassemble( [ 0x033095E7 ].pack('N'), :arm )
        print_message( "%s\r\n\r\n\t%s\r\n" % [ asm, raw ] )

        raw, asm = self.disassemble( "\x66\x95", :arm, 0, :thumb )
        print_message( "%s\r\n\r\n\t%s\r\n" % [ asm, raw ] )
    end

=begin

aeskeygenassist xmm0, xmmword [ecx], 0x8 

{:mnemonic=>:aeskeygenassist, :arch=>:x86, :pc=>0, :length=>6, 
:vendor=>:any, :_rex=>0, :pfx_rex=>0, :pfx_seg=>0, :pfx_opr=>0, 
:pfx_adr=>0, :pfx_lock=>0, :pfx_str=>0, :pfx_bnd=>0, :pfx_xacquire=>0, 
:pfx_xrelease=>0, :pfx_rep=>0, :pfx_repe=>0, :pfx_repne=>0, 
:opr_mode=>32, :adr_mode=>32, :br_far=>0, :br_near=>0, :have_modrm=>1, 
:modrm=>1, :vex_op=>0, :vex_b1=>0, :vex_b2=>0, :flags=>{:of=>:unchanged, 
:sf=>:unchanged, :zf=>:unchanged, :af=>:unchanged, :pf=>:unchanged, 
:cf=>:unchanged, :tf=>:unchanged, :if=>:unchanged, :df=>:unchanged, 
:nf=>:unchanged, :rf=>:unchanged, :ac=>:unchanged}, 
:operands=>[{:read=>false, :write=>true, :type=>:register, :size=>128, 
:base=>:xmm0, :index=>nil, :scale=>0, :offset=>0, :lval=>{:sbyte=>0, 
:ubyte=>0, :sword=>0, :uword=>0, :sdword=>0, :udword=>0, :sqword=>0, 
:uqword=>0, :ptr_seg=>nil, :ptr_off=>nil}}, {:read=>true, :write=>false, 
:type=>:memory, :size=>128, :base=>:ecx, :index=>nil, :scale=>0, 
:offset=>0, :lval=>{:sbyte=>0, :ubyte=>0, :sword=>0, :uword=>0, 
:sdword=>0, :udword=>0, :sqword=>0, :uqword=>0, :ptr_seg=>nil, 
:ptr_off=>nil}}, {:read=>true, :write=>false, :type=>:immediate, 
:size=>8, :base=>nil, :index=>nil, :scale=>0, :offset=>0, 
:lval=>{:sbyte=>8, :ubyte=>8, :sword=>8, :uword=>8, :sdword=>8, 
:udword=>8, :sqword=>8, :uqword=>8, :ptr_seg=>nil, :ptr_off=>nil}}]} 

sha1nexte xmm8, xmmword [rax] 

{:mnemonic=>:sha1nexte, :arch=>:x64, :pc=>0, :length=>5, :vendor=>:any, 
:_rex=>4, :pfx_rex=>68, :pfx_seg=>0, :pfx_opr=>0, :pfx_adr=>0, 
:pfx_lock=>0, :pfx_str=>0, :pfx_bnd=>0, :pfx_xacquire=>0, 
:pfx_xrelease=>0, :pfx_rep=>0, :pfx_repe=>0, :pfx_repne=>0, 
:opr_mode=>32, :adr_mode=>64, :br_far=>0, :br_near=>0, :have_modrm=>1, 
:modrm=>0, :vex_op=>0, :vex_b1=>0, :vex_b2=>0, :flags=>{:of=>:unchanged, 
:sf=>:unchanged, :zf=>:unchanged, :af=>:unchanged, :pf=>:unchanged, 
:cf=>:unchanged, :tf=>:unchanged, :if=>:unchanged, :df=>:unchanged, 
:nf=>:unchanged, :rf=>:unchanged, :ac=>:unchanged}, 
:operands=>[{:read=>true, :write=>true, :type=>:register, :size=>128, 
:base=>:xmm8, :index=>nil, :scale=>0, :offset=>0, :lval=>{:sbyte=>0, 
:ubyte=>0, :sword=>0, :uword=>0, :sdword=>0, :udword=>0, :sqword=>0, 
:uqword=>0, :ptr_seg=>nil, :ptr_off=>nil}}, {:read=>true, :write=>false, 
:type=>:memory, :size=>128, :base=>:rax, :index=>nil, :scale=>0, 
:offset=>0, :lval=>{:sbyte=>0, :ubyte=>0, :sword=>0, :uword=>0, 
:sdword=>0, :udword=>0, :sqword=>0, :uqword=>0, :ptr_seg=>nil, 
:ptr_off=>nil}}]} 

ldr r3, [r5, r3] 

{:mnemonic=>:ldr, :pc=>4, :length=>0, :arch=>:arm, :cc=>:al, 
:usermode=>false, :update_flags=>false, :writeback=>false, 
:cps_mode=>nil, :cps_flag=>nil, :mem_barrier=>nil, :vector_size=>0, 
:vector_data=>nil, :groups=>[:arm], :operands=>[{:type=>:register, 
:subtracted=>false, :vector_index=>nil, :shift_type=>nil, 
:shift_value=>0, :reg=>:r3, :imm=>nil, :base=>nil, :index=>nil, 
:scale=>nil, :disp=>nil, :fp=>nil, :setend=>nil}, {:type=>:memory, 
:subtracted=>false, :vector_index=>nil, :shift_type=>nil, 
:shift_value=>0, :reg=>nil, :imm=>nil, :base=>:r5, :index=>:r3, 
:scale=>1, :disp=>0, :fp=>nil, :setend=>nil}]} 

str r5, [sp, #0x198] 

{:mnemonic=>:str, :pc=>2, :length=>0, :arch=>:arm, :cc=>:al, 
:usermode=>false, :update_flags=>false, :writeback=>false, 
:cps_mode=>nil, :cps_flag=>nil, :mem_barrier=>nil, :vector_size=>0, 
:vector_data=>nil, :groups=>[:thumb, :thumb1only], 
:operands=>[{:type=>:register, :subtracted=>false, :vector_index=>nil, 
:shift_type=>nil, :shift_value=>0, :reg=>:r5, :imm=>nil, :base=>nil, 
:index=>nil, :scale=>nil, :disp=>nil, :fp=>nil, :setend=>nil}, 
{:type=>:memory, :subtracted=>false, :vector_index=>nil, 
:shift_type=>nil, :shift_value=>0, :reg=>nil, :imm=>nil, :base=>:sp, 
:index=>nil, :scale=>1, :disp=>408, :fp=>nil, :setend=>nil}]} 

=end

end
