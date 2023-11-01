let mode = "dark";

const updateTheme = () => {
  let darkOrLight = document.body.className.indexOf("dark") !== -1 ? "light" : "dark";
  mode = darkOrLight;
  
  const elementLight =  document.getElementById("light");
  const elementDark =  document.getElementById("dark");
  
  if (mode == "dark") {
    elementLight.style.display = 'none';
    elementDark.style.display = '';
  } else {
    elementLight.style.display = '';
    elementDark.style.display = 'none';    
  }
  
  ui("mode", mode);
}

const updateColors = (url) => {
  setTimeout(() => {
    ui("theme", url);
  }, 360);
}

const refresh = () => {
  document.body.style.display = 'none';
  setTimeout(() => {
    document.body.style.display = 'block';
  }, 180);
}