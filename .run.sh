#!/bin/bash

# package game and deploy web server

# delete old build
rm -rf .packaged/*
sleep 0.1

# build .love
echo "Building .love file..."
cd src && zip -qr ../.packaged/game.love * && cd ..

# build game for web
echo "Building for web..."
love.js src .packaged -t game -c
sleep 0.1

# use custom files
cp -r .package-src/* .packaged/
sleep 0.1

# start http server
http-server .packaged
