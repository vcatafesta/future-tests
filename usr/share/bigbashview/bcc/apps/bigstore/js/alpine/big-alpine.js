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

    Alpine.magic('loadComponent', () => {
        return async (url, target) => {
            const response = await fetch(url);
            const text = await response.text();
            document.querySelector(target).innerHTML = text;
            Alpine.initializeComponent(document.querySelector(target));
        };
    });

    // Função para verificar se o resultado de uma URL é 'active'
    Alpine.magic('isActive', () => {
        return async (url) => {
            try {
                const response = await fetch(url);
                const text = await response.text();
                return text.trim().toLowerCase() === 'true';
            } catch (error) {
                console.error('Erro ao verificar isActive:', error);
                return false;
            }
        };
    });

    // Define uma função global para verificar o estado 'active'
    isActive = function (alpineComponent, url) {
        fetch(url)
            .then(response => response.text())
            .then(text => {
                alpineComponent.active = text.trim();
            })
            .catch(error => {
                console.error('Erro ao verificar isActive:', error);
                return false;
            });
    };

    // Função para inicializar componentes customizados
    document.querySelectorAll('[component]').forEach(async (component) => {
        const componentName = component.getAttribute('component');
        const jsonFile = component.getAttribute('load-json');
        const componentHtml = await fetch(`components/${componentName}.html`).then(res => res.text());
        
        if (jsonFile) {
            const jsonData = await fetch(jsonFile).then(res => res.json());
            component.innerHTML = componentHtml;
            Alpine.addScopeToNode(component, jsonData, Alpine.reactive);
        } else {
            component.innerHTML = componentHtml;
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
