VERSION = $(shell git describe --tag --abbrev=0)
default: commitdata
	zip -r zlibrary.koplugin.zip *.lua dialogs functions menus routes

commitdata:
	echo return \"$(VERSION)\" > zl-version.lua
