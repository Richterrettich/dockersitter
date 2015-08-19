#!/bin/bash

cert="$(dirname $0)/rootCA.crt"

function mac {
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $cert
}

function linux {
  distribution=$(find /etc/*-release -type f | xargs cat | grep  'ID' | head -n1 | awk -F'=' '{gsub(/"/,"",$2); print tolower($2)}')
  echo $distribution
  case $distribution in 
    debian|ubuntu|linuxmint*|elementary*) 
      echo "hier"
      sudo cp $cert /usr/local/share/ca-certificates/richterrettich.crt
      sudo update-ca-certificates;;
    fedora|centos) 
      sudo cp $cert /etc/pki/ca-trust/source/anchors
      sudo update-ca-trust;;
  esac
}


case $OSTYPE in 
  darwin*) mac
    ;; 
  linux-gnu*) linux
    ;;
esac


