# qubic-hive-twice is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
# qubic-hive-twice is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with qubic-hive-twice. If not, see <https://www.gnu.org/licenses/>


get_miner_uptime(){
  local a=0
  let a=`stat --format='%Y' $log_name`-`stat --format='%Y' $cpu_conf_name`
  echo $a
}

get_log_time_diff(){
  local a=0
  let a=`date +%s`-`stat --format='%Y' $log_name`
  echo $a
}




#######################
# MAIN script body
#######################


log_basename="/var/log/miner/custom/custom"
log_name="$log_basename.log"
log_head_name="${log_basename}_head.log"
cpu_conf_name="/hive/miners/custom/qubic-hive-twice/cpu/appsettings.json"
custom_version=1.8.9


diffTime=$(get_log_time_diff)
maxDelay=250


# If log is fresh the calc miner stats or set to null if not
if [ "$diffTime" -lt "$maxDelay" ]; then

  ver="$custom_version"
  hs_units="hs"
  algo="qubic"
  
  uptime=$(get_miner_uptime)
  [[ $uptime -lt 60 ]] && head -n 100 $log_name > $log_head_name
  
  cpu_count=`cat $log_head_name | grep "threads are used" | tail -n 1 | cut -d " " -f4`
  [[ $cpu_count = "" ]] && cpu_count=0
  gpu_count=`cat $log_head_name | grep "CUDA devices are used" | tail -n 1 | cut -d " " -f4`
  [[ $gpu_count = "" ]] && gpu_count=0
  
  if [ $cpu_count -eq 0 ] || [ $gpu_count -eq 0 ]; then
    echo ...
    cat $log_name | grep -E "threads are used|CUDA devices are used" | tail -n 20 > $log_head_name
    cpu_count=`cat $log_head_name | grep "threads are used" | tail -n 1 | cut -d " " -f4`
    [[ $cpu_count = "" ]] && cpu_count=0
    gpu_count=`cat $log_head_name | grep "CUDA devices are used" | tail -n 1 | cut -d " " -f4`
    [[ $gpu_count = "" ]] && gpu_count=0
  fi
  
  cpu_temp=`cpu-temp`
  [[ $cpu_temp = "" ]] && cpu_temp=null
  
  
  echo ----------
  echo cpu_count: $cpu_count
  echo gpu_count: $gpu_count
  echo gpu_stats: $gpu_stats
  echo cpu_indexes_array: $cpu_indexes_array
  #echo gpu_detect_json: $gpu_detect_json
  echo ----------
  
  
  if [[ $gpu_count -ge 0 ]]; then
    # GPUs
    gpu_hs=`cat $log_name | tail -n 50 | grep "^GPU" | grep "Try " | tail -n 1 | cut -d " " -f15`
    gpu_found=`cat $log_name | tail -n 50 | grep "^GPU" | grep "Try " | tail -n 1 | cut -d " " -f6 | cut -d "/" -f1`
    gpu_submit=`cat $log_name | tail -n 50 | grep "^GPU" | grep "Try " | tail -n 1 | cut -d " " -f6 | cut -d "/" -f2`
    gpu_temp=$(jq '.temp' <<< $gpu_stats)
    gpu_fan=$(jq '.fan' <<< $gpu_stats)
    gpu_bus=$(jq '.busids' <<< $gpu_stats)
  	if [[ $cpu_indexes_array != '[]' ]]; then
      #remove Internal Gpus
  		gpu_temp=$(jq -c "del(.$cpu_indexes_array)" <<< $gpu_temp) &&
  		gpu_fan=$(jq -c "del(.$cpu_indexes_array)" <<< $gpu_fan) &&
  		gpu_bus=$(jq -c "del(.$cpu_indexes_array)" <<< $gpu_bus)
    fi
    let gpu_hs_tot=0
    
    # <= 1.8.2
    for (( i=0; i < ${gpu_count}; i++ )); do
      hs[$i]=`cat $log_name | tail -n 100 | grep "^GPU" | grep "GPU#$i" | grep "iters/sec" | tail -n 1 | cut -d ":" -f6 | cut -d " " -f2`
      [[ -z ${hs[$i]} ]] && hs[$i]=0
      let gpu_hs_tot=$gpu_hs_tot+${hs[$i]}
      temp[$i]=$(jq .[$i] <<< $gpu_temp)
      fan[$i]=$(jq .[$i] <<< $gpu_fan)
      busid=$(jq .[$i] <<< $gpu_bus)
      bus_numbers[$i]=`echo $busid | cut -d ":" -f1 | cut -c2- | awk -F: '{ printf "%d\n",("0x"$1) }'`
    done
    if [[ $gpu_hs_tot -eq 0 ]]; then
      # 1.8.4
      for (( i=0; i < ${gpu_count}; i++ )); do
        hs[$i]=$(grep -oP "GPU #$i: \K\d+(?= it/s)" "$log_name" | tail -n 1)
        [[ -z ${hs[$i]} ]] && hs[$i]=0
        let gpu_hs_tot=$gpu_hs_tot+${hs[$i]}
      done
    fi
    if [[ $gpu_hs_tot -eq 0 ]]; then
      # si on a pas le hs par gpu, prend la moyenne
      for (( i=0; i < ${gpu_count}; i++ )); do
        hs[$i]=`printf "%.1f\n" $((10 * $gpu_hs / $gpu_count))e-1`
      done
    fi
  fi
  if [[ $cpu_count -ge 0 ]]; then
    # CPU
    cpu_hs=`cat $log_name | tail -n 50 | grep "^CPU" | grep "Try " | tail -n 1 | cut -d " " -f15`
    cpu_found=`cat $log_name | tail -n 50 | grep "^CPU" | grep "Try " | tail -n 1 | cut -d " " -f6 | cut -d "/" -f1`
    cpu_submit=`cat $log_name | tail -n 50 | grep "^CPU" | grep "Try " | tail -n 1 | cut -d " " -f6 | cut -d "/" -f2`
    hs[$gpu_count]=`cat $log_name | tail -n 50 | grep "^CPU" | grep "Try " | tail -n 1 | cut -d " " -f15`
    temp[$gpu_count]=$cpu_temp
    fan[$gpu_count]=""
    bus_numbers[$gpu_count]="null"
  fi
  
  [[ $gpu_hs = "" ]] && gpu_hs=0
  [[ $gpu_found = "" ]] && gpu_found=0
  [[ $gpu_submit = "" ]] && gpu_submit=0
  [[ $cpu_hs = "" ]] && cpu_hs=0
  [[ $cpu_found = "" ]] && cpu_found=0
  [[ $cpu_submit = "" ]] && cpu_submit=0
  
  let khs=$gpu_hs+$cpu_hs
  let ac=$gpu_found+$cpu_found
  let rj=($gpu_submit+$cpu_submit)-$ac

  khs=`echo $khs | awk '{print $1/1000}'`


  stats=$(jq -nc \
            --arg khs "$khs" \
            --arg hs_units "$hs_units" \
            --argjson hs "`echo ${hs[@]} | tr " " "\n" | jq -cs '.'`" \
            --argjson temp "`echo ${temp[@]} | tr " " "\n" | jq -cs '.'`" \
            --argjson fan "`echo ${fan[@]} | tr " " "\n" | jq -cs '.'`" \
            --arg uptime "$uptime" \
            --arg ver "$ver" \
            --arg ac "$ac" --arg rj "$rj" \
            --arg algo "$algo" \
            --argjson bus_numbers "`echo ${bus_numbers[@]} | tr " " "\n" | jq -cs '.'`" \
            '{$hs, $hs_units, $temp, $fan, $uptime, $ver, ar: [$ac, $rj], $algo, $bus_numbers}')

else
  stats=""
  khs=0
fi

# debug output

 echo khs:   $khs
 echo stats: $stats
 echo ----------
