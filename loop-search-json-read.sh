#!/bin/bash

echo "[" #> $userpath/bigcontrolcenter.json
sed 's|}|},|g' $HOME/.cache/bigcontrolcenter/*.cache
echo '{ "category": "System About", "name": "KSystemLog2", "comment": "Ferramenta de visualização de registros do sistema", "icon": "/usr/share/icons/biglinux-icons-material/scalable/apps/org.kde.ksystemlog.svg", "exec": "ksystemlog -qwindowtitle " }]' #>> $userpath/bigcontrolcenter.json
