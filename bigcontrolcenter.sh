#!/bin/bash

./loop-search-json.sh make &


	QT_QPA_PLATFORM=xcb\
		SDL_VIDEODRIVER=x11\
		WINIT_UNIX_BACKEND=x11\
		GDK_BACKEND=x11\
		bigbashview -n "$TITLE" -t gtk -s 1280x720 "bigcontrolcenter.html" -i icon.png -d "$bbvpath"
