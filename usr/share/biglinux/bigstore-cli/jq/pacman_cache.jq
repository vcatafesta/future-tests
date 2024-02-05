# Split the input by newline, filter out empty lines, and then reduce it
reduce (split("\n") | .[] | select(. != "")) as $line ([]; 

# Check if the line starts with spaces (typically descriptions in pacman output)
if ($line | startswith("    "))
then
    # If there are already items in the result array
    if (length > 0)
    then 
    # Add the description to the last package in the result array
    .[-1].description = ($line | ltrimstr("    "))
    else 
    .
    end
else
    # Construct the package info object
    {
    "repo": ($line | split("/")[0]), # Extract the repository name
    "package": ($line | split("/")[1] | split(" ")[0]), # Extract the package name
    "installed": ($line | contains(" [installed") | tostring), # Check if the package is installed
    "version": (if $line | contains(" [installed: ") # Extract the installed version if available
                            then ($line | split(" [installed: ")[1] | split("]")[0])
                            else ($line | split(" ")[1] | split(" ")[0]) end)
    } as $package_info | 

    # Append the package info to the result array
    . + [$package_info]
end
)
