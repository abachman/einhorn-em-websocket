#!/usr/bin/env ruby

require 'rubygems'
require 'einhorn/worker'

require 'eventmachine'
require 'em-websocket'

# Application
require 'json'

# Tiny patch for EventMachine::WebSocket to allow it to start with an existing
# socket using the existing EventMachine.attach_server method.
module EventMachine
  module WebSocket
    def self.run(options)
      host, port, socket = options.values_at(:host, :port, :socket)

      if socket && host.nil? && port.nil?
        puts "starting EventMachine::WebSocket server with socket #{ socket }"
        EM.attach_server(socket, Connection, options) do |c|
          yield c
        end
      else
        EM.start_server(host, port, Connection, options) do |c|
          yield c
        end
      end
    end
  end
end

class SocketServer
  def initialize(identifier, stream)
    @id = identifier
    @sock = stream
    @client_id = "temp-client-id"

    @sock.onopen {|handshake|
      log "opening SocketServer for path #{ handshake.path }"

      # setup context here...
      @context = {
        path: handshake.path,
        headers: handshake.headers
      }

      # wrap any potential calls to @sock.send in a non-blocking block
      EM.defer {
        self.onopen()
      }
    }

    @sock.onmessage(&method(:onmessage))
    @sock.onclose(&method(:onclose))
  end

  def client_id
    @client_id
  end

  def log(msg)
    puts "[#{@id}] #{ msg }"
  end

  def onopen
    log "send onopen"
    @sock.send "#{ client_id } you connected to #{@context[:path]} #{@id}"
  end

  def onmessage(data)
    log "received message from #{ client_id }: #{ data }"

    # Handle the occasional JSON message
    if data[0] == '{'
      begin
        parsed_data = JSON.parse(data)
        case parsed_data['type']
        when 'status'
          log "GOT STATUS"
          @client_id = parsed_data["client_id"]
        else
          log "got unrecognized JSON message"
        end
      rescue => ex
        log "failed to parse data, expected JSON: #{ ex.message }"
      end
    else
      @sock.send("echo #{ @id } [#{ client_id }]: #{ data }")
    end
  end

  def onclose(*args)
    log "#{client_id} closed connection #{ args.inspect }"
  end

  def shutdown
    @sock.send("server #{ @id } is shutting down!")
    sleep 1
  end
end

def einhorn_main
  puts "server.rb called with #{ARGV.inspect}"
  fd_count = Einhorn::Worker.einhorn_fd_count

  unless fd_count > 0
    raise "Need to call with at least one bound socket. Try running 'einhorn -b 127.0.0.1:5000,r ... #{$0}'"
  end

  _id = "server-#{$$}"

  Einhorn::Worker.graceful_shutdown do
    puts "#{$$} is now exiting"

    # server must exit
    exit(0)
  end

  EM.run {
    qs = nil

    (0...fd_count).each do |i|
      # get the corresponding socket for the given einhorn file descriptor
      fd_num = Einhorn::Worker.socket!(i)
      socket = IO.for_fd(fd_num)

      # WebSocket Server
      EM::WebSocket.run(socket: socket, debug: false) do |ws|
        qs = SocketServer.new(_id, ws)
      end
    end

    puts "server #{ fd_count } has launched"
    Einhorn::Worker.ack!
  }
end

if $0 == __FILE__
  einhorn_main
end
