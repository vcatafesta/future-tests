# BEGIN is run before the first line is read, and just execute one time
BEGIN {

    # Read the updates file line by line
    while (getline < updatesFile) {
        split($0, a, " ");
        updates[a[1]] = a[4];
    }

    # Read the translations file line by line
    while (getline < localeFile) {

        # Split each line by tab and store the package name and translation in an array
        split($0, a, "\t");

        # Store the translation in the translations array, with the package name as the key
        translations[a[1]] = a[2];
    }

    # Initialize the output string with an opening bracket, to start the new JSON array
    out = "[\n";
}

# Now start the main loop, which is run for each line of the pacman output
{
    # Store the fields in variables, to make the code more readable
    repo = $2;
    package = $3;
    description = $6;
    version = $5;
    installed = $4;

    # Escape double quotes and other escape sequences in the descriptions
    gsub(/(["\\])/,"\\\\&", description);
    gsub(/(["\\])/,"\\\\&", translations[package]);

    # Use translated description if available, otherwise use original description
    description_to_use = (translations[package] != "") ? translations[package] : description;

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
    # Add a closing bracket to the output string, to close the JSON array
    # We add an empty object at the end, because is faster than remove the last comma
    out = out ",\n{}]";

    # Finally print the output string
    print out;
}
