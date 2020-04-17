require 'relyze/core'

class Plugin < Relyze::Plugin::Loader

    def initialize
        super( {
            :guid        => '{F7AE56EF-4B07-4935-A87D-639D1ED2B26C}',
            :name        => 'MCLF',
            :description => 'Load MobiCore Load Format (MCLF) v2 binaries',
            :authors     => [ 'Relyze Software Limited' ],
            :license     => 'Relyze Plugin License'
        } )
    end
    
    def self.query( buffer )

        magic, version_minor, version_major = buffer.unpack( 'Vvv' )
        
        return nil if magic != 0x464C434D
        
        return nil if version_major != 2
        
        return {
            :title        => 'MobiCore Load Format (MCLF)',
            :type         => :mclf,
            :arch         => :arm,
            :endian       => :little,
            :arch_mode    => :auto,
            :platform     => :unknown,
            :base_address => 0
        }
    end
    
    def load
    
        # unpack the header structure...
        magic,
        version_minor,
        version_major,
        flags,
        mem_type,
        service_type,
        num_instances,
        uuid,
        driver_id,
        num_threads,
        text_start,
        text_len,
        data_start,
        data_len,
        bss_len,
        entry,
        service_version = cm.buffer.unpack( 'VvvVVVVa16VVVVVVVVV' )
        
        # add in some information items to the model (this will be displayed in the UI overview)...
        cm.add_information(
            Relyze::FileModel::Information.new( {
                :group => :analysis,
                :title => 'MCLF Version',
                :data  => "#{version_major}.#{version_minor}"
            } )
        )
                
        flags_str = []
        flags_str << 'MC_SERVICE_HEADER_FLAGS_PERMANENT' if flags & 1 == 1
        flags_str << 'MC_SERVICE_HEADER_FLAGS_NO_CONTROL_INTERFACE' if flags & 2 == 2
        flags_str << 'MC_SERVICE_HEADER_FLAGS_DEBUGGABLE' if flags & 4 == 4
        flags_str << 'MC_SERVICE_HEADER_FLAGS_EXTENDED_LAYOUT' if flags & 8 == 8
        
        cm.add_information(
            Relyze::FileModel::Information.new( {
                :group => :analysis,
                :title => 'MCLF Flags',
                :data  => "0x#{flags.to_s( 16 )} (#{flags_str.join( ' | ' )})"
            } )
        )
        
        mt = [ 
            'MCLF_MEM_TYPE_INTERNAL_PREFERRED', 
            'MCLF_MEM_TYPE_INTERNAL', 
            'MCLF_MEM_TYPE_EXTERNAL' 
        ][mem_type]
        
        if( not mt.nil? )
            cm.add_information(
                Relyze::FileModel::Information.new( {
                    :group => :analysis,
                    :title => 'MCLF Mem Type',
                    :data  => mt
                } )
            )
        end
        
        st = [ 
            'SERVICE_TYPE_ILLEGAL', 
            'SERVICE_TYPE_DRIVER', 
            'SERVICE_TYPE_SP_TRUSTLET',
            'SERVICE_TYPE_SYSTEM_TRUSTLET', 
            'SERVICE_TYPE_MIDDLEWARE', 
            'SERVICE_TYPE_LAST_ENTRY' 
        ][service_type.to_i]
        
        if( not st.nil? )
            cm.add_information(
                Relyze::FileModel::Information.new( {
                    :group => :analysis,
                    :title => 'MCLF Service Type',
                    :data  => st
                } )
            )
        end
        
        cm.add_information(
            Relyze::FileModel::Information.new( {
                :group => :analysis,
                :title => 'MCLF UUID',
                :data  => uuid.unpack( 'H*' ).first
            } )
        )
        
        cm.add_information(
            Relyze::FileModel::Information.new( {
                :group => :analysis,
                :title => 'MCLF Driver ID',
                :data  => '0x' + driver_id.to_s( 16 )
            } )
        )
        
        # add in some markers for the entropy graph in the UI overview...
        cm.add_entropy_marker( ".text", 0, text_len )
        
        cm.add_entropy_marker( ".data", text_len, data_len )
        
        # create the segments...
        seg = cm.add_segment( ".text", cm.va2rva( text_start ), text_len, 0, true, false, true )
        
        seg.write_buffer( 0, cm.buffer[0, text_len] )
        
        seg = cm.add_segment( ".data", cm.va2rva( data_start ), data_len, 0, true, false, false )
        
        seg.write_buffer( 0, cm.buffer[text_len, data_len] )
        
        cm.add_segment( ".bss", cm.va2rva( data_start + data_len ), 0, bss_len, true, true, false )
        
        # use the C headers to generate some new data types
        self.load_type_headers

        header_type = 'mclfHeader_t'
        if( version_minor >= 3 )
            header_type = 'mclfHeaderV23_t'
            if( version_minor >= 4 )
                header_type = 'mclfHeaderV24_t'
            end
        end
        
        # add the header structures to the analysis queue...
        cm.analysis_queue_push( :data, cm.va2rva( text_start ), "header", cm.dtf[header_type] )
        
        cm.analysis_queue_push( :data, cm.va2rva( text_start + 0x80 ), "text_header", cm.dtf['mclfTextHeader_t'] )
        
        # add in the initial entry point to the analysis queue...
        cm.analysis_queue_push( :function, cm.va2rva( entry ), "entry" )
        
        return true
    end
    
    def load_type_headers
        # https://raw.githubusercontent.com/Trustonic/trustonic-tee-user-space/master/common/MobiCore/inc/mcUuid.h
        cm.dtf.add( %{
/*
 * Copyright (c) 2013-2015 TRUSTONIC LIMITED
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the TRUSTONIC LIMITED nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MC_UUID_H_
#define MC_UUID_H_

#ifdef WIN32
#define _UNUSED
#else
#define _UNUSED __attribute__((unused))
#endif

#define UUID_TYPE

#define UUID_LENGTH 16
/** Universally Unique Identifier (UUID) according to ISO/IEC 11578. */
typedef struct {
    uint8_t value[UUID_LENGTH]; /**< Value of the UUID. */
} mcUuid_t, *mcUuid_ptr;

/** UUID value used as free marker in service provider containers. */
#define MC_UUID_FREE_DEFINE \
    { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, \
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF }

static _UNUSED const mcUuid_t MC_UUID_FREE = {
    MC_UUID_FREE_DEFINE
};

/** Reserved UUID. */
#define MC_UUID_RESERVED_DEFINE \
    { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, \
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }

static _UNUSED const mcUuid_t MC_UUID_RESERVED = {
    MC_UUID_RESERVED_DEFINE
};

/** UUID for system applications. */
#define MC_UUID_SYSTEM_DEFINE \
    { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, \
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE }

static _UNUSED const mcUuid_t MC_UUID_SYSTEM = {
    MC_UUID_SYSTEM_DEFINE
};

#define MC_UUID_RTM_DEFINE \
    { 0x12, 0x34, 0x12, 0x34, 0x12, 0x34, 0x12, 0x34,       \
      0x12, 0x34, 0x12, 0x34, 0x12, 0x34, 0x12, 0x34 }

static _UNUSED const mcUuid_t MC_UUID_RTM = {
    MC_UUID_RTM_DEFINE
};

/**
 * TODO: Replace with v5 UUID (milestone #3)
 */
#define LTA_UUID_DEFINE \
    { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,         \
      0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11}

#endif // MC_UUID_H_
        } )
        
        # https://github.com/Trustonic/trustonic-tee-user-space/blob/master/common/MobiCore/inc/mcSuid.h
        cm.dtf.add( %{
/*
 * Copyright (c) 2013-2015 TRUSTONIC LIMITED
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the TRUSTONIC LIMITED nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MC_SUID_H_
#define MC_SUID_H_

/** Length of SUID. */
#define MC_SUID_LEN    16

/** Platform specific device identifier (serial number of the chip). */
typedef struct {
    uint8_t data[MC_SUID_LEN - sizeof(uint32_t)];
} suidData_t;

/** Soc unique identifier type. */
typedef struct {
    uint32_t    sipId;  /**< Silicon Provider ID to be set during build. */
    suidData_t  suidData;
} mcSuid_t;

#endif // MC_SUID_H_
        } )
        
        # https://github.com/Trustonic/trustonic-tee-user-space/blob/master/common/MobiCore/inc/mcDriverId.h
        cm.dtf.add( %{
/*
 * Copyright (c) 2013-2015 TRUSTONIC LIMITED
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the TRUSTONIC LIMITED nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef RTMDRVID_H_
#define RTMDRVID_H_

#define MC_DRV_VENDOR_ID_SHIFT     (16)
#define MC_DRV_VENDOR_ID_MASK      (0xFFFF << MC_DRV_VENDOR_ID_SHIFT)
#define MC_DRV_NUMBER_MASK         (0x0000FFFF)

/** MobiCore vendor IDs. */
typedef enum {
    MC_DRV_VENDOR_ID_GD   = 0 << MC_DRV_VENDOR_ID_SHIFT,
} mcDrvVendorId_t;

/** MobiCore GD driver numbers. */
typedef enum {
    MC_DRV_NUMBER_INVALID = 0,
    MC_DRV_NUMBER_CRYPTO  = 1,
    /** Last GD driver number reserved for pre-installed drivers.
     * GD driver numbers up to this constant may not be used for loadable drivers. */
    MC_DRV_NUMBER_LAST_PRE_INSTALLED = 100,
    TB_DRV_NUMBER_TUI  = 0x101,
    TB_DRV_NUMBER_TPLAY  = 0x600,
} mcDrvNumber_t;

/** MobiCore driver IDs for Trustlets. */
typedef enum {
    MC_DRV_ID_INVALID = MC_DRV_VENDOR_ID_GD | MC_DRV_NUMBER_INVALID,
    MC_DRV_ID_CRYPTO  = MC_DRV_VENDOR_ID_GD | MC_DRV_NUMBER_CRYPTO,
    /** Last GD driver ID reserved for pre-installed drivers.
     * GD driver IDs up to this constant may not be used for loadable drivers. */
    MC_DRV_ID_LAST_PRE_INSTALLED = MC_DRV_VENDOR_ID_GD | MC_DRV_NUMBER_LAST_PRE_INSTALLED,
    TB_DRV_ID_TUI  = MC_DRV_VENDOR_ID_GD | TB_DRV_NUMBER_TUI,
    TB_DRV_ID_TPLAY  = MC_DRV_VENDOR_ID_GD | TB_DRV_NUMBER_TPLAY,
} mcDriverId_t;

#endif /* RTMDRVID_H_ */
        } )
        
        # https://github.com/Trustonic/trustonic-tee-user-space/blob/master/common/MobiCore/inc/mcLoadFormat.h
        cm.dtf.add( %{
/*
 * Copyright (c) 2013-2015 TRUSTONIC LIMITED
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the TRUSTONIC LIMITED nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef MCLOADFORMAT_H_
#define MCLOADFORMAT_H_

#include "mcUuid.h"
#include "mcSuid.h"
#include "mcDriverId.h"

#define MCLF_VERSION_MAJOR   2
#define MCLF_VERSION_MINOR   5
#define MCLF_VERSION_MINOR_CURRENT   3

#define MC_SERVICE_HEADER_MAGIC_BE         ((uint32_t)('M'|('C'<<8)|('L'<<16)|('F'<<24))) /**< "MCLF" in big endian integer representation */
#define MC_SERVICE_HEADER_MAGIC_LE         ((uint32_t)(('M'<<24)|('C'<<16)|('L'<<8)|'F')) /**< "MCLF" in little endian integer representation */
#define MC_SERVICE_HEADER_MAGIC_STR         "MCLF"                                        /**< "MCLF" as string */

/** @name MCLF flags */
#define MC_SERVICE_HEADER_FLAGS_PERMANENT               (1U << 0) /**< Loaded service cannot be unloaded from MobiCore. */
#define MC_SERVICE_HEADER_FLAGS_NO_CONTROL_INTERFACE    (1U << 1) /**< Service has no WSM control interface. */
#define MC_SERVICE_HEADER_FLAGS_DEBUGGABLE              (1U << 2) /**< Service can be debugged. */
#define MC_SERVICE_HEADER_FLAGS_EXTENDED_LAYOUT          (1U << 3) /**< New-layout trusted application or trusted driver. */


/** Service type.
 * The service type defines the type of executable.
 */
typedef enum {
    SERVICE_TYPE_ILLEGAL         = 0, /**< Service type is invalid. */
    SERVICE_TYPE_DRIVER          = 1, /**< Service is a driver. */
    SERVICE_TYPE_SP_TRUSTLET     = 2, /**< Service is a Trustlet. */
    SERVICE_TYPE_SYSTEM_TRUSTLET = 3, /**< Service is a system Trustlet. */
    SERVICE_TYPE_MIDDLEWARE      = 4, /**< Service is a middleware. */
    SERVICE_TYPE_LAST_ENTRY      = 5, /**< marker for last entry */
} serviceType_t;

/**
 * Memory types.
 */
typedef enum {
    MCLF_MEM_TYPE_INTERNAL_PREFERRED = 0, /**< If available use internal memory; otherwise external memory. */
    MCLF_MEM_TYPE_INTERNAL = 1, /**< Internal memory must be used for executing the service. */
    MCLF_MEM_TYPE_EXTERNAL = 2, /**< External memory must be used for executing the service. */
} memType_t;

/**
 * Descriptor for a memory segment.
 */
typedef struct {
    void *    start;  /**< Virtual start address. */
    uint32_t    len;    /**< Length of the segment in bytes. */
} segmentDescriptor_t, *segmentDescriptor_ptr;

/**
 * MCLF intro for data structure identification.
 * Must be the first element of a valid MCLF file.
 */
typedef struct {
    uint32_t        magic;      /**< Header magic value ASCII "MCLF". */
    uint32_t        version;    /**< Version of the MCLF header structure. */
} mclfIntro_t, *mclfIntro_ptr;


// Version 2 /////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @defgroup MCLF_VER_V2   MCLF Version 32
 * @ingroup MCLF_VER
 *
 * @addtogroup MCLF_VER_V2
 */

/**
 * Version 2.1/2.2 MCLF header.
 */
typedef struct {
    mclfIntro_t             intro;           /**< MCLF header start with the mandatory intro. */
    uint32_t                flags;           /**< Service flags. */
    memType_t               memType;         /**< Type of memory the service must be executed from. */
    serviceType_t           serviceType;     /**< Type of service. */

    uint32_t                numInstances;    /**< Number of instances which can be run simultaneously. */
    mcUuid_t                uuid;            /**< Loadable service unique identifier (UUID). */
    mcDriverId_t            driverId;        /**< If the serviceType is SERVICE_TYPE_DRIVER the Driver ID is used. */
    uint32_t                numThreads;      /**<
                                              * <pre>
                                              * <br>Number of threads (N) in a service depending on service type.<br>
                                              *
                                              *   SERVICE_TYPE_SP_TRUSTLET: N = 1
                                              *   SERVICE_TYPE_SYSTEM_TRUSTLET: N = 1
                                              *   SERVICE_TYPE_DRIVER: N >= 1
                                              * </pre>
                                              */
    segmentDescriptor_t     text;           /**< Virtual text segment. */
    segmentDescriptor_t     data;           /**< Virtual data segment. */
    uint32_t                bssLen;         /**< Length of the BSS segment in bytes. MUST be at least 8 byte. */
    void *                entry;          /**< Virtual start address of service code. */
    uint32_t                serviceVersion; /**< Version of the interface the driver exports. */

// These should be put on next MCLF update:
//    mcSuid_t                permittedSuid;  /**< Starting 2.3: If nonzero, suid which is allowed to execute binary */
//    uint32_t                permittedHwCf;  /**< Starting 2.3: If nonzero, hw configuration which is allowed to execute binary */

} mclfHeaderV2_t, *mclfHeaderV2_ptr;


/**
 * Version 2.3 MCLF header.
 */
typedef struct {
    mclfHeaderV2_t          mclfHeaderV2;
    mcSuid_t                permittedSuid;  /**< Starting 2.3: If nonzero, suid which is allowed to execute binary */
    uint32_t                permittedHwCfg; /**< Starting 2.3: If nonzero, hw configuration which is allowed to execute binary */
} mclfHeaderV23_t, *mclfHeaderV23_ptr;


/**
 * Version 2.4 MCLF header.
 */
typedef struct {
    mclfHeaderV23_t         mclfHeaderV2;
    uint32_t                gp_level;           /**<Starting 2.4: 0 for legacy MobiCore trustlets and 1 for Potato TAs. */
    uint32_t                attestationOffset;  /**<Starting 2.4: Offset of attestation data area. */

} mclfHeaderV24_t, *mclfHeaderV24_ptr;



/*
 * HEAP parameters
 */

typedef struct {
    uint32_t    init;
    uint32_t    max;
} heapSize_t, *heapSize_ptr;

/*
 * McLib Internal Management Data
 * This structure defines the parameters of a buffer used internally by McLib for each TA/TDriver
 * and it specifies default heap parameters (for MCLF header versions >=2.5)
 *
 * `mcLibData` field describes McLib work buffer
 * and it is used for MCLF header versions <=2.4
 * In this case the buffer is a part of TA BSS section
 *
 * For MCLF header versions >=2.5 `mcLibData` field is not used anymore and
 * replaced by `mcLibData` field
 * RTM itself determines actual address in this case and sets `mcLibData` field value
 *
 * `heapSize` field describes default heap parameters and
 *  it is used only for MCLF header versions >=2.5
 *
 */

typedef struct {
    union {
        segmentDescriptor_t     mcLibData;  /**< Segment for McLib data.
                                                 Set at compile time.
                                                 Required always. */
        heapSize_t              heapSize;   /**< Initial and maximum heap sizes.
                                                 Set by MobiConvert for extended-layout TAs */
    } cfg;
    void *                    mcLibBase;  /**< McLib base address.
                                                 Mobicore sets at load time for trustlets / drivers.
                                                 Required always. */
} mclfIMD_t, *mclfIMD_ptr;



/**
 * Version 2 MCLF text segment header.
 * Required to be present in MobiCore 1.2 components at address (0x1080).
 * This extension is initialized already at trustlet compile time,
 * but may be modified later by configuration tools and by MobiCore at load time.
 */
typedef struct {
    uint32_t                version;        /**< Version of the TextHeader structure. */
    uint32_t                textHeaderLen;  /**< Size of this structure (fixed at compile time) */
    uint32_t                requiredFeat;   /**< Flags to indicate features that Mobicore must understand/interprete when loading.
                                                 Required always. */
    void *                mcLibEntry;     /**< Address for McLib entry.
                                                 Mobicore sets at load time for trustlets / drivers.
                                                 Required always. */
    mclfIMD_t               mcIMD;          /**< McLib Internal Management Data */
    uint32_t                tlApiVers;      /**< TlApi version used when building trustlet.
                                                 Value set at compile time.
                                                 Required always. */
    uint32_t                drApiVers;      /**< DrApi version used when building trustlet.
                                                 Value set at compile time for drivers. 0 for trustlets.
                                                 Required always. */
    void *                ta_properties;  /**< address of _TA_Properties in the TA. */
} mclfTextHeader_t, *mclfTextHeader_ptr;

// Version 2 ///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @addtogroup MCLF
 */

/** MCLF header */
typedef union {
    mclfIntro_t    intro;           /**< Intro for data structure identification. */
    mclfHeaderV2_t mclfHeaderV2;    /**< Version 2 header */
} mclfHeader_t, *mclfHeader_ptr;

// Version 2.3 changes header definition
// Above structure is hard-coded into many places.
// So new changes are made into separate structure.
#define MCLF_HEADER_SIZE_V23 (0x080)

// Actual (known) length can be calculated using macro
#define MCLF_HEADER_SIZE(version) ((version)>0x20002?(MCLF_HEADER_SIZE_V23):sizeof(mclfHeader_t))

// This is only minimum size, so nothing below this makes sense.
#define MCLF_BINARY_MIN_SIZE(version) (MCLF_HEADER_SIZE_V23+sizeof(mclfTextHeader_t))

#endif /* MCLOADFORMAT_H_ */
        } )
    end
end
