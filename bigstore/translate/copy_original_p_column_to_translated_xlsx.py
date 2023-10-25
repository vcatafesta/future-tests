import pandas as pd
import sys

def copy_column_from_file1_to_file2(file1_path, file2_path):
    # Ler o primeiro arquivo e obter a coluna 'p'
    df1 = pd.read_excel(file1_path)
    col_p_from_df1 = df1['p']

    # Ler o segundo arquivo
    df2 = pd.read_excel(file2_path)

    # Alterar o nome das colunas do segundo arquivo conforme especificado
    df2.columns = ['p', 'd']

    # Verificar se o tamanho da coluna 'p' do primeiro arquivo é compatível com o segundo arquivo
    if len(col_p_from_df1) != len(df2):
        print("Os arquivos têm números diferentes de linhas. A operação foi cancelada.")
        return

    # Substituir a coluna 'p' no segundo arquivo
    df2['p'] = col_p_from_df1

    # Salvar o segundo arquivo modificado
    df2.to_excel(file2_path, index=False)
    print(f"O arquivo {file2_path} foi modificado com sucesso.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: arquivo.py arquivo1.xlsx arquivo2.xlsx")
        sys.exit(1)
    
    file1_path = sys.argv[1]
    file2_path = sys.argv[2]
    copy_column_from_file1_to_file2(file1_path, file2_path)
