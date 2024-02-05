# BEGIN is run before the first line is read, and just execute one time
BEGIN {

    # Read the updates file line by line
    while (getline < updatesFile) {
        split($0, a, " ");
        updates[a[1]] = a[4];
    }

    # Initialize the output string with an opening bracket
    out = "[\n";
}

# Now start the main loop, which is run for each line of the pacman output
{
    repo = $2;
    package = $3;
    description_to_use = $6;
    version = $5;
    installed = $4;

    # Escape double quotes and other escape sequences in the descriptions
    gsub(/(["\\])/,"\\\\&", description_to_use);

    # Verfify to not add duplicated packages and print json line
    update_info = (package in updates) ? updates[package] : "";

    # Verfify to not add duplicated packages and print json line
    if (!(package in processed_packages)) {
        processed_packages[package] = 1;
        out = out separator "{\"p\":\""package\
                            "\",\"d\":\""description_to_use\
                            "\",\"v\":\""version\
                            "\",\"i\":\""installed\
                            "\",\"u\":\""update_info\
                            "\",\"r\":\""repo\
                            "\",\"t\":\"p\"}";
        separator = ",\n";
    }
}

# END is run after the last line is read, and just execute one time
END {
    out = out ",\n{}]";
    # Add a closing bracket to the output string, to close the JSON array
    # We add an empty object at the end, because is faster than remove the last comma

    # Finally print the output string
    print out;
}
