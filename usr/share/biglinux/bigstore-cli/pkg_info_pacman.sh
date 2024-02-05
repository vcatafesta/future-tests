#!/usr/bin/env bash

#  Created: 2024/01/17
#
#  Copyright (c) 2023-2024, Bruno Gonçalves <www.biglinux.com.br>
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# If $1 is empty, exit
if [ -z "$1" ]; then
  exit 1
fi

# Search info in pacman database
pacmanInfo="$(LANG=C pacman -Sii $1)"
if [[ $? != 0 ]]; then

  # If not found, search info in pacman installed packages
  pacmanInfo="$(LANG=C pacman -Qi $1)"
    if [[ $? != 0 ]]; then

      # If not found in database or installed packages, exit with error
      exit 1
    fi
fi

# Convert pacman info to JSON
# Yes need breakline in the end of echo
echo "$pacmanInfo
" | grep -E -B 999  -m1 '^$' | \
awk -v RS="" -f awk/pkg_info_pacman.awk | \
jq -f jq/pkg_info_pacman.jq

