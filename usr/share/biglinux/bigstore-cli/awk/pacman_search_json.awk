# package = $2;
# description = $3;
# version = $4;
# installed = $5;
# updateVersion = $6;
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
        if ($2 ~ t[i]) count -= 1;
    }

    # If the package is installed, count -= 10
    if ($5 == "true") {
        count -= 10;
    }

    # If the package have update, count -= 10
    if ($6 != "") {
        count -= 10;
    }

    # Print the count and all information from json line
    print count, $0;
}
