BEGIN {
    FS = "\t"; # Define separator as tab

    # Read installed packages
    while (getline < installedPackages) {
        split($0, a, FS);
        installed[a[3]] = 1; # Use package ID as key
    }
    close(installedPackages);

    # Read packages with updates available
    while (getline < updatePackages) {
        split($0, a, FS);
        updateKey = a[3] FS a[5] FS a[6]; # Create a unique key using id, branch and origin
        updates[updateKey] = 1; # Mark update available for this key
    }
    close(updatePackages);

    # Read the translations file line by line
    while (getline < localeFile) {

        # Split each line by tab and store the package name and translation in an array
        split($0, a, "\t");

        # Store the translation in the translations array, with the package name as the key
        translations[a[1]] = a[2];
    }

    # print "["; # Start of JSON array
    first = 1; # To control the comma before the JSON objects
}

# Process the complete list of packages
{
    # name = $1;
    # description = $2;
    # id = $3;
    # version = $4;
    # branch = $5;
    # origin = $6;
    if (FNR > 1 && !first) print ","; # Add comma before each JSON object, except the first
    first = 0; # Reset flag after the first object

    # Use translated description if available, otherwise use original description
    description_to_use = (translations[$3] != "") ? translations[$3] : $2;

    # Escape invalid JSON characters
    gsub(/(["\\])/,"\\\\&", description_to_use);

    updateKey = $3 FS $5 FS $6; # Create a unique key for the current package using id, branch and origin

    # Create the JSON object for the current package
    printf "{\"p\":\"%s\",\"d\":\"%s\",\"id\":\"%s\",\"v\":\"%s\",\"b\":\"%s\",\"o\":\"%s\",\"i\":%s,\"u\":%s,\"t\":\"f\"}",
        $1, description_to_use, $3, $4, $5, $6,
        (installed[$3] ? "\"true\"" : "\"\""),
        (updates[updateKey] ? "\"true\"" : "\"\"");
}

END {
    print ","; # Add comma before the next JSON array
}
