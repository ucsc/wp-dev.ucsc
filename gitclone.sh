#!/bin/bash

mkdir -p public/wp-content/themes/ucsc-2022

cd public/wp-content/themes/ucsc-2022
if [[ ! -d .git ]];then
  git clone https://github.com/ucsc/ucsc-2022.git .
  if [ $? -gt 0 ];then
    echo "Cloning theme failed."
    exit
  else
    echo "Cloning theme successful."
  fi
else
  echo "Theme already installed"
fi

cd ../../../..

mkdir -p public/wp-content/plugins/ucsc-gutenberg-blocks

cd public/wp-content/plugins/ucsc-gutenberg-blocks

if [[ ! -d .git ]];then
  git clone https://github.com/ucsc/ucsc-gutenberg-blocks.git .
  if [ $? -gt 0 ];then
    echo "Cloning plugin failed."
    exit
  else
    echo "Cloning plugin successful."
  fi
else
  echo "Plugin already installed"
fi


