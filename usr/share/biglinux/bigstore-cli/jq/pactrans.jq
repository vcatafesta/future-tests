# Convert pactrans output in json
# Example of use:

# upgrade
# pactrans --sysupgrade --yolo --print-only | jq -Rn -f pactrans.jq

# install
# pactrans --install --yolo --print-only gimp | jq -Rn -f pactrans.jq

# remove
# pactrans --remove --yolo --print-only --cascade --recursive --unneeded gimp | jq -Rn -f pactrans.jq

# Tips for regex used in def:
#
# ^ and $ are anchors that match the start and end of a line, respectively, ensuring the whole line fits the pattern.
# (.*): captures any character sequence before a colon :, typically representing the package name.
# local \\((.*)\\) captures the version of the package installed locally.
#  The double backslashes \\ are used to escape the parentheses in the jq string, which means single
# backslashes are used in the actual regex to match literal parentheses.
# is newer than is a literal string that separates the local version from the repository version information.
# ([^ ]*) captures the repository's name, using [^ ]* to match any character except a space,
# ensuring it only captures the word immediately after "is newer than".
# \\((.*)\\) captures the repository version, similarly enclosed in escaped parentheses.

# def in this case is used to define value like a variable
def regex_newer_than: "^(.*): local \\((.*)\\) is newer than ([^ ]*) \\(([^)]*)\\)$";
def regex_replaced_packages: "^:: replacing package '([^']*)' with '([^']*)'";
def regex_provides_dependency: "^:: selecting package '([^']*)' as provider for dependency '([^']*)'";
def regex_conflict_remove: "^:: uninstalling package '([^']*)' due to conflict with '([^']*)'";
def regex_remove: "^removing local/([^ ]*) \\(([^ )]*)";
def regex_install: "^installing ([^/]*)/([^ ]*) \\(([^) ]*)\\)";
def regex_update: "^installing ([^/]*)/([^ ]*) \\(([^ ]*) -> ([^)]*)\\)";
def regex_download_size: "^Download Size: +(.[0-9.]+) ([A-Z])";
def regex_installed_size: "^Installed Size: +(.[0-9.]+) ([A-Z])";
def regex_size_delta: "^Size Delta: +(.[0-9.]+) ([A-Z])$";

# Process each input line, excluding empty ones.
[inputs
| select(. != "")
| . as $line  # Bind the current line to a variable for processing.
| if test(regex_newer_than) then  # If the line matches the regex for a newer local version...
    ($line | match(regex_newer_than)) | {  # Extract captured groups with the match function.
      "type": "newer_local_version",  # Classify the line for easy identification.
      "package": .captures[0].string,  # Capture the package name.
      "local_version": .captures[1].string,  # Capture the local version of the package.
      "repository": .captures[2].string,  # Capture the repository name.
      "repository_version": .captures[3].string  # Capture the repository version.
    }
  elif test(regex_replaced_packages) then
    ($line | match(regex_replaced_packages)) | {
      "type": "package_replacement",
      "old_package": .captures[0].string,
      "new_package": .captures[1].string
    }
  elif test(regex_provides_dependency) then
    ($line | match(regex_provides_dependency)) | {
      "type": "provides_dependency",
      "install": .captures[0].string,
      "need_dependency": .captures[1].string
    }
  elif test(regex_conflict_remove) then
    ($line | match(regex_conflict_remove)) | {
      "type": "conflict_remove",
      "remove": .captures[0].string,
      "conflict": .captures[1].string
    }
  elif test(regex_install) then
    ($line | match(regex_install)) | {
      "type": "install",
      "repo": .captures[0].string,
      "package": .captures[1].string,
      "version": .captures[2].string
    }
  elif test(regex_update) then
    ($line | match(regex_update)) |
    {
      "repo": .captures[0].string,
      "package": .captures[1].string,
      "version": .captures[2].string,
      "new_version": .captures[3].string
    } | . + {
      "type": (if .version == .new_version then "reinstall"  # Determine if it's a reinstall or an update based on version comparison.
               else "update" end)
    }
  elif test(regex_remove) then
    ($line | match(regex_remove)) | {
      "type": "remove",
      "package": .captures[0].string,
      "version": .captures[1].string
    }
  elif test(regex_download_size) then
    ($line | match(regex_download_size)) | {
      "type": "download_size",
      "size": .captures[0].string,
      "unit": .captures[1].string
    }
  elif test(regex_installed_size) then
    ($line | match(regex_installed_size)) | {
      "type": "installed_size",
      "size": .captures[0].string,
      "unit": .captures[1].string
    }
  elif test(regex_size_delta) then
    ($line | match(regex_size_delta)) | {
      "type": "size_delta",
      "size": .captures[0].string,
      "unit": .captures[1].string
    }
  else
    null  # If no regex matches, return null.
  end
| select(. != null)  # Filter out null results, keeping only matched and processed lines.
]