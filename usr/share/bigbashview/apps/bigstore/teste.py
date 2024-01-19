import json

# Caminho para os arquivos
json_path = '/var/tmp/pamac/packages-meta-ext-v1.json'
translations_path = '/usr/share/bigbashview/apps/bigstore/translations.txt'

# Carregar dados JSON
with open(json_path, 'r') as file:
    packages = json.load(file)

# Carregar traduções
translations = {}
with open(translations_path, 'r') as file:
    for line in file:
        parts = line.strip().split('\t')
        if len(parts) == 2:
            translations[parts[0]] = parts[1]

# Atualizar descrições
for package in packages:
    name = package['Name']
    if name in translations:
        package['Description'] = translations[name]

# Salvar novo arquivo JSON
with open('/var/tmp/translated_packages.json', 'w') as file:
    json.dump(packages, file, indent=4, ensure_ascii=False)
 
