#!/bin/bash

rg "\"Name\":\"$1\"" "/var/tmp/pamac/packages-meta-ext-v1.json" | sed 's|,$||g'
