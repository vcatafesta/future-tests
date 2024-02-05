BEGIN {
    FS = "\t"; # Use separator as tab

    # Read installed packages
    while (getline < installedPackages) {
        split($0, a, FS);
        installed[a[1]] = 1; # Use package ID as key
    }
    close(installedPackages);

    # Read the translations file line by line
    while (getline < localeFile) {

        # Split each line by tab and store the package name and translation in an array
        split($0, a, "\t");

        # Store the translation in the translations array, with the package name as the key
        translations[a[1]] = a[2];
    }

    # print "["; # Start of JSON array
    first = 1; # To control the comma before JSON objects
}

# Process the complete list of packages
{
    # name = $1;
    # description = $2;
    # id = $3;
    # pkgid = $4;
    # version = $5;
    # installed = $6;
    if (FNR > 1 && !first) print ","; # Add comma before each JSON object, except the first
    first = 0; # Reset flag after the first object

    # Use translated description if available, otherwise use original description
    description_to_use = (translations[$3] != "") ? translations[$3] : $2;

    # Escape invalid JSON characters
    gsub(/(["\\])/,"\\\\&", description_to_use);

    # Create the JSON object for the current package
    printf "{\"n\":\"%s\",\"d\":\"%s\",\"p\":\"%s\",\"v\":\"%s\",\"ic\":\"%s\",\"i\":%s,\"u\":\"\",\"t\":\"s\"}",
        $1, description_to_use, $3, $5, $6,
        (installed[$3] ? "\"true\"" : "\"\"");
}

END {
    print ","; # Close the JSON array
}
