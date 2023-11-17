
---

## Steps for Translation and File Conversion

1. **Initial Script Execution**:
   - Run the `json_to_xlsx.sh` file.
   - This will create the `~/.cache/bigstoreTranslation/pacmanAndAur.xlsx` file.

2. **Online Translation**:
   - Upload the `.xlsx` file to an online translation system, such as [Google Translator](https://translate.google.com/).

3. **Saving the Translated Files**:
   - Save the translated files with the name `pacmanAndAur_pt.xlsx`. Replace `pt` with the code of the language you translated to.
   - Store these files in the same folder as the scripts.

4. **Correcting the Translation of the Package Name Column**:
   - Run the `copy_original_p_column_to_translated_xlsx.sh`. This will correct the translation of the column containing the package names.

5. **Conversion to JSON**:
   - Lastly, run the `xlsx_to_json.sh`.
   - This will generate `.json` files that can be used in the big-store.

---
