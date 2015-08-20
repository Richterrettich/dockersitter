#!/bin/bash

distribution=$(find /etc/*-release -type f | xargs cat | grep  'ID' | head -n1 | awk -F'=' '{gsub(/"/,"",$2); print tolower($2)}')
case $distribution in 
	debian|ubuntu|linuxmint*|elementary*) 
		sudo mkdir -p /usr/local/share/ca-certificates
		sudo cp $1/* /usr/local/share/ca-certificates/
		sudo update-ca-certificates;;
	fedora|centos) 
		sudo cp $1 /etc/pki/ca-trust/source/anchors/*
		sudo update-ca-trust;;
esac
