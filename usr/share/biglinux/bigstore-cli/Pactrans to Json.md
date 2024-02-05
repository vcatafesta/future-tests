# Example to see modifications in upgrade native packages

pactrans --sysupgrade --yolo --print-only | jq -Rnc -f jq/pactrans.jq
