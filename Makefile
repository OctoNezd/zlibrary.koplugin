VERSION = $(shell git describe)

commitdata:
	echo return \"$(VERSION)\" > zl-version.lua
