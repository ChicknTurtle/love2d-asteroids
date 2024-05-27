# package game and deploy web server

# delete old build
rm -rf .packaged/*
wait

# build .love
echo "Building .love file..."
cd src && zip -qr ../.packaged/game.love * && cd ..

# build game for web
echo "Building for web..."
love.js src .packaged -t game -c
wait

# use custom files
cp -r .package-src/* .packaged/
wait

# start http server
http-server .packaged
