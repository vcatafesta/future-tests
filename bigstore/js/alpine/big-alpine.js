// Alpine listeners
document.addEventListener('alpine:init', async () => {

    Alpine.magic('fetchjson', () => {
        return async (
            url,
            jsonItem = null,
            method = "GET"
        ) => {
            let response = await xfetch(url = url, jsonItem = jsonItem, method = method)
            return await response;
        }
    })

    Alpine.magic('fetch', () => {
        return async (
            url,
            method = "GET"
        ) => {
            let response = await xfetch(url = url, jsonItem = null, method = method)
            return await response;
        }
    })

})

// Actual fetch function
async function xfetch(url, jsonItem = null, method = 'GET') {

    if (jsonItem == null) {

        return fetch(url, {method: method})
            .then((response) => response.text())
            .then((responseText) => {
                return responseText
            })
            .catch((error) => {
              console.log(error)
            });

    } else {

        return fetch(url, {method: method})
            .then((response) => response.json())
            .then((responseJson) => {
                return responseJson[jsonItem]
            })
            .catch((error) => {
              console.log(error)
            });

    }
}




// Alpine listeners
document.addEventListener('alpine:init', async () => {

    // Existing 'fetchjson' magic method for fetching and returning a specific item from JSON
    Alpine.magic('fetchjson', () => {
        return async (
            url,
            jsonItem = null,
            method = "GET"
        ) => {
            let response = await xfetch(url = url, jsonItem = jsonItem, method = method);
            return response;
        }
    });

    // Existing 'fetch' magic method for fetching and returning text
    Alpine.magic('fetch', () => {
        return async (
            url,
            method = "GET"
        ) => {
            let response = await xfetch(url = url, jsonItem = null, method = method);
            return response;
        }
    });

    // New 'fetchCompleteJson' magic method for fetching and returning complete JSON
    Alpine.magic('fetchCompleteJson', () => {
        return async (
            url,
            method = "GET"
        ) => {
            let response = await xfetchCompleteJson(url, method);
            return response;
        }
    });

});

// Actual fetch function
async function xfetch(url, jsonItem = null, method = 'GET') {

    if (jsonItem == null) {

        return fetch(url, {method: method})
            .then((response) => response.text())
            .then((responseText) => {
                return responseText
            })
            .catch((error) => {
              console.log(error)
            });

    } else {

        return fetch(url, {method: method})
            .then((response) => response.json())
            .then((responseJson) => {
                return responseJson
            })
            .catch((error) => {
              console.log(error)
            });

    }
}

// New fetch function for fetching complete JSON
async function xfetchCompleteJson(url, method = 'GET') {
    return fetch(url, {method: method})
        .then((response) => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .catch((error) => {
            console.error('Fetching complete JSON failed:', error);
        });
}
