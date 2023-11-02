// FETCHJSON START
document.addEventListener('alpine:init', () => {
    Alpine.data('fetchJson', (urlMap) => ({
        isLoaded: false, // Global loading state
        init() {
            let loadCount = 0; // Counter for the number of JSONs loaded
            Object.entries(urlMap).forEach(([name, url]) => {
                // Initialize the property with null
                this[name] = null;
                fetch(url)
                    .then(response => response.json())
                    .then(jsonData => {
                        this[name] = jsonData; // Assigns the JSON data directly to the property
                        loadCount++;
                        if (loadCount === Object.keys(urlMap).length) {
                            this.isLoaded = true; // Updates isLoaded when all JSONs are loaded
                        }
                    })
                    .catch(error => {
                        console.error(`Error fetching JSON from ${name}:`, error);
                        this[name] = null; // Assign null in case of error
                    });
            });
        },
    }));
}); 
// FETCHJSON END
