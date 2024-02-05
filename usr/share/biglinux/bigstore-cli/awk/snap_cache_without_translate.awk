BEGIN {
    FS = "\t"; # Use separator as tab

    # Read installed packages
    while (getline < installedPackages) {
        split($0, a, FS);
        installed[a[1]] = 1; # Use package ID as key
    }
    close(installedPackages);

    # print "["; # Start of JSON array
    first = 1; # To control the comma before JSON objects
}

# Process the complete list of packages
{
    if (FNR > 1 && !first) print ","; # Add comma before each JSON object, except the first
    first = 0; # Reset flag after the first object

    # Escape invalid JSON characters
    gsub(/(["\\])/,"\\\\&", $2);

    # Create the JSON object for the current package
    printf "{\"n\":\"%s\",\"d\":\"%s\",\"p\":\"%s\",\"v\":\"%s\",\"ic\":\"%s\",\"i\":%s,\"u\":\"\",\"t\":\"s\"}",
        $1, $2, $3, $5, $6,
        (installed[$3] ? "\"true\"" : "\"\"");
}

END {
    print ","; # Close the JSON array
}
