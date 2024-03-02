function getItems() {
  let autoCompleteMenuEnabled = true;
  let isThrottled = false;

  const items = {
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

    async saveConfig() {
      const config = {
        searchPacman: this.searchPacman,
        searchAUR: this.searchAUR,
        searchFlatpak: this.searchFlatpak,
        searchSnap: this.searchSnap,
      };
      try {
        await fetch("/api/file?filename=$HOME/.config/bigstore/config.json", {
          method: "POST",
          body: JSON.stringify(config),
        });
      } catch (error) {
        console.error("Failed to save config:", error);
      }
    },

    async loadConfig() {
      try {
        const response = await fetch(
          "/api/file?filename=$HOME/.config/bigstore/config.json"
        );
        if (response.ok) {
          const config = await response.json();
          Object.assign(this, config);
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

    toggleMarkForAction(item, action) {
      const listName = `markedFor${action[0].toUpperCase() + action.slice(1)}`;
      const index = this[listName].findIndex(
        (pkg) => pkg.p === item.p && pkg.type === item.t
      );
      if (index > -1) {
        this[listName].splice(index, 1);
      } else {
        this[listName].push({ p: item.p, type: item.t });
        ["Install", "Removal", "Update"].forEach((act) => {
          if (action !== act.toLowerCase()) {
            this[`markedFor${act}`] = this[`markedFor${act}`].filter(
              (pkg) => pkg.p !== item.p || pkg.type !== item.t
            );
          }
        });
      }
    },

    isMarkedForAction(item, actionType) {
      return this[
        `markedFor${actionType[0].toUpperCase() + actionType.slice(1)}`
      ].some((pkg) => pkg.p === item.p && pkg.type === item.t);
    },

    cancelSelection() {
      this.markedForInstall = [];
      this.markedForRemoval = [];
      this.markedForUpdate = [];
    },

    showModal(item) {
      this.showPkgInfoModal = true;
      this.showPkgInfoModalPart2 = false;
      this.pkgInfo = item;
      if (item.t === "p" || (item.t === "a" && item.i === "true")) {
        this.getPacmanInfo();
        this.getPacmanInfoAppstream();
      } else if (item.t === "a") {
        this.getAurInfo();
      }
    },

    // Function to get the additional info from Pacman
    async getPacmanInfo() {
      try {
        const response = await fetch(
          `/usr/share/biglinux/bigstore-cli/pkg_info_pacman.sh?${this.pkgInfo.p}`
        );
        if (response.ok) {
          this.pacmanInfo = await response.json();
          this.showPkgInfoModalPart2 = true;
        }
      } catch (error) {
        console.error("Error fetching Pacman info:", error);
      }
    },

    async getPacmanInfoAppstream() {
      try {
        const response = await fetch(
          `/usr/share/biglinux/bigstore-cli/pkg_info_pacman_appstream.sh?${this.pkgInfo.p}`
        );
        if (response.ok) {
          this.pacmanInfoAppstream = await response.json();
        }
      } catch (error) {
        console.error("Error fetching Pacman Appstream info:", error);
      }
    },

    async getAurInfo() {
      try {
        const response = await fetch(`json_info_aur.sh?${this.pkgInfo.p}`);
        if (response.ok) {
          this.aurInfo = await response.json();
          this.showPkgInfoModalPart2 = true;
        }
      } catch (error) {
        console.error("Error fetching AUR info:", error);
      }
    },

    init() {
      const ctx = this;
      this.triggerElement = this.$refs.scrollContainer.querySelector(
        "#infinite-scroll-trigger"
      );
      if ("IntersectionObserver" in window) {
        this.observer = new IntersectionObserver(
          (entries) => {
            if (entries[0].isIntersecting) ctx.loadMore();
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

    performSearch(searchQuery = this.$refs.searchInput.value) {
      this.maxItems = 30;
      window.scrollTo(0, 0);
      this.search = searchQuery;
      this.fetchData();
      autoCompleteMenuEnabled = false;
      setTimeout(() => (autoCompleteMenuEnabled = true), 500);
    },

    get filteredItems() {
      return this.search === ""
        ? []
        : this.bigstoreData.slice(0, this.maxItems);
    },

    checkScroll() {
      if (isThrottled) return;
      isThrottled = true;
      const scrollContainer = this.$refs.scrollContainer;
      if (scrollContainer.clientHeight < window.innerHeight) this.loadMore();
      setTimeout(() => (isThrottled = false), 100);
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
      this.endOfResults = this.maxItems >= this.filteredItems.length;
      setTimeout(() => (isThrottled = false), 100);
    },

    async fetchIcon(item) {
      try {
        let response;
        let html;
        if (item.ic) {
          item.iconHTML = '<img class="large" src="' + item.ic + '">';
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
  const formats = {
    p: '<div class="secondary bgcolor-pkg-native white-text round"><label class="padding">Nativo</label></div>',
    a: '<div class="secondary bgcolor-pkg-aur white-text round"><label class="padding">Aur</label></div>',
    f: '<div class="secondary bgcolor-pkg-flatpak white-text round"><label class="padding">Flatpak</label></div>',
    s: '<div class="secondary bgcolor-pkg-snap white-text round"><label class="padding">Snap</label></div>',
    w: '<div class="secondary bgcolor-pkg-web white-text round"><label class="padding">Web</label></div>',
  };
  return formats[type] || "";
}
