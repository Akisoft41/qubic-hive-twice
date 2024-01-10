# qubic-hive-twice is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
# qubic-hive-twice is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with qubic-hive-twice. If not, see <https://www.gnu.org/licenses/>


confCPU=`cat /hive/miners/custom/$CUSTOM_NAME/cpu/appsettings_global.json | envsubst`
confGPU=`cat /hive/miners/custom/$CUSTOM_NAME/gpu/appsettings_global.json | envsubst`

SettingsCPU=$(jq -r .Settings <<< "$confCPU")
SettingsGPU=$(jq -r .Settings <<< "$confGPU")


[[ ! -z $CUSTOM_TEMPLATE ]] &&
	SettingsCPU=`jq --null-input --argjson Settings "$SettingsCPU" --arg alias "${CUSTOM_TEMPLATE}-cpu" '$Settings + {$alias}'` &&
	SettingsGPU=`jq --null-input --argjson Settings "$SettingsGPU" --arg alias "$CUSTOM_TEMPLATE" '$Settings + {$alias}'`

[[ ! -z $CUSTOM_URL ]] &&
	SettingsCPU=`jq --null-input --argjson Settings "$SettingsCPU" --arg baseUrl "$CUSTOM_URL" '$Settings + {$baseUrl}'` &&
	SettingsGPU=`jq --null-input --argjson Settings "$SettingsGPU" --arg baseUrl "$CUSTOM_URL" '$Settings + {$baseUrl}'`


#merge user config options into main config
if [[ ! -z $CUSTOM_USER_CONFIG ]]; then
	while read -r line; do
		[[ -z $line ]] && continue
    [[ ${line:0:1} = "#" ]] && continue # comment
    if [[ ${line:0:7} = "nvtool " ]]; then
      eval $line
    elif [[ ${line:1:15} = "amountOfThreads" ]]; then
		  SettingsCPU=$(jq -s '.[0] * .[1]' <<< "$SettingsCPU {$line}")
    elif [[ ${line:0:4} = "cpu:" ]]; then
		  SettingsCPU=$(jq -s '.[0] * .[1]' <<< "$SettingsCPU {${line:4}}")
    elif [[ ${line:0:4} = "gpu:" ]]; then
		  SettingsGPU=$(jq -s '.[0] * .[1]' <<< "$SettingsGPU {${line:4}}")
    else
		  SettingsCPU=$(jq -s '.[0] * .[1]' <<< "$SettingsCPU {$line}")
		  SettingsGPU=$(jq -s '.[0] * .[1]' <<< "$SettingsGPU {$line}")
    fi
	done <<< "$CUSTOM_USER_CONFIG"
fi


confCPU=`jq --null-input --argjson Settings "$SettingsCPU" '{$Settings}'`
confGPU=`jq --null-input --argjson Settings "$SettingsGPU" '{$Settings}'`
echo $confCPU | jq . > /hive/miners/custom/$CUSTOM_NAME/cpu/appsettings.json
echo $confGPU | jq . > /hive/miners/custom/$CUSTOM_NAME/gpu/appsettings.json


# le script h-run.sh a besoin du programme "ts" qui fait partie du package Ubuntu "moreutils"
apt install moreutils -y
