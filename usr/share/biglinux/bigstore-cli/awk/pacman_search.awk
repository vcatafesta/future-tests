# BEGIN run one time before the first line is read
BEGIN {
    # Use strange characters as separator, to avoid problems
    OFS=" "

    # Split the terms in array t, with space as separator
    # Any word in search is a term
    split(terms, t, " ");

    # Define colors, for text output more beautiful
    blue="\x1b[34m"
    yellow="\x1b[33m"
    gray="\x1b[36m"
    green="\x1b[32m"
    red="\x1b[31m"
    resetColor="\x1b[0m"

    # Count number of results
    totalInstalled = 0;
    totalNotInstalled = 0;
}

# Now start the main loop, which is run for each line of the pacman output
{
    # Store the fields in variables, to make the code more readable
    package = $2;
    description = $3;
    version = $4;
    installed = $5;
    updateVersion = $6;
    repo = $7;

    # Count is 49 for pacman, 50 is AUR, less number have more priority
    # For each term, if the package name match with term, count -= 1
    # If the package is installed, count -= 10
    # If the package have update, count -= 10
    # This make easy to sort the results
    count = 49;

    # For each term, if the package name match with term, count -= 1
    for (i in t) {
        if (package ~ t[i]) count -= 1;
    }

    # If the package is installed, count -= 10
    if (installed == "true") {
        count -= 10;
        installed = "installed ";
        totalInstalled += 1;

        # If the package have update, count -= 10
        if (updateVersion != "") {
            update = "new version  " gray updateVersion;
            count -= 10;
        } else {
            update = "";
        }
    } else {
        totalNotInstalled += 1;
        installed = "";
        update = "";
    }

    # Add "\t,,," to use sed after sort and change for break line
    print count, gray repo "/" yellow package "  " green installed " " gray version "  " yellow update "  " resetColor "\t,,," description "\t,,,";

# END run one time after the last line is read
} END {
        print "\n01   " gray "Pacman\tinstalled: " resetColor totalInstalled gray "\tNot installed: " resetColor totalNotInstalled gray "\tTotal: " resetColor totalInstalled + totalNotInstalled;
}
