VERSION = $(shell git describe)
default: commitdata
	zip zlibrary.koplugin.zip *.lua dialogs functions menus routes

commitdata:
	echo return \"$(VERSION)\" > zl-version.lua
