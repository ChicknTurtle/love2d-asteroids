# package game and deploy web server

# delete old build
rm -r .packaged
wait

# build game
echo "Building for web..."
love.js game .packaged -t game -c
wait

# use custom files
cp -r .package-src/* .packaged/
wait

# build .love
echo "Building .love file..."
cd game && zip -qr ../.packaged/game.love * && cd ..

# start http server
http-server .packaged
