# $0 is the entire line                         - Complete line
# $1 is the first field, before "p":"
# $2 is the first field, before "p":"           - Package
# $3 is the second field, before ","d":"        - Description
# $4 is the third field, before ","v":"         - Version
# $5 is the fourth field, before ","i":"        - Installed ( true or false )
# $6 is the sixth field, before ","u":"         - Update version
# $7 is the seventh field, before ","vote":"    - Votes
# $8 is the eighth field, before ","pop":"      - Popularity
# $9 is the ninth field, before ","ood":"       - Out of date in unix timestamp
# $10 is the tenth field, before ","maint":"    - Maintainer
# $11 is the eleventh field, after last "       - End of line

# BEGIN run one time before the first line is read
BEGIN { 

    # Split the terms in array t, with space as separator
    # Any word in search is a term
    split(terms, t, " "); 
}

# Now start the main loop, which is run for each line of the pacman output
{
    # Count is 50, because the max count is 50
    # For each term, if the package name match with term, count -= 1
    # If the package is installed, count -= 10
    # If the package have update, count -= 10
    # This make easy to sort the results
    count = 50;

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
