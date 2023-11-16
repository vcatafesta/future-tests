import pandas as pd
import json
import sys

def combine_and_remove_duplicates(json_path1, json_path2, xlsx_path):
    # Ler o primeiro arquivo JSON
    with open(json_path1, 'r') as file:
        data1 = json.load(file)

    # Ler o segundo arquivo JSON
    with open(json_path2, 'r') as file:
        data2 = json.load(file)

    # Converter os dados JSON para DataFrames
    df1 = pd.DataFrame(data1)
    df1 = df1[['p', 'd']]
    df2 = pd.DataFrame(data2)
    df2 = df2[['p', 'd']]

    # Combinar os dois DataFrames
    combined_df = pd.concat([df1, df2])

    # Remover duplicatas com base na coluna 'p'
    combined_df.drop_duplicates(subset='p', inplace=True)

    # Salvar o DataFrame resultante como um arquivo XLSX
    combined_df.to_excel(xlsx_path, index=False)
    print(f"Arquivo salvo como {xlsx_path}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Uso: arquivo.py endereco_arquivo1.json endereco_arquivo2.json endereco_arquivo.xlsx")
        sys.exit(1)
    
    json_path1 = sys.argv[1]
    json_path2 = sys.argv[2]
    xlsx_path = sys.argv[3]
    combine_and_remove_duplicates(json_path1, json_path2, xlsx_path)
