function getItems() {
  let autoCompleteMenuEnabled = true;
  let isThrottled = false;

  window.items = {
    search: "",
    showPkgInfoModal: false,
    showPkgInfoModalPart2: false,
    bigstoreData: [],
    markedForInstall: [],
    markedForRemoval: [],
    markedForUpdate: [],
    filteredItemsCount: 0,
    maxItems: 30,
    open: false,
    pkgInfo: {},
    item: {},
    searchPacman: true,
    searchAUR: true,
    searchFlatpak: true,
    searchSnap: false,
    pacmanCount: 0,
    aurCount: 0,
    flatpakCount: 0,
    snapCount: 0,
    additionalInfo: null,

    // Function to save the current configuration
    async saveConfig() {
      try {
        const config = {
          searchPacman: this.searchPacman,
          searchAUR: this.searchAUR,
          searchFlatpak: this.searchFlatpak,
          searchSnap: this.searchSnap,
        };
        await fetch("/api/file?filename=$HOME/.config/bigstore/config.json", {
          method: "POST",
          body: JSON.stringify(config),
        });
      } catch (error) {
        console.error("Fail to save os load config:", error);
      }
    },

    // Function to load the saved configuration
    async loadConfig() {
      try {
        const response = await fetch(
          "/api/file?filename=$HOME/.config/bigstore/config.json"
        );
        if (response.ok) {
          const config = await response.json();
          if (config) {
            this.searchPacman = config.searchPacman;
            this.searchAUR = config.searchAUR;
            this.searchFlatpak = config.searchFlatpak;
            this.searchSnap = config.searchSnap;
          }
        } else {
          console.error(
            "Failed to load config:",
            response.status,
            response.statusText
          );
        }
      } catch (error) {
        console.error("Error during config load:", error);
      }
    },

    // Updated to work as a toggle
    toggleMarkForInstall(item) {
      let isMarked = this.markedForInstall.some(
        (pkg) => pkg.p === item.p && pkg.type === item.t
      );
      if (isMarked) {
        // If it's already marked for installation, remove it from the list
        this.markedForInstall = this.markedForInstall.filter(
          (pkg) => pkg.p !== item.p || pkg.type !== item.t
        );
      } else {
        // Otherwise, add it to the list and remove from other states if necessary
        this.markedForInstall.push({ p: item.p, type: item.t });
      }
    },
    toggleMarkForRemoval(item) {
      let isMarked = this.markedForRemoval.some(
        (pkg) => pkg.p === item.p && pkg.type === item.t
      );
      if (isMarked) {
        // If it's already marked for removal, remove it from the list
        this.markedForRemoval = this.markedForRemoval.filter(
          (pkg) => pkg.p !== item.p || pkg.type !== item.t
        );
      } else {
        // Otherwise, add it to the list and remove from other states if necessary
        this.markedForRemoval.push({ p: item.p, type: item.t });
      }
    },
    // Updated to work as a toggle
    toggleMarkForUpdate(item) {
      let isMarked = this.markedForUpdate.some(
        (pkg) => pkg.p === item.p && pkg.type === item.t
      );
      if (isMarked) {
        // If it's already marked for update, remove it from the list
        this.markedForUpdate = this.markedForUpdate.filter(
          (pkg) => pkg.p !== item.p || pkg.type !== item.t
        );
      } else {
        // Otherwise, add it to the list and remove from other states if necessary
        this.markedForUpdate.push({ p: item.p, type: item.t });
      }
    },

    isMarkedForAction(item, actionType) {
      let actionList = this[`markedFor${actionType}`];
      return actionList.some(
        (pkg) => pkg.id === item.id && pkg.type === item.t
      );
    },

    // Function to show modal and load the additional info for the selected item
    showModal(item) {
      console.log(item);
      // this.pkgInfo = {};
      // this.pacmanInfo = {};
      this.showPkgInfoModal = true;
      this.showPkgInfoModalPart2 = false;
      this.pkgInfo = item;
      if (item.t === "p") {
        this.getPacmanInfo();
        this.getPacmanInfoAppstream();
      } else if (item.t === "a") {
        if (item.i === "true") {
          this.getPacmanInfo();
          this.getPacmanInfoAppstream();
        } else {
          this.getAurInfo();
        }
      }
    },

    // Function to get the additional info from Pacman
    getPacmanInfo() {
      fetch(
        "/usr/share/biglinux/bigstore-cli/pkg_info_pacman.sh?" + this.pkgInfo.p
      )
        .then((response) => response.json())
        .then((json) => {
          this.pacmanInfo = json;
          this.showPkgInfoModalPart2 = true;
        });
    },
    getPacmanInfoAppstream() {
      fetch(
        "/usr/share/biglinux/bigstore-cli/pkg_info_pacman_appstream.sh?" +
          this.pkgInfo.p
      )
        .then((response) => response.json())
        .then((json) => {
          this.pacmanInfoAppstream = json;
        });
    },
    // Function to get the additional info from AUR
    getAurInfo() {
      fetch("json_info_aur.sh?" + this.pkgInfo.p)
        .then((response) => response.json())
        .then((json) => {
          this.aurInfo = json;
          this.showPkgInfoModalPart2 = true;
        });
    },

    init() {
      // Context
      const ctx = this;

      // Trigger Element
      this.triggerElement = this.$refs.scrollContainer.querySelector(
        "#infinite-scroll-trigger"
      );

      // Intersection Observer Supported
      if ("IntersectionObserver" in window) {
        this.observer = new IntersectionObserver(
          function () {
            ctx.loadMore();
          },
          { threshold: [0] }
        );
        this.observer.observe(this.triggerElement);
      }
    },

    // Function to fetch data for all enabled repositories
    async fetchData() {
      try {
        this.bigstoreData = [];
        this.numberOfResults = {};
        let query = this.search
          ? `${this.searchPacman ? " --pacman" : ""}${
              this.searchAUR ? " --aur" : ""
            }${this.searchFlatpak ? " --flatpak" : ""}${
              this.searchSnap ? " --snap" : ""
            } ${this.search}`
          : "";
        // Get response with searched terms
        const response = await fetch(`/usr/bin/bigstore-search.sh?-j${query}`);
        this.bigstoreData = await response.json();

        // Get response with number of results
        const results = await fetch(
          "/api/file?filename=$HOME/.cache/bigstore-cli/numberOfTotalResults.json"
        );
        const resultsInfo = await results.json();

        // Update category count
        this.pacmanCount = resultsInfo.numberOfResults.Pacman;
        this.aurCount = resultsInfo.numberOfResults.AUR;
        this.flatpakCount = resultsInfo.numberOfResults.Flatpak;
        this.snapCount = resultsInfo.numberOfResults.Snap;
      } catch (error) {
        console.error("Error fetching bigstore data:", error);
      }
    },

    performSearch(searchQuery) {
      // Reset max items on any search
      this.maxItems = 30;
      // Scroll to top on search
      window.scrollTo(0, 0);
      if (searchQuery !== undefined) {
        this.search = searchQuery;
      } else {
        this.search = this.$refs.searchInput.value;
      }
      this.fetchData();
      autoCompleteMenuEnabled = false;
      setTimeout(() => {
        autoCompleteMenuEnabled = true;
      }, 500);
    },

    get filteredItems() {
      if (this.search === "") {
        return [];
      }
      return this.bigstoreData.slice(0, this.maxItems);
    },

    checkScroll() {
      if (isThrottled) return;
      isThrottled = true;
      const scrollContainer = this.$refs.scrollContainer;
      if (scrollContainer.clientHeight < window.innerHeight) {
        this.loadMore();
      }
      setTimeout(() => {
        isThrottled = false;
      }, 100);
    },

    get displayedItems() {
      let items = this.filteredItems.slice(0, this.maxItems);
      this.$nextTick(() => {
        this.checkScroll();
      });
      return items;
    },

    loadMore() {
      if (isThrottled) return;
      isThrottled = true;
      this.maxItems += 20;
      if (this.maxItems >= this.filteredItems.length) {
        this.endOfResults = true;
      } else {
        this.endOfResults = false;
      }
      setTimeout(() => {
        isThrottled = false;
      }, 100);
    },

    async fetchIcon(item) {
      try {
        let response;
        let html;
        if (item.ic) {
          item.iconHTML =
            '<img class="large" src="' + item.ic + '" loading="lazy">';
        } else if (item.id) {
          response = await fetch(
            `./find_icon.sh?type=flatpak&query=${item.id}`
          );
          html = await response.text();
          item.iconHTML = html;
        } else {
          response = await fetch(`./find_icon.sh?type=pacman&query=${item.p}`);
          html = await response.text();
          item.iconHTML = html;
        }
      } catch (error) {
        console.error(`Error fetching icon for ${item.p}:`, error);
      }
    },

    selectAutocomplete(value) {
      this.$refs.searchInput.value = value;
      autocompleteResults = [];
      this.performSearch();
    },
  };

  // Return object to be used in alpinejs
  return items;
}

function removeAccents(str) {
  return str.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

// Avatar with colors from https://marcoslooten.com/blog/creating-avatars-with-colors-using-the-modulus/
const colors = [
  "#d50000",
  "#9c27b0",
  "#3f51b5",
  "#00796b",
  "#8d6e63",
  "#b71c1c",
  "#880e4f",
  "#4a148c",
  "#3f51b5",
  "#2196f3",
  "#827717",
  "#ef6c00",
  "#e65100",
  "#546e7a",
  "#009688",
];

function makeIcon(icon) {
  function numberFromText(text) {
    // numberFromText("AA")
    const charCodes = text
      .split("") // => ["A", "A"]
      .map((char) => char.charCodeAt(0)) // => [65, 65]
      .join(""); // => "6565"
    return parseInt(charCodes, 10);
  }

  const text = icon.innerText;
  icon.style.backgroundColor = colors[numberFromText(text) % colors.length];
}

function formatTitle(title) {
  title = title.replace(/[_-]/g, " ");
  title = title
    .split(" ")
    .map((word) => {
      return word.length > 2
        ? word.charAt(0).toUpperCase() + word.slice(1)
        : word;
    })
    .join(" ");
  return title;
}

function formatDescription(description) {
  description = description.trim();
  description = description.charAt(0).toUpperCase() + description.slice(1);
  if (description.charAt(description.length - 1) !== ".") {
    description += ".";
  }
  return description;
}

function packageFormat(type) {
  let format;
  switch (type) {
    case "p":
      format =
        '<div class="secondary bgcolor-pkg-native white-text round"><label class="padding">Nativo</label></div>';
      break;
    case "a":
      format =
        '<div class="secondary bgcolor-pkg-aur white-text round"><label class="padding">Aur</label></div>';
      break;
    case "f":
      format =
        '<div class="secondary bgcolor-pkg-flatpak white-text round"><label class="padding">Flatpak</label></div>';
      break;
    case "s":
      format =
        '<div class="secondary bgcolor-pkg-snap white-text round"><label class="padding">Snap</label></div>';
      break;
    case "w":
      format =
        '<div class="secondary bgcolor-pkg-web white-text round"><label class="padding">Web</label></div>';
      break;
    default:
      format = "";
  }
  return format;
}
