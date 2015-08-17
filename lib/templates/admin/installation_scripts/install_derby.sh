#!/bin/bash
mkdir /opt/derby && wget -P /tmp http://psg.mtu.edu/pub/apache//db/derby/db-derby-10.10.2.0/db-derby-10.10.2.0-bin.zip && unzip /tmp/db-derby-10.10.2.0-bin.zip -d /opt/derby && rm /tmp/db-derby-10.10.2.0-bin.zip
