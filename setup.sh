#!/bin/bash

themes=("ucsc-2022")
plugins=("ucsc-gutenberg-blocks" "ucsc-custom-functionality")

setup () {
  if [ ! -d "$i" ]; then
	  git clone https://github.com/ucsc/${i}.git
    if [ $? -gt 0 ];then
      echo "Cloning '$i' failed."
    exit
    else
      echo "Cloned '$i' successfully."
    fi    
  else
    echo "'$i' already exists."
  fi
}

cd public/wp-content/themes

for i in "${themes[@]}"
do
  setup $i
done

cd ../plugins

for i in "${plugins[@]}"
do
  setup $i
done