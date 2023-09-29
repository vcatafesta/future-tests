#!/usr/bin/env bash

#  2023-2023, Bruno Gonçalves <www.biglinux.com.br>
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

LANG=C pacman -Ss $* | 

# Use jq to parse and structure the output
jq -Rn '
  # Initialize state variables
  reduce inputs as $line ({output: {}, current_package: null};

    # Check if the line starts with spaces (typically descriptions in pacman output)
    if ($line | startswith("    "))
    then
      # If there is a current package
      if (.current_package)
      then 
        # Add the description to the current package
        .output[.current_package].description = ($line | ltrimstr("    "))
      else 
        .
      end
    else
      # Construct the package info
      {
        repository: ($line | split("/")[0]),          
        package: ($line | split("/")[1] | split(" ")[0]),        
        version: ($line | split(" ")[1] | split("-")[0]),          
        group: (if $line | contains("(") and contains(")")  
               then ($line | split(" ")[2] | split("(")[1] | split(")")[0]) 
               else null end),
        installed: ($line | contains("[installed") | tostring),             
        installed_version: (if $line | contains("[installed: ")               
                           then ($line | split("[installed: ")[1] | split("]")[0])
                           else null end)
      } as $package_info |

      # Set the current package name
      .current_package = $package_info.package |
      
      # Add the package info to the output
      .output[$package_info.package] = $package_info
    end
  ) | .output
'