require 'em-websocket-client'
require 'json'

begin
  CLIENT_COUNT = Integer(ARGV[0]) || 1
rescue
  CLIENT_COUNT = 1
end

class ClientDisconnect < Exception; end

class Client
  def initialize(id)
    @id = id
    @ping_count = 0
  end

  def pinger(conn)
    return if @killed

    EM.add_timer(rand() * 1) {
      @ping_count += 1
      begin
        conn.send_msg "client-#{@id} ping #{@ping_count}"
      rescue => ex
        @killed = true
      end
      pinger(conn)
    }
  end

  def run
    @killed = false
    conn = EventMachine::WebSocketClient.connect("ws://localhost:2345/client/#{ @id }")

    conn.connected do
      log "connected"
      @reconnect_attempts = 0

      # send status and start pinger after a pause
      EM.add_timer(0.1) {
        conn.send_msg(JSON.generate(type: 'status', client_id: @id))
        log "sent status"
      }
    end

    conn.errback do |e|
      log "Got error: #{e}"
    end

    conn.stream do |msg|
      log "<#{msg}>"
      if msg.data == "done"
        conn.close_connection
      end
    end

    conn.disconnect do
      log "DISCONNECTED"
      @killed = true
      reconnect
    end

    # start the moderately frantic activity
    pinger(conn)
  end

  def reconnect
    # reconnect timeout with falloff
    EM.add_timer(0.2 + @reconnect_attempts) {
      @reconnect_attempts += 1
      log "reconnecting attempt #{ @reconnect_attempts }"
      run
    }
  end

  def log(msg)
    puts "[client-console-%s] %s" % [@id, msg]
  end
end

EM.run do
  t = nil
  (1..CLIENT_COUNT).each do |n|
    t = Thread.new do
      EM.next_tick {
        c = Client.new($$ + n)
        c.run
      }
    end
  end
  t.join
end
