#!/bin/bash
mv settings.json settings.tmp
cp -rv ./* /Volumes/Kindle/koreader/plugins/zlibrary.koplugin/
mv settings.tmp settings.json
diskutil eject Kindle
