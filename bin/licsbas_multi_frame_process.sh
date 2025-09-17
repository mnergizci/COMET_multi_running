#!/bin/bash
## Script to process multiple licsar2licsbas running. 
# 01/04/2024 Muhammet Nergizci, COMET, University of Leeds

# Function to display usage
usage() {
    echo "Usage: $0 <frames_file> [-s start_date] [-e end_date] [--local] [--sbovl] [--eqoff] [--corrections] [--abs]"
    exit 1
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    usage
fi

# Default values
frames_file=""
start_date=""
end_date=""
sboi_flag=""
eqoff_flag=""
local_flag=""
corrections_flag=""
abs_flag=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--start-date)
            start_date="$2"
            shift 2
            ;;
        -e|--end-date)
            end_date="$2"
            shift 2
            ;;
        --local)
            local_flag="yes"
            shift
            ;;
        --sbovl)
            sboi_flag="yes"
            shift
            ;;
        --eqoff)
            eqoff_flag="yes"
            shift
            ;;
        --corrections)
            corrections_flag="yes"
            shift
            ;;
        --abs)
            abs_flag="yes"
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            frames_file="$1"
            shift
            ;;
    esac
done

# Validate mandatory arguments
if [[ -z "$frames_file" || -z "$start_date" || -z "$end_date" ]]; then
    usage
fi

# Create directories
log_dir="LiCSBAS_log"
mkdir -p "$log_dir"
mkdir -p preprocess

# Extract the desired part of the current directory path
current_dir_suffix=$(pwd | awk -F'/' '{print $(NF-1)"/"$NF}')

# Process each frame in the input file
while read -r i; do
    # Validate frame format
    if ! [[ "$i" =~ ^[0-9]{3}[AD]_[0-9]{5}_[0-9]{6}$ ]]; then
        echo "Skipping invalid frame: $i"
        continue
    fi

    session_name="${i}_${current_dir_suffix}"
    echo "Starting session: $session_name"

    if [[ "$corrections_flag" == "yes" ]]; then
        # Submit as SLURM batch job
        if [[ "$sboi_flag" == "yes" && "$eqoff_flag" == "yes" ]]; then
            if [[ "$abs_flag" == "yes" ]]; then
                sbatch --qos=high --output=preprocess/preprocessing_jasmin${i}.out --error=preprocess/preprocessing_jasmin${i}.err \
                --job-name=prepros_LB_${i} -n 8 --time=47:59:00 --mem=65536 -p comet --account=comet_lics --partition=standard \
                --wrap="licsar2licsbas.sh -W -M 10 -b -Q -n 8 -T -i -e -O -E 6 -p -X -x -Z ${i} ${start_date} ${end_date}"
            else
                sbatch --qos=high --output=preprocess/preprocessing_jasmin${i}.out --error=preprocess/preprocessing_jasmin${i}.err \
                --job-name=prepros_LB_${i} -n 8 --time=47:59:00 --mem=65536 -p comet --account=comet_lics --partition=standard \
                --wrap="licsar2licsbas.sh -W -M 10 -b -Q -n 8 -T -i -e -O -E 6 -p -X -Z ${i} ${start_date} ${end_date}"
            fi
        elif [[ "$sboi_flag" == "yes" ]]; then
            if [[ "$abs_flag" == "yes" ]]; then
                sbatch --qos=high --output=preprocess/preprocessing_jasmin${i}.out --error=preprocess/preprocessing_jasmin${i}.err \
                --job-name=prepros_LB_${i} -n 8 --time=47:59:00 --mem=65536 -p comet --account=comet_lics --partition=standard \
                --wrap="licsar2licsbas.sh -W -M 10 -b -Q -n 8 -T -i -e -O -p -X -x -Z ${i} ${start_date} ${end_date}"
            else
                sbatch --qos=high --output=preprocess/preprocessing_jasmin${i}.out --error=preprocess/preprocessing_jasmin${i}.err \
                --job-name=prepros_LB_${i} -n 8 --time=47:59:00 --mem=65536 -p comet --account=comet_lics --partition=standard \
                --wrap="licsar2licsbas.sh -W -M 10 -b -Q -n 8 -T -i -e -O -p -X -Z ${i} ${start_date} ${end_date}"
            fi
        elif [[ "$eqoff_flag" == "yes" ]]; then
            sbatch --qos=high --output=preprocess/preprocessing_jasmin${i}.out --error=preprocess/preprocessing_jasmin${i}.err \
            --job-name=prepros_LB_${i} -n 8 --time=47:59:00 --mem=65536 -p comet --account=comet_lics --partition=standard \
            --wrap="licsar2licsbas.sh -M 10 -g -n 8 -W -N -T -i -e -u -t 0 -C 0.2 -d -E 6 -p -O -Z -X ${i} ${start_date} ${end_date}"
        else
            sbatch --qos=high --output=preprocess/preprocessing_jasmin${i}.out --error=preprocess/preprocessing_jasmin${i}.err \
            --job-name=prepros_LB_${i} -n 8 --time=47:59:00 --mem=65536 -p comet --account=comet_lics --partition=standard \
            --wrap="licsar2licsbas.sh -M 10 -g -n 8 -W -N -T -i -e -u -t 0 -C 0.2 -d -p -O -Z -X ${i} ${start_date} ${end_date}"
        fi
    else
        # Run using tmux
        tmux_command=""
        if [[ "$local_flag" == "yes" ]]; then
            tmux_command="local_mn; "
        fi

        ###here is second step to run the script after iono and set correction is already calculated and saved in epochs
        if [[ "$sboi_flag" == "yes" && "$eqoff_flag" == "yes" ]]; then
            if [[ "$abs_flag" == "yes" ]]; then
                tmux_command+="licsar2licsbas.sh -W -M 10 -b -Q -n 8 -T -i -e -O -E 6 -p -x -Z '$i' '$start_date' '$end_date'"
            else
                tmux_command+="licsar2licsbas.sh -W -M 10 -b -Q -n 8 -T -i -e -O -E 6 -p -Z '$i' '$start_date' '$end_date'"
            fi

        elif [[ "$sboi_flag" == "yes" ]]; then
            if [[ "$abs_flag" == "yes" ]]; then
                tmux_command+="licsar2licsbas.sh -W -M 10 -b -Q -n 8 -T -i -e -O -p -x -Z '$i' '$start_date' '$end_date'"
            else
                tmux_command+="licsar2licsbas.sh -W -M 10 -b -Q -n 8 -T -i -e -O -p -Z '$i' '$start_date' '$end_date'"
            fi
            
        elif [[ "$eqoff_flag" == "yes" ]]; then
            tmux_command+="licsar2licsbas.sh -M 10 -g -n 8 -W -N -T -i -e -u -t 0 -C 0.2 -d -E 6 -p -O -Z '$i' '$start_date' '$end_date'"
        else
            tmux_command+="licsar2licsbas.sh -M 10 -g -n 8 -W -N -T -i -e -u -t 0 -C 0.2 -d -p -O -Z '$i' '$start_date' '$end_date'"
        fi

        tmux_command+=" >> '${log_dir}/${i}_out.log' 2>> '${log_dir}/${i}_err.log' && echo 'Job for $i completed; bash'"
        # echo "Command: $tmux_command"
        tmux new-session -d -s "$session_name" "$tmux_command"
    fi 
done < "$frames_file"
