VERSION = $(shell git describe)

commitdata:
	echo return "$(VERSION)" > version.lua
