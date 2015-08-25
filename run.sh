# Run the einhorn executable in the proper Bundler env
#   bundle exec einhorn
# use the manual ACK on server boot
#   -m manual
# bind locally to the given $PORT, allow multiple server processes to bind to
# the same port
#   -b 127.0.0.1:2345,r
# start 2 copies of the server
#   -n 8
# store PID in locally available file for easy kill -HUP signaling
#   -e einhorn.pid
# preload application
#   -p ./server.rb
# run the actual application
#   -- ./server.rb
bundle exec einhorn \
  -m manual \
  -b 127.0.0.1:2345,r \
  -n 8 \
  -e einhorn.pid \
  -p ./server.rb \
  -- ./server.rb


