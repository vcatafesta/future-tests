{
  split($0, lines, "\n");
  print "{";
  for (i in lines) {
    if (lines[i] ~ /^(Repository|Name|Version|Description|Architecture|URL|Licenses|Download Size|Installed Size|Packager|Build Date|MD5 Sum|SHA-256 Sum|Signatures)/) {
      split(lines[i], kv, / : /);
      gsub(/"/, "\\\"", kv[2]);
      kv[1] = gensub(/ +$/, "", "g", kv[1]);  # Trim trailing spaces in key
      print "\"" kv[1] "\": \"" kv[2] "\",";
    }
    else if (lines[i] ~ /^(Groups|Provides|Depends On|Optional Deps|Required By|Optional For|Conflicts With|Replaces)/) {
      split(lines[i], kv, / : /);
      kv[1] = gensub(/ +$/, "", "g", kv[1]);  # Trim trailing spaces in key
      printf "\"" kv[1] "\": [";
      n = split(kv[2], values, /  /);
      for (j=1; j<=n; j++) {
        gsub(/"/, "\\\"", values[j]);
        if (values[j] != "None" && values[j] != "") {
          printf "\"" values[j] "\"";
          if (j < n) printf ", ";
        }
      }
      print "],";
    }
  }
  print "\"end\":\"\"}"
}
