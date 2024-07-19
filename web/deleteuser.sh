#!/bin/bash

USER_NAME=$1

if [ -z "$USER_NAME" ]; then
    echo "No user specified"
    exit 1
fi

sudo userdel "$USER_NAME"
sudo rm -rf "/home/$USER_NAME"
