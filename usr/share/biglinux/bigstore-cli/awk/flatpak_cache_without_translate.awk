BEGIN {
    FS = "\t"; # Define separator as tab

    # Read installed packages
    while (getline < installedPackages) {
        split($0, a, FS);
        installed[a[3]] = 1; # Usa o ID do pacote como chave
    }
    close(installedPackages);

    # Read packages with updates available
    while (getline < updatePackages) {
        split($0, a, FS);
        updateKey = a[3] FS a[5] FS a[6]; # Create a unique key using id, branch and origin
        updates[updateKey] = 1; # Mark update available for this key
    }
    close(updatePackages);

    # print "["; # Start of JSON array
    first = 1; # To control the comma before the JSON objects
}

# Process the complete list of packages
{
    if (FNR > 1 && !first) print ","; # Add comma before each JSON object, except the first
    first = 0; # Reset flag after the first object

    updateKey = $3 FS $5 FS $6; # Create a unique key for the current package using id, branch and origin

    # Escape invalid JSON characters
    gsub(/(["\\])/,"\\\\&", $2);

    # Create the JSON object for the current package
    printf "{\"p\":\"%s\",\"d\":\"%s\",\"id\":\"%s\",\"v\":\"%s\",\"b\":\"%s\",\"o\":\"%s\",\"i\":%s,\"u\":%s,\"t\":\"f\"}",
        $1, $2, $3, $4, $5, $6,
        (installed[$3] ? "\"true\"" : "\"\""),
        (updates[updateKey] ? "\"true\"" : "\"\"");
}

END {
    # print "]"; # End of JSON array
}
