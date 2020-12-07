#!/bin/bash
cp -pr /etc/ssh/sshd_config /etc/ssh/sshd_config.bk
echo "Port 7096" >> /etc/ssh/sshd_config
service sshd restart
