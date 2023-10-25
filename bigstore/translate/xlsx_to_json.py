import pandas as pd
import json
import sys

def convert_xlsx_to_json(input_file):
    # Ler o arquivo .xlsx
    df = pd.read_excel(input_file)

    # Criar o dicionário de dados usando os nomes corretos das colunas
    data_dict = {}
    for index, row in df.iterrows():
        package_name = row['p']
        description = row['d']
        data_dict[package_name] = {"t": description}

    return data_dict

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python arquivo.py <entrada.xlsx>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    result = convert_xlsx_to_json(input_file)
    
    # Imprimir o dicionário resultante no formato JSON
    print(json.dumps(result, ensure_ascii=False))

