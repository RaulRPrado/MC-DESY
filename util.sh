#!/bin/bash

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
    echo "/afs/ifh.de/group/cta/scratch/prado/MC-VERITAS/config"
}

print_runtime()
{
    local days
    local days=$(( $1 / 86400 ))
    printf "Runtime: %s:" "${days}"
    TZ=UTC0 printf '%(%H:%M:%S)T\n' "${1}"
    printf "Seconds: %s\n" "${1}"
}

file_size()
{
    local file=$1
    local size
    size=$(stat -c%s "${file}")
    echo $(( size / 1000000))
}

collect_arguments()
{
    local n_args=$1
    shift
    local pars=""
    for i in $(seq 1 "${n_args}"); do
        pars="${pars} $1"
        shift
    done

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
            error_exit "collect_arguments: wrong input par"
        fi

    done  
}


#############
# VALIDATIONS

validate_wobble_direction()
{
    if ! [[ "$1" =~ ^("north"|"south"|"east"|"west"|"all")$ ]]; then
        error_exit "Wobble direction option is invalid - aborting"
    else
        echo "$1"
    fi
}

wobble_direction()
{
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
    for z in 0 20 30 35 40 45 50 55 60 65 70; do
        if [ "${zenith}" = "${z}" ]; then
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

validate_wobble()
{
    local wob
    wob=$(echo "$1" | bc -l)
    if [ "$(echo "${wob} == 0" | bc -l)" = "1" ]; then
        echo "0.0"
    elif [ "$(echo "${wob} == 1.0" | bc -l)" = "1" ]; then
        echo "1.0"
    elif [ "$(echo "${wob} < 1.0" | bc -l)" = "1" ]; then
        w=${wob:0:3}
        echo "0$w"
    else
        echo "${wob:0:4}"
    fi
}

validate_mode()
{
    local mode=$1
    if [ "${mode}" != "std" ] && [ "${mode}" != "rhv" ]; then
        error_exit "Mode option is invalid - aborting"
    else
        echo "${mode}"
    fi
}

validate_primary()
{
    local prim=$1
    if [ "${prim}" != "proton" ]; then
        error_exit "primary option is invalid - aborting"
    else
        echo "${prim}"
    fi
}

nsb_list_from_group()
{
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
    local zenith=$1
    local i=$2
    echo "${zenith}$(( i + 5000 ))"
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
}

groptics_log()
{
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
}

gro_pilot_file()
{
    local wobble=$1
    local wd=$2
    local force=$3

    local cfg_dir
    cfg_dir=$(config_dir)

    local file="${cfg_dir}/GrOptics/GrOpticsV6pilot_wob${wobble}_${wd}.txt"

    if [ "${force}" = "true" ] || [ ! -f "${file}" ]; then
        local gen_file="${cfg_dir}/GrOptics/GrOpticsV6pilot_generic.txt"
        cp "${gen_file}" "${file}"
        sed -i -e 's/X'"${wd}"'X/*/g' "${file}"
        W="0$(echo "scale=2; ${wobble}/10" | bc -l)"
        sed -i -e 's/XWX/'"$W"'/g' "${file}"
        echo "${file}"  
    fi
    echo "${file}"
}

config_atm()
{
    local atm=$1
    local cfg_dir
    cfg_dir=$(config_dir)
    if [ "${atm}" = "summer" ]; then
        echo "${cfg_dir}/GrOptics/Ext_results_VSummer_6_1_6.M5.txt"
    elif [ "${atm}" =  "winter" ]; then
        echo "${cfg_dir}/GrOptics/Ext_results_VWinter_3_2_6.M5.txt"
    fi
}


config_ioreader()
{
    local cfg_dir
    cfg_dir=$(config_dir)
    echo "${cfg_dir}/GrOptics/IOReaderDetectorConfigV6.txt"
}

#############
# CORSIKA

corsika_directory_zip()
{
    local zenith=$1
    local atm=$2
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")
    local atm_dir
    atm_dir=$(atm_directory "${atm}")

    echo "/lustre/fs23/group/veritas/simulations/V6_FLWO/OSG_CORSIKA/${atm_dir}/corsika/${zenith_dir}"    
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

    echo "/lustre/fs23/group/veritas/V6_DESY/OSG_CORSIKA/${atm_dir}/corsika/${zenith_dir}"    
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

corsika_out_directory()
{
    local zenith=$1
    local atm=$2
    local zenith_dir
    zenith_dir=$(zenith_directory "${zenith}")
    local atm_dir
    atm_dir=$(atm_directory "${atm}")

    echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/corsika"    
}

corsika_out_file()
{
    local run=$1
    local zenith=$2
    local atm=$3
    local corsika_dir
    corsika_dir=$(corsika_out_directory "${zenith}" "${atm}")

    echo "${corsika_dir}/DAT${run}.telescope"
}

corsika_input()
{
    local run=$1
    local zenith=$2
    local atm=$3
    local corsika_dir
    corsika_dir=$(corsika_out_directory "${zenith}" "${atm}")

    echo "${corsika_dir}/input/DAT${run}.inp"
}

corsika_log()
{
    local run=$1
    local zenith=$2
    local atm=$3
    local corsika_dir
    corsika_dir=$(corsika_out_directory "${zenith}" "${atm}")

    echo "${corsika_dir}/log/DAT${run}.log"
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
    local mode=$1
    cfg_dir=$(config_dir)
    if [ "${mode}" = "std" ]; then
        echo "${cfg_dir}/CARE/CARE_V6_Std.txt"
    else
        echo "${cfg_dir}/CARE/CARE_V6_RHV.txt"
    fi
}

care_high_gain()
{
    cfg_dir=$(config_dir)
    echo "${cfg_dir}/CARE/VERITASHighGainPulseShapeHamamatsuPMT.txt"
}

care_low_gain()
{
    cfg_dir=$(config_dir)
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

    echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/care_${mode}/wobble${wobble}/Data/NSB${nsb}/CARE${run}"
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

    echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/care_${mode}/wobble${wobble}/Log/NSB${nsb}/log_${run}.${label}"
}

merged_care_file()
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

    echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/merged/Data/gamma_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz.vbf"
}

merged_care_log()
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

    echo "/lustre/fs23/group/veritas/V6_DESY/${atm_dir}/${zenith_dir}/merged/Log/log_V6_CARE_${mode}_${atm_dir}_zen${zenith}deg_${wobble}wob_${nsb}MHz.${label}"
}
