# JSON Fetch Component with Alpine.js

This document describes the `fetchJson` component designed to work with Alpine.js. The component fetches JSON data from specified URLs and displays selected data within a web page.

## Usage

To use the `fetchJson` component, you need to have Alpine.js included in your project. The component is initialized with an object that maps names to API endpoints.

### Example

```html
<!DOCTYPE html>
<html>
<head>
    <!-- Include Alpine.js core and additional plugins -->
    <script src="js/alpine/big-alpine.js" defer></script>
    <script src="js/alpine/alpine.js" defer></script>
</head>
<body>
    <!-- Template tag with x-if directive to conditionally render content -->
    <!-- x-data directive initializes the fetchJson component with the given URLs -->
    <template x-if="isLoaded" x-data="fetchJson({
        laptop: 'https://dummyjson.com/products/search?q=Laptop',
        phone: 'https://dummyjson.com/products/search?q=Phone'
    })">
        <!-- To avoid problems with responsiveness, keep interaction with data within a div, you can use sub divs as much as you need -->
        <div>
            <!-- Span tags with x-text directive to display the product titles -->
            <!-- IDs are used for targeting elements, if necessary -->
            <span id="laptop" x-text="laptop.products[0].title"></span>
            <span id="phone" x-text="phone.products[2].title"></span>
        </div>
    </template>
</body>
</html>

```

In the above code, the `fetchJson` component is initialized with two properties: `laptop` and `phone`. Each property corresponds to a URL endpoint that returns JSON data.

## Requirements

- Alpine.js must be included in your project.
- The `big-alpine.js` script is required if you're using additional Alpine.js plugins.

## Component Initialization

The component is initialized within the `x-data` directive of a `<template>` tag. The `x-if` directive is used to conditionally render the content when the JSON data is loaded and `isLoaded` is `true`.

## Displaying Data

Data is displayed using the `x-text` directive, which sets the text content of the element to the specified expression. Here, we access the `title` of the first product for laptops and the third product for phones.

## Error Handling

Error handling is implemented within the JavaScript code that defines the `fetchJson` component. If an error occurs during the fetch operation, an error message is logged to the console, and the data property is set to `null`.

## Contributions

Contributions to the `fetchJson` component are welcome. Please feel free to submit issues and pull requests to the repository.
