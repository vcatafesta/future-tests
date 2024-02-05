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

    package = $2;
    description = $3;
    version = $4;
    installed = $5; # true or false
    up = $6; # update available
    vote = $7; # votes
    pop = $8; # popularity
    ood = $9; # out of date in unix timestamp
    maint = $10; # maintainer

    count = 50;
    for (i in t) {
        if (package ~ t[i]) count -= 1;
    }
    if (installed == "true") {
        count -= 10;
        totalInstalled += 1;
        if (up != "") {
            installed="installed ";
            update=" new version  "gray up " ";
            count -= 10;
        } else {
            update = "";
            installed="installed  ";}
    } else {
        update = "";
        installed="";
        totalNotInstalled += 1;
    }
    if (ood != "") {
        ood = "  Out of date since " strftime("%F",ood);
    } else {
        ood = "";
    }
    if (maint == "") {
        maint = "\x1b[31mOrphan";
    }

    # Removendo a contagem do print final
    print count, blue "AUR" gray "/" yellow package "  " green installed gray version " " yellow update resetColor " (" gray "Votes " resetColor vote gray " Pop " resetColor pop gray " Maintainer " resetColor maint resetColor")" red ood resetColor "\t,,," description "\t,,,";

# END run one time after the last line is read
} END {
        print "\n01   " gray "AUR\t\tinstalled: " resetColor totalInstalled gray "\tNot installed: " resetColor totalNotInstalled gray "\tTotal: " resetColor totalInstalled + totalNotInstalled;
}
