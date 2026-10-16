#!/bin/sh
#
# Copyright 2026 Rafał Wabik (IceG) - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.
#

get_device_info() {
    device_name="$1"
    device_path="$2"
    
    case "$device_name" in
        *ath11k*isa*|*ath11k*c000000*)
            echo "Wi-Fi 2.4GHz"
            ;;
        *ath11k*pci*)
            echo "Wi-Fi 5GHz"
            ;;
        cpu_thermal|cpu-thermal)
            echo "CPU"
            ;;
        ubi32_thermal|ubi32-thermal)
            echo "Network Coprocessor"
            ;;
        top_glue_thermal|top-glue-thermal)
            echo "Mainboard"
            ;;
        gephy_thermal|gephy-thermal)
            echo "Ethernet"
            ;;
        *)
            # NN sensors
            echo ""
            ;;
    esac
}

echo "{"
echo "  \"temperatures\": ["

first=1

# ath11k
for hwmon_dir in /sys/class/hwmon/hwmon*; do
    if [ -d "$hwmon_dir" ]; then
        name=""
        if [ -f "$hwmon_dir/name" ]; then
            name=$(cat "$hwmon_dir/name" 2>/dev/null)
        fi
        
        if [ "$name" = "ath11k_hwmon" ]; then
            real_path=$(readlink -f "$hwmon_dir")
            
            for temp_file in "$hwmon_dir"/temp*_input; do
                if [ -f "$temp_file" ]; then
                    temp_raw=$(cat "$temp_file" 2>/dev/null)
                    
                    if [ -z "$temp_raw" ] || [ "$temp_raw" = "" ]; then
                        continue
                    fi
                    
                    case "$temp_raw" in
                        ''|*[!0-9-]*) continue ;;
                    esac
                    
                    temp_c=$(awk "BEGIN {printf \"%.1f\", $temp_raw/1000}" 2>/dev/null)
                    
                    if [ -z "$temp_c" ]; then
                        continue
                    fi
                    
                    description=""
                    if echo "$real_path" | grep -q "pci"; then
                        description="Wi-Fi 5GHz"
                    elif echo "$real_path" | grep -q "c000000\|platform"; then
                        description="Wi-Fi 2.4GHz"
                    else
                        description="Wi-Fi"
                    fi
                    
                    if [ $first -eq 0 ]; then
                        echo ","
                    fi
                    first=0
                    
                    echo "    {"
                    echo "      \"name\": \"ath11k_$(basename $hwmon_dir)\","
                    echo "      \"description\": \"$description\","
                    echo "      \"temperature_c\": $temp_c,"
                    echo "      \"path\": \"$temp_file\""
                    printf "    }"
                fi
            done
        fi
    fi
done

# thermal_zone (CPU, Mainboard, Network Coprocessor, Ethernet)
for zone_dir in /sys/class/thermal/thermal_zone*; do
    if [ -d "$zone_dir" ]; then
        zone_type=""
        if [ -f "$zone_dir/type" ]; then
            zone_type=$(cat "$zone_dir/type" 2>/dev/null)
        fi
        
        if [ -f "$zone_dir/temp" ]; then
            temp_raw=$(cat "$zone_dir/temp" 2>/dev/null)
            
            if [ -z "$temp_raw" ] || [ "$temp_raw" = "" ]; then
                continue
            fi
            
            case "$temp_raw" in
                ''|*[!0-9-]*) continue ;;
            esac
            
            temp_c=$(awk "BEGIN {printf \"%.1f\", $temp_raw/1000}" 2>/dev/null)
            
            if [ -z "$temp_c" ]; then
                continue
            fi
            
            description=$(get_device_info "$zone_type" "$zone_dir")
            
            # NN sensors
            if [ -z "$description" ]; then
                continue
            fi
            
            if [ $first -eq 0 ]; then
                echo ","
            fi
            first=0
            
            echo "    {"
            echo "      \"name\": \"$zone_type\","
            echo "      \"description\": \"$description\","
            echo "      \"temperature_c\": $temp_c,"
            echo "      \"path\": \"$zone_dir/temp\""
            printf "    }"
        fi
    fi
done

echo ""
echo "  ],"

# CPU (list of cores + frequency from mhz)
cores_json=""
for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*; do
    [ -d "$cpu_dir" ] || continue
    cpu_num="${cpu_dir##*cpu}"
    if [ -z "$cores_json" ]; then
        cores_json="$cpu_num"
    else
        cores_json="$cores_json, $cpu_num"
    fi
done

mhz_bin=$(command -v mhz 2>/dev/null)
if [ -z "$mhz_bin" ] && [ -x /usr/bin/mhz ]; then
    mhz_bin="/usr/bin/mhz"
fi

cpu_mhz=""
if [ -n "$mhz_bin" ]; then
    cpu_mhz=$("$mhz_bin" 2>&1 | sed -n 's/.*cpu_MHz=\([0-9.]*\).*/\1/p' | head -n 1)
fi

if [ -z "$cpu_mhz" ]; then
    cpu_mhz="null"
fi

echo "  \"cpu\": {"
echo "    \"cores\": [$cores_json],"
echo "    \"mhz\": $cpu_mhz"
echo "  }"
echo "}"
