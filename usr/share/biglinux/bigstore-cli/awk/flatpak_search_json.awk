# package = $2;
# description = $3;
# version = $5;
# id = $4;
# installed = $8;
# update = $9;
# branch = $6;
# repo = $7;

# BEGIN run one time before the first line is read
BEGIN { 

    # Split the terms in array t, with space as separator
    # Any word in search is a term
    split(terms, t, " "); 
}

# Now start the main loop, which is run for each line of the pacman output
{
    # Count is 49 for pacman, 50 is AUR, less number have more priority
    # For each term, if the package name match with term, count -= 1
    # If the package is installed, count -= 10
    # If the package have update, count -= 10
    # This make easy to sort the results
    count = 49;

    # For each term, if the package name match with term, count -= 1
    for (i in t) {
        if (tolower($2) ~ t[i]) count -= 1;
        if (tolower($4) ~ t[i]) count -= 1;
    }

    # If the package is installed, count -= 10
    if ($8 == "true") {
        count -= 10;
    }

    # If the package have update, count -= 10
    if ($9 != "") {
        count -= 10;
    }

    # Print the count and all information from json line
    print count, $0;
}
