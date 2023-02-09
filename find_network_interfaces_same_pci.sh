#!/bin/bash

names=$(ip a | grep BROADCAST | awk '{print $2}' | sed 's/://')

declare -A processed_pairs

IFS=$'\n' read -rd '' -a names_array <<< "$names"

for i in "${names_array[@]}"; do
  for j in "${names_array[@]}"; do
    if [[ $i == $j ]]; then
      continue
    fi

    if [[ ${processed_pairs["$i-$j"]} == 1 ]]; then
      continue
    fi

    if [[ ${#i} != ${#j} ]]; then
      continue
    fi

    diff_count=0
    for ((k=0; k<${#i}; k++)); do
      if [[ "${i:$k:1}" != "${j:$k:1}" ]]; then
        ((diff_count++))
      fi
    done

    if [[ $diff_count == 1 ]]; then
      echo "$i"
      echo "$j"
      processed_pairs["$i-$j"]=1
      processed_pairs["$j-$i"]=1
    fi
  done
done

