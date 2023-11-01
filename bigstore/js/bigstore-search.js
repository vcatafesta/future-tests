// Function to manage and fetch items from multiple software repositories
function getItems() {
   // Variable to hold search terms
   let searchTerms = []
   // Variable to store the search results
   let results = []
   // Flag to control the auto-complete menu
   let autoCompleteMenuEnabled = true
   // Throttle flag to limit the rate of certain operations
   let isThrottled = false

     // Return an object containing properties and methods related to item fetching and search
     return {
        search: '',
        pacmanData: [],
        aurData: [],
        flatpakData: [],
        snapData: [],
        autocompleteResults: [],
        maxItems: 20,
        translatedDescriptions: {},
        filteredItemsCount: 0,
        maxAutoCompleteItems: 10,
        searchPacman: true,
        searchAUR: true,
        searchFlatpak: true,
        searchSnap: true,
        pacmanCount: 0,
        aurCount: 0,
        flatpakCount: 0,
        snapCount: 0,
        endOfResults: false,
        open: false,
        pkgInfo: {},
        item: {},
        additionalInfo: null,
        // Function to save the current configuration
        async saveConfig() {
            try {
                const config = {
                    searchPacman: this.searchPacman,
                    searchAUR: this.searchAUR,
                    searchFlatpak: this.searchFlatpak,
                    searchSnap: this.searchSnap,
                }
                await fetch('/api/file?filename=$HOME/.config/bigstore/config.json', {
                    method: 'POST',
                    body: JSON.stringify(config),
                })

                if (this.searchPacman && !this.pacmanData.length) {
                    this.pacmanData = await this.fetchPacmanData()
                }

                if (this.searchAUR && !this.aurData.length) {
                    this.aurData = await this.fetchAurData()
                }

                if (this.searchFlatpak && !this.flatpakData.length) {
                    this.flatpakData = await this.fetchFlatpakData()
                }

                if (this.searchSnap && !this.snapData.length) {
                    this.snapData = await this.fetchSnapData()
                }
                this.maxItems = 20
            } catch (error) {
                console.error("Fail to save os load config:", error)
            }
        },
        // Function to load the saved configuration
        async loadConfig() {
            try {
                const response = await fetch('/api/file?filename=$HOME/.config/bigstore/config.json')
                if (response.ok) {
                    const config = await response.json()
                    if (config) {
                        this.searchPacman = config.searchPacman
                        this.searchAUR = config.searchAUR
                        this.searchFlatpak = config.searchFlatpak
                        this.searchSnap = config.searchSnap
                    }
                } else {
                    console.error('Failed to load config:', response.status, response.statusText)
                }
            } catch (error) {
                console.error('Error during config load:', error)
            }
        // },showModal(item) {
        //     this.pkgInfo = item
        },


        showModal(item) {
            this.pkgInfo = item;
            // this.$nextTick(() => {
            //     makeIcon(document.querySelector('.makeIcon'));
            // });
        },


        // Function to initialize the setup
        init() {
            this.fetchData().catch(error => {
                console.error("Error during data fetching or processing:", error)
            })

            const autoCompleteMenu = document.querySelector('.min')
            autoCompleteMenu.addEventListener('scroll', this.autoCompleteScrollHandler.bind(this))

            // Context
            const ctx = this

            // Trigger Element
            this.triggerElement = this.$refs.scrollContainer.querySelector('#infinite-scroll-trigger')

            // Intersection Observer Supported
            if ('IntersectionObserver' in window) {
                this.observer = new IntersectionObserver(function (entries) {
                    ctx.loadMore()
                }, { threshold: [0] })
                this.observer.observe(this.triggerElement)
            }
        },
        // Handler for scroll event in autocomplete menu
        autoCompleteScrollHandler(e) {
            const { scrollTop, scrollHeight, clientHeight } = e.target
            if (scrollTop + clientHeight >= scrollHeight) {
                this.maxAutoCompleteItems += 10
                this.filterAutocomplete()
            }
        },
        // Function to filter the autocomplete suggestions
        filterAutocomplete() {
            let searchTerm = this.$refs.searchInput.value.toLowerCase()
            if (searchTerm.length === 0 || autoCompleteMenuEnabled === false) {
                this.autocompleteResults = []
                return
            }
            let allData = []
            if (this.searchPacman) allData = allData.concat(this.pacmanData)
            if (this.searchAUR) allData = allData.concat(this.aurData)
            if (this.searchFlatpak) allData = allData.concat(this.flatpakData)
            if (this.searchSnap) allData = allData.concat(this.snapData)
            let seen = new Set()
            this.autocompleteResults = allData.filter(item => {
                const itemWords = item.p.toLowerCase().split(/[\s-_]+/)
                let searchWords = searchTerm.toLowerCase().split(/[\s-_]+/)
                searchWords = searchWords.filter(word => word.trim() !== '')
                if (searchWords.length === 0) return false
                return searchWords.every(searchWord =>
                    itemWords.some(itemWord =>
                        itemWord.includes(searchWord)
                    )
                )
            }).filter(item => {
                if (seen.has(item.p)) {
                    return false
                } else {
                    seen.add(item.p)
                    return true
                }
            }).slice(0, this.maxAutoCompleteItems)
        },
        // Function to fetch data for all enabled repositories
        async fetchData() {
            // Create an array to store promises
            const fetchPromises = [];

            if (this.searchPacman) {
                fetchPromises.push(this.fetchPacmanData());
            }
        
            if (this.searchAUR) {
                fetchPromises.push(this.fetchAurData());
            }
        
            if (this.searchFlatpak) {
                fetchPromises.push(this.fetchFlatpakData());
            }
        
            if (this.searchSnap) {
                fetchPromises.push(this.fetchSnapData());
            }
        
            // Wait for all promises to resolve
            const [pacmanData, aurData, flatpakData, snapData] = await Promise.all(fetchPromises);
        
            if (this.searchPacman) {
                this.pacmanData = pacmanData;
            }
        
            if (this.searchAUR) {
                this.aurData = aurData;
            }
        
            if (this.searchFlatpak) {
                this.flatpakData = flatpakData;
            }
        
            if (this.searchSnap) {
                this.snapData = snapData;
            }
        },
        async fetchPacmanData() {
            this.pacmanData = []
            const data = await this.fetchWithFallback('json_search_pacman_with_translation.sh').then(res => res.json())
            return this.processCommonData(data, 'pacman')
        },
        async fetchAurData() {
            this.aurData = [];
            const [cacheData, installedData] = await Promise.all([
                this.fetchWithFallback('json_search_aur_with_translation.sh').then(res => res.json()),
                this.fetchWithFallback('json_installed_aur.sh').then(res => res.json())
            ]);
            const processedData = this.processCommonData(cacheData, 'aur');
            this.updateAurDataWithInstalledInfo(processedData, installedData);
            return processedData;
        },
        async fetchFlatpakData() {
            this.flatpakData = [];
            const [cacheData, installedData, updatesData] = await Promise.all([
                this.fetchWithFallback('json_search_flatpak.sh').then(res => res.json()),
                this.fetchWithFallback('json_installed_flatpak.sh').then(res => res.json()),
                this.fetchWithFallback('json_updates_flatpak.sh').then(res => res.json())
            ]);
            return this.processFlatpakData(cacheData, installedData, updatesData);
        },
        async fetchSnapData() {
            this.snapData = [];
            const [cacheData, installedData, updatesData] = await Promise.all([
                this.fetchWithFallback('json_search_snap.sh').then(res => res.json()),
                this.fetchWithFallback('json_installed_snap.sh').then(res => res.json()),
                this.fetchWithFallback('json_updates_snap.sh').then(res => res.json())
            ]);
            return this.processSnapData(cacheData, installedData, updatesData);
        },
        async fetchAdditionalInfo(id, type) {
            try {
                const response = await fetch('packageInfo.sh?type=${type}&id=${id}');
                if (response.ok) {
                    this.additionalInfo = await response.json();
                } else {
                    console.error('Failed to fetch additional info:', response.status, response.statusText);
                }
            } catch (error) {
                console.error('Error during fetchAdditionalInfo:', error);
            }
        },
        // Utility function to fetch data with a timeout
        fetchWithFallback(url, ms = 30000) {
            return Promise.race([
                fetch(url),
                this.timeout(ms, `Timeout after ${ms}ms for ${url}`)
            ]).catch(error => {
                console.error(`Error fetching ${url}:`, error)
                return []
            })
        },
        timeout(ms, message) {
            return new Promise((_, reject) => {
                setTimeout(() => reject(new Error(message)), ms)
            })
        },
        processCommonData(data, source) {
            return data.map(item => {
                // item.d = this.translatedDescriptions[item.p] ? this.translatedDescriptions[item.p].t : (item.d || '')
                item.s = source
                item.searchPackage = item.p ? item.p.toLowerCase() : ''
                item.searchDescription = item.d ? removeAccents(item.d.toLowerCase()) : ''
                item.score = 0
                return item
            })
        },
        processFlatpakData(cacheData, installedData, updatesData) {
            return cacheData.map(item => {
                item.s = 'flatpak'
                item.i = installedData.flatpakInstalled.includes(item.p) ? 'true' : 'false'
                item.u = updatesData.flatpakUpdates.includes(item.p) ? 'true' : 'false'
                item.searchPackage = item.p ? item.p.toLowerCase() : ''
                item.searchDescription = item.d ? removeAccents(item.d.toLowerCase()) : ''
                item.score = 0
                return item
            })
        },
        processSnapData(cacheData, installedData, updatesData) {
            return cacheData.map(item => {
                item.s = 'snap'
                item.i = installedData.snapInstalled.includes(item.p) ? 'true' : 'false'
                item.u = updatesData.snapUpdates.includes(item.p) ? 'true' : 'false'
                item.searchPackage = item.p ? item.p.toLowerCase() : ''
                item.searchDescription = item.d ? removeAccents(item.d.toLowerCase()) : ''
                item.score = 0
                return item
            })
        },
        updateAurDataWithInstalledInfo(data, installedPackages) {
            const dataMap = Object.fromEntries(data.map(item => [item.p, item]))

            for (const [packageName, installedInfo] of Object.entries(installedPackages)) {
                const item = dataMap[packageName]
                if (item) {
                    item.i = 'true'
                    item.i_version = installedInfo.version || ''
                }
            }
        },
        updateFlatpakDataWithInstalledInfo(data, installedPackages) {
            installedPackages.forEach(packageName => {
                const item = data.find(item => item.n === packageName)
                if (item) {
                    item.i = 'true'
                }
            })
        },
        updateSnapDataWithInstalledInfo(data, installedPackages) {
            installedPackages.forEach(packageName => {
                const item = data.find(item => item.n === packageName)
                if (item) {
                    item.i = 'true'
                }
            })
        },
        performSearch() {
            this.search = this.$refs.searchInput.value
            searchTerms = removeAccents(this.search.toLowerCase()).split(/\s+/)
            this.maxItems = 20  // Reset the maxItems count
            this.autocompleteResults = [] // Clean auto complete
            autoCompleteMenuEnabled = false
            // re enable autoCompleteMenu after 400ms
            setTimeout(() => {
                autoCompleteMenuEnabled = true
            }, 200)

        },
        filterData(data) {
            return this.filterByTerms(data, ['p', 'searchDescription'])
        },
        filterDataFlatpak(data) {
            return this.search === '' ? data : this.filterByTerms(data, ['p', 'searchPackage', 'searchDescription'])
        },
        filterDataSnap(data) {
            if (this.search === '') return data
            const results = []
            const added = new Set()

            for (let i = 0; i < data.length; i++) {
                const item = data[i]
                const attributes = ['p', 'searchPackage', 'k', 'searchDescription']
                if (searchTerms.some(term => attributes.some(attr => item[attr].includes(term)))) {
                    if (!added.has(item.p)) { // Verify if the item was already added
                        results.push(item)
                        added.add(item.p) // Add identifier to the set
                    }
                }
            }
            return results
        },
        filterByTerms(data, attributes) {
            const added = new Set();
            if (!Array.isArray(data)) {
                console.warn("Data passed to filterByTerms is not an array:", data);
                return [];
            }
            const matches = attributes.map(() => []);
            for (let i = 0; i < data.length; i++) {
                const item = data[i];
                item.score = 0;  // Reset score here
                if (item.i == 'true') item.score += 4;
                attributes.forEach((attr, idx) => {
                    if (searchTerms.every(term => item[attr].includes(term))) {
                        if (!added.has(item.p)) {  // Only add if not already added
                            matches[idx].push(item);
                            item.score += 5 - idx;
                            added.add(item.p);  // Add identifier to the set
                        }
                    }
                });
            }
            return [].concat(...matches).sort((a, b) => b.score - a.score);
        },
        get filteredItems() {
            if (this.search === '') {
                return []
            }
            let combinedResults = []
            let pacmanCounter = 0, aurCounter = 0, flatpakCounter = 0, snapCounter = 0
            let addResult = (item, counter) => {
                combinedResults.push(item)
                return counter + 1
            }
            if (this.searchPacman) {
                this.filterData(this.pacmanData).forEach(item => {
                    pacmanCounter = addResult(item, pacmanCounter)
                })
            }
            if (this.searchAUR) {
                this.filterData(this.aurData).forEach(item => {
                    aurCounter = addResult(item, aurCounter)
                })
            }
            if (this.searchFlatpak) {
                this.filterDataFlatpak(this.flatpakData).forEach(item => {
                    flatpakCounter = addResult(item, flatpakCounter)
                })
            }
            if (this.searchSnap) {
                this.filterDataSnap(this.snapData).forEach(item => {
                    snapCounter = addResult(item, snapCounter)
                })
            }
            // Update category count
            this.pacmanCount = pacmanCounter
            this.aurCount = aurCounter
            this.flatpakCount = flatpakCounter
            this.snapCount = snapCounter

            // Order by installed and score
            combinedResults.sort((a, b) => {
                if (a.i === 'true' && b.i !== 'true') return -1
                if (b.i === 'true' && a.i !== 'true') return 1
                return b.score - a.score
            })
            return combinedResults
        },
        checkScroll() {
            if (isThrottled) return
            isThrottled = true
            const scrollContainer = this.$refs.scrollContainer
            if (scrollContainer.clientHeight < window.innerHeight) {
                this.loadMore()
            }
            setTimeout(() => {
                isThrottled = false
            }, 100)
        },
        get displayedItems() {
            let items = this.filteredItems.slice(0, this.maxItems)
            this.$nextTick(() => {
                this.checkScroll()
            })
            return items
        },
        loadMore() {
            if (isThrottled) return
            isThrottled = true
            this.maxItems += 20

            if (this.maxItems >= this.filteredItems.length) {
                this.endOfResults = true
            } else {
                this.endOfResults = false
            }

            setTimeout(() => {
                isThrottled = false
            }, 100)
        },
        async fetchIcon(item) {
            try {
                let response
                let html
                if (item.g) {
                    response = await fetch(`./find_icon.sh?type=flatpak&query=${item.g}`)
                    html = await response.text()
                    item.iconHTML = html
                } else {
                    response = await fetch(`./find_icon.sh?type=pacman&query=${item.p}`)
                    html = await response.text()
                    item.iconHTML = html
                }
            } catch (error) {
                console.error(`Error fetching icon for ${item.p}:`, error)
            }
        },
        selectAutocomplete(value) {
            this.$refs.searchInput.value = value
            this.autocompleteResults = []
            this.performSearch()
        },
    }
}

function removeAccents(str) {
    return str.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
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
]

function makeIcon(icon) {
    function numberFromText(text) {
        // numberFromText("AA")
        const charCodes = text
            .split("") // => ["A", "A"]
            .map((char) => char.charCodeAt(0)) // => [65, 65]
            .join("") // => "6565"
        return parseInt(charCodes, 10)
    }

    const text = icon.innerText
    icon.style.backgroundColor = colors[numberFromText(text) % colors.length]
}

function formatTitle(title) {
    title = title.replace(/[_-]/g, ' ')
    title = title.split(' ').map(word => {
        return word.length > 2 ? word.charAt(0).toUpperCase() + word.slice(1) : word
    }).join(' ')
    return title
}

function formatDescription(description) {
    description = description.trim()
    description = description.charAt(0).toUpperCase() + description.slice(1)
    if (description.charAt(description.length - 1) !== '.') {
        description += '.'
    }
    return description
}

