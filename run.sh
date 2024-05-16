# package game and deploy web server

# delete old build
rm -r packaged-game
wait

# build game
echo "Building for web..."
love.js game packaged-game -t game -c
wait

# use custom files
cp -r package-src/* packaged-game/
wait

# build .love asynchronously
(
  echo "Building .love file..."
  cd game && zip -qr ../packaged-game/game.love * && cd ..
) &

# start http server
http-server packaged-game
