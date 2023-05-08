#!/bin/bash

export PATH=$PATH:~/.local/bin
cp -r $HOME/$SCRIPTHOME/configs/.config/* $HOME/.config/
pip install konsave
konsave -i $HOME/$SCRIPTHOME/configs/sydyk.knsv
sleep 1
konsave -a sydyk
