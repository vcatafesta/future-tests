# BEGIN is run before the first line is read, and just execute one time
BEGIN {

    # Read the installed packages file line by line
    while (getline < installedPackagesFile) {

        # Split each line by space and store the package name and version in an array
        split($0, b, " ");

        # Store the package name and version in an associative array
        installed_packages[b[1]] = b[2];
    }

    # Initialize the output string with an opening bracket, to start the new JSON array
    out = "[\n";
}

# Now start the main loop, which is run for each line of the pacman output
{
    # Store the fields in variables, to make the code more readable
    package = $1;
    description = $2;
    version = $3;
    numvotes = $4;
    popularity = $5;
    outofdate = ($6 == "null") ? "" : $6;
    maintainer = ($7 == "null") ? "" : $7;

    # Escape double quotes and other escape sequences in the descriptions
    gsub(/(["\\])/,"\\\\&", description);

    # Check if the package is installed
    # Use cmd with vercmp binary to compare versions
    # vercmp is binary to verify version of packages from pacman
    if (package in installed_packages) {
        installed_version = installed_packages[package];
        cmd = "vercmp \"" version "\" \"" installed_version "\"";
        cmd | getline result;
        close(cmd);

        # Check if an update is available
        update_available = (result > 0) ? "true" : "false";

        # Append the package info to the output string
        # The separator variable is used to add a comma and newline after each package info
        # out separator have lot of \ because need scape the "
        out = out separator "{\"p\":\""package\
                            "\",\"d\":\""description\
                            "\",\"v\":\""installed_version\
                            "\",\"i\":\"true"\
                            "\",\"u\":\""version\
                            "\",\"vt\":\""numvotes\
                            "\",\"pp\":\""popularity\
                            "\",\"od\":\""outofdate\
                            "\",\"m\":\""maintainer\
                            "\",\"t\":\"a\"}";

    } else {

        # Same as above, but for packages that are not installed
        out = out separator "{\"p\":\""package\
                            "\",\"d\":\""description\
                            "\",\"v\":\""version\
                            "\",\"i\":\""\
                            "\",\"u\":\""\
                            "\",\"vt\":\""numvotes\
                            "\",\"pp\":\""popularity\
                            "\",\"od\":\""outofdate\
                            "\",\"m\":\""maintainer\
                            "\",\"t\":\"a\"}";

    }
    separator = ",\n";
}

# END is run after the last line is read, and just execute one time
END {
    # Add a closing bracket to the output string, to close the JSON array
    # We add an empty object at the end, because is faster than remove the last comma
    out = out ",\n{}]";

    # Finally print the output string
    print out;
}
