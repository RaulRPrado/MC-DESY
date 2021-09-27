#!/bin/bash

# Utilities functions

error_exit()
{
    echo "$1" 1>&2
    exit 1
}

check_file()
{
    if [ ! -f "$1" ]; then
        error_exit "File $1 does not exist - aborting"
    fi
}

check_and_create_dir()
{
    if [ ! -d "$1" ]; then
        echo "Creating directory $1"
        mkdir -p "$1"
    fi
}

remove_file()
{
    for file in "$@"; do
        if [ -f "$file" ]; then
            rm "$file"
        fi
    done
}


config_dir()
{
    local source_dir=$1
    echo "${source_dir}/config"
}

print_runtime()
{
    # Print the runtime in a nice format
    # for a given number of seconds
    local seconds=$1
    local days
    local days=$(( seconds / 86400 ))
    printf "Runtime: %s:" "${days}"
    TZ=UTC0 printf '%(%H:%M:%S)T\n' "${1}"
    printf "Seconds: %s\n" "${1}"
}

file_size()
{
    # Print file size in G
    local file=$1
    local size
    size=$(stat -c%s "${file}")
    echo $(( size / 1000000))
}

collect_arguments()
{
    # Collect arguments from $@
    # Usage: collect_aruments number_of_arguments arg1 arg2 arg3 ... S@
    local n_args=$1
    shift
    local pars=""
    for i in $(seq 1 "${n_args}"); do
        pars="${pars} $1"
        shift
    done

    # shellcheck disable=SC2068    
    for arg in $@; do
        found_par="false"
        for par in ${pars}; do
            if [ "${arg}" = "-${par}" ]; then
                shift
                eval "${par}"="${1}"
                shift
                found_par="true"
            fi
        done
        
        if [ "${found_par}" = "false" ] && [ "${arg:0:1}" = "-" ]; then
            error_exit "collect_arguments: wrong input ${arg}"
        fi

    done  
}


#############
# VALIDATIONS

validate_wobble_direction()
{
    # shellcheck disable=SC2140 
    if ! [[ "$1" =~ ^("north"|"south"|"east"|"west"|"all")$ ]]; then
        error_exit "Wobble direction option is invalid - aborting"
    else
        echo "$1"
    fi
}

wobble_direction()
{
    # Return wobble direction (north, south, east or west)
    # for a given run number
    local run=$1
    local wd=""
    case "$(echo "${run}%4" | bc)" in
        0)
            wd="north"
            ;;
        1)
            wd="east"
            ;;
        2)
            wd="south"
            ;;
        3)
            wd="west"
            ;;
    esac
    echo "$wd"
}

validate_zenith()
{
    local zenith=$1
    for z in 0 00 20 30 35 40 45 50 55 60 65 70; do
        if [ "${zenith}" = "${z}" ]; then
            if [ "${zenith}" = "0" ]; then
                z=00
            fi
            echo "${z}"
            return
        fi
    done
    error_exit "zenith option is invalid - aborting"
}

validate_atm()
{
    if [ "$1" == "summer" ] || [ "$1" == "62" ]; then
        echo "summer"
    elif [ "$1" == "winter" ] || [ "$1" == "61" ]; then
        echo "winter"
    else
        error_exit "Atm option is invalid - aborting"
    fi
}

get_atm_number()
{
    if [ "$1" == "summer" ] || [ "$1" == "62" ]; then
        echo "62"
    elif [ "$1" == "winter" ] || [ "$1" == "61" ]; then
        echo "61"
    else
        error_exit "Atm option is invalid - aborting"
    fi
}

validate_wobble()
{
    # Validate wobble, return in a fixed format
    # 2 digits of precision maximum
    
    if [ "$1" == "" ]; then
        error_exit "Wobble option is invalid - aborting"
    fi
 
    local wob
    local out_wobble
    wob=$(echo "$1" | bc -l)
    if [ "$(echo "${wob} == 0" | bc -l)" = "1" ]; then
        out_wobble="0.0"
    elif [ "$(echo "${wob} == 1.0" | bc -l)" = "1" ]; then
        out_wobble="1.0"
    elif [ "$(echo "${wob} < 1.0" | bc -l)" = "1" ]; then
        w=${wob:0:3}
        out_wobble="0$w"
    else
        out_wobble="${wob:0:4}"
    fi

    if ! [[ "${out_wobble}" =~ ^("0.0"|"0.25"|"0.5"|"0.75"|"1.0"|"1.25"|"1.5"|"1.75"|"2.0")$ ]]; then
        error_exit "Wobble option is invalid - aborting"
    else
        echo "${out_wobble}"
    fi

}

validate_mode()
{
    # CARE mode: std or rhv (Reduced High Voltage)
    local mode=$1
    if [ "${mode}" != "std" ] && [ "${mode}" != "rhv" ]; then
        error_exit "Mode option is invalid - aborting"
    else
        echo "${mode}"
    fi
}

validate_primary()
{
    # Only proton is allowed by now
    local prim=$1
    if [ "${prim}" != "proton" ]; then
        error_exit "primary option is invalid - aborting"
    else
        echo "${prim}"
    fi
}

nsb_list_from_group()
{
    # NSb groups are a, b or c
    local group=$1
    if [ "${group}" = "a" ] || [ "${group}" = "A" ]; then
        echo "50 75 100 130"
    elif [ "${group}" = "b" ] || [ "${group}" = "B" ]; then
        echo "160 200 250 300"
    elif [ "${group}" = "c" ] || [ "${group}" = "C" ]; then
        echo "350 400 450"
    elif [ "${group}" = "all" ] || [ "${group}" = "ALL" ]; then
        echo "50 75 100 130 160 200 250 300 350 400 450"
    else
        error_exit "NSB group invalid"
    fi
}

compute_run()
{
    # Compute run number for a given zenith
    # and sequencial number i
    local zenith=$1
    local i=$2
    if [ "${zenith}" == "00" ]; then
        echo "10$(( i + 5000 ))"
    else
        echo "${zenith}$(( i + 5000 ))"
    fi
}


############
# DIRECTORIES

atm_directory()
{
    if [ "$1" = "winter" ]; then
        echo "Atmosphere61"
    elif [ "$1" = "summer" ]; then
        echo "Atmosphere62"
    fi
}


zenith_directory()
{
    local zenith=$1
    echo "Zd${zenith}"
}

#############
# GROPTICS

groptics_file()
{
    local run=$1
    local zenith=$2
    local atm=$3
    local wobble=$4
    local atm_dir
    atm_dir=$(atm_directory "${atm}")
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")
    
    echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/groptics/wobble${wobble}/Data/DAT${run}.root"

    # echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/groptics/wobble${wobble}/Data/DAT${run}.root"
}

groptics_log()
{
    # Label should be out or err
    local run=$1
    local zenith=$2
    local atm=$3
    local wobble=$4
    local label=$5
    local atm_dir
    atm_dir=$(atm_directory "${atm}")
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")
    
    echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/groptics/wobble${wobble}/Log/run${run}/log_${run}.${label}"

    # echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/groptics/wobble${wobble}/Log/run${run}/log_${run}.${label}"

}

gro_pilot_file()
{
    # Return GrOptics pilot file for a given wobble offset and direction
    # File is created if it does not exists, unless force=true
    local source_dir=$1
    local wobble=$2
    local wd=$3
    local force=$4

    local cfg_dir
    cfg_dir=$(config_dir "${source_dir}")

    local file="${cfg_dir}/GrOptics/GrOpticsV6pilot_wob${wobble}_${wd}.txt"

    if [ "${force}" = "true" ] || [ ! -f "${file}" ]; then
        local gen_file="${cfg_dir}/GrOptics/GrOpticsV6pilot_generic.txt"
        cp "${gen_file}" "${file}"
        sed -i -e 's/X'"${wd}"'X/*/g' "${file}"
        sed -i -e 's/XWX/'"${wobble}"'/g' "${file}"
    fi
    echo "${file}"
}

config_atm()
{
    local source_dir=$1
    local atm=$2
    local cfg_dir
    cfg_dir=$(config_dir "${source_dir}")
    if [ "${atm}" = "summer" ]; then
        echo "${cfg_dir}/GrOptics/Ext_results_VSummer_6_1_6.M5.txt"
    elif [ "${atm}" =  "winter" ]; then
        echo "${cfg_dir}/GrOptics/Ext_results_VWinter_3_2_6.M5.txt"
    fi
}


config_ioreader()
{
    local source_dir=$1
    local cfg_dir
    cfg_dir=$(config_dir "${source_dir}")
    echo "${cfg_dir}/GrOptics/IOReaderDetectorConfigV6.txt"
}

#############
# CORSIKA

corsika_directory_zip()
{
    # Return directory of zipped corsika file
    local zenith=$1
    local atm=$2
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")
    local atm_dir
    atm_dir=$(atm_directory "${atm}")

    echo "/lustre/fs24/group/veritas/simulations/CORSIKA/${atm_dir}/${zenith_dir}/telfiles"    
    # echo "/lustre/fs23/group/veritas/simulations/V6_FLWO/OSG_CORSIKA/${atm_dir}/corsika/${zenith_dir}"    
}

corsika_file_zip()
{
    local run=$1
    local zenith=$2
    local atm=$3
    local corsika_dir
    corsika_dir=$(corsika_directory_zip "${zenith}" "${atm}")

    echo "${corsika_dir}/DAT${run}.telescope"
}

corsika_directory()
{
    local zenith=$1
    local atm=$2
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")
    local atm_dir
    atm_dir=$(atm_directory "${atm}")

    echo "/lustre/fs24/group/veritas/simulations/CORSIKA/${atm_dir}/${zenith_dir}/telfiles"    
    # echo "/lustre/fs23/group/veritas/V6_DESY/OSG_CORSIKA/${atm_dir}/corsika/${zenith_dir}"    
}

corsika_file()
{
    local run=$1
    local zenith=$2
    local atm=$3
    local corsika_dir
    corsika_dir=$(corsika_directory "${zenith}" "${atm}")

    echo "${corsika_dir}/DAT${run}.telescope"
}

## Proton stuff

compute_proton_run()
{
    # Compute run number for a given zenith
    # and sequencial number i
    local i=$1
    echo "10$(( i + 5000 ))"
}

corsika_proton_directory()
{
    local label=$1
    echo "/lustre/fs23/group/veritas/V6_DESY/proton/${label}/corsika"    
}

corsika_proton_file()
{
    local label=$1
    local run=$2
    local corsika_dir
    corsika_dir=$(corsika_proton_directory "${label}")

    echo "${corsika_dir}/DAT${run}.telescope"
}

corsika_proton_input()
{
    local label=$1
    local run=$2
    local corsika_dir
    corsika_dir=$(corsika_proton_directory "${label}")

    echo "${corsika_dir}/input/DAT${run}.inp"
}

corsika_proton_log()
{
    local label=$1
    local run=$2
    local type=$3
    local corsika_dir
    corsika_dir=$(corsika_proton_directory "${label}")

    echo "${corsika_dir}/log/DAT${run}.${type}"
}

corsika_tel_positions()
{
    local cfg_dir
    cfg_dir=$(config_dir)
    echo "${cfg_dir}/CORSIKA/TelPOS_VERITAS.txt"
}

atm_config_file()
{
    local atm=$1
    if [ "${atm}" = "winter" ]; then
        local number="61"
    else
        local number="62"
    fi
    local cfg_dir
    cfg_dir=$(config_dir)
    echo "${cfg_dir}/CORSIKA/atmprof${number}.dat"
}

############
# CARE

care_config_file()
{
    local source_dir=$1
    local mode=$2
    cfg_dir=$(config_dir "${source_dir}")
    if [ "${mode}" = "std" ]; then
        # echo "${cfg_dir}/CARE/CARE_V6_Std.txt"
        echo "${cfg_dir}/CARE/CARE_VERITAS_AfterPMTUpgrade_V6Nahee_withPMTransitTimeSpread.cfg"
    else
        echo "${cfg_dir}/CARE/CARE_V6_RHV.txt"
    fi
}

care_high_gain()
{
    local source_dir=$1
    cfg_dir=$(config_dir "${source_dir}")
    echo "${cfg_dir}/CARE/VERITASHighGainPulseShapeHamamatsuPMT.txt"
}

care_low_gain()
{
    local source_dir=$1
    cfg_dir=$(config_dir "${source_dir}")
    echo "${cfg_dir}/CARE/VERITASLowGainPulseShapeHamamatsuPMT.txt"
}

care_file()
{
    local run=$1
    local zenith=$2
    local atm=$3
    local wobble=$4
    local nsb=$5
    local mode=$6
    local atm_dir
    atm_dir=$(atm_directory "${atm}")
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")

    # echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/care_${mode}/wobble${wobble}/Data/NSB${nsb}/CARE${run}"

    echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/care_${mode}/wobble${wobble}/Data/NSB${nsb}/CARE${run}"
}

care_log()
{
    local run=$1
    local zenith=$2
    local atm=$3
    local wobble=$4
    local nsb=$5
    local mode=$6
    local label=$7
    local atm_dir
    atm_dir=$(atm_directory "${atm}")
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")

    # echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/care_${mode}/wobble${wobble}/Log/NSB${nsb}/log_${run}.${label}"

    echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/care_${mode}/wobble${wobble}/Log/NSB${nsb}/log_${run}.${label}"
}

merged_root_name()
{
    local zenith=$1
    local atm=$2
    local wobble=$3
    local nsb=$4
    local mode=$5
    local atm_dir
    atm_dir=$(atm_directory "${atm}")
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")

    # echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/merged/Data/gamma_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz"
    
    # echo "/lustre/fs18/group/cta/veritas/NSOffsetSimulations/${atm_dir}/${zenith_dir}/gamma_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz"
    
    echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/gamma_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz"
}

merged_care_file()
{
    local zenith=$1
    local atm=$2
    local wobble=$3
    local nsb=$4
    local mode=$5
    local n_merge=$6
    local atm_dir
    name=$(merged_root_name "${zenith}" "${atm}" "${wobble}" "${nsb}" "${mode}")

    if [ "${n_merge}" == "" ]; then
        echo "${name}.vbf"
    else
        echo "${name}_${n_merge}.vbf" 
    fi
}

compressed_care_file()
{
    local zenith=$1
    local atm=$2
    local wobble=$3
    local nsb=$4
    local mode=$5
    local atm_dir
    name=$(merged_root_name "${zenith}" "${atm}" "${wobble}" "${nsb}" "${mode}")
    echo "${name}.vbf.bz2"
}

merged_care_log()
{
    local zenith=$1
    local atm=$2
    local wobble=$3
    local nsb=$4
    local mode=$5
    local label=$6
    local n_merge=$7
    local atm_dir
    atm_dir=$(atm_directory "${atm}")
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")

    if [ "${n_merge}" == "" ]; then
        echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/merged/Log/log_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz.${label}"
        
        # echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/merged/Log/log_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz.${label}"
    else
        echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/merged/Log/log_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz_${n_merge}.${label}"

        # echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/merged/Log/log_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz_${n_merge}.${label}"
    fi
}

split_care_log()
{
    local zenith=$1
    local atm=$2
    local wobble=$3
    local nsb=$4
    local mode=$5
    local label=$6
    local atm_dir
    atm_dir=$(atm_directory "${atm}")
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")

    # echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/split/Log/log_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz.${label}"

    echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/split/Log/log_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz.${label}"

}


compressed_care_log()
{
    local zenith=$1
    local atm=$2
    local wobble=$3
    local nsb=$4
    local mode=$5
    local label=$6
    local atm_dir
    atm_dir=$(atm_directory "${atm}")
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")

    echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/merged/Log/compressed_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz.${label}"

    # echo "/lustre/fs24/group/veritas/simulations/NSOffsetSimulations/${atm_dir}/${zenith_dir}/merged/Log/compressed_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz.${label}"
}
