# einhorn + em-websockets echo server

A working example of a WebSocket server built with the
[EventMachine::WebSocket](https://github.com/igrigorik/em-websocket) library
running behind [einhorn](https://github.com/stripe/einhorn). When I went
looking for examples, I couldn't find any, so I built one for myself.

This is NOT library code, this is simply an example of one way you could launch
and control an EventMachine::WebSocket server with einhorn, written for my personal
edification and potential future use at [Figure 53](http://figure53.com).

## Benefits

* very close to zero downtime restarts.
* integrates well with existing em-websocket server code.

## Negatives

* Occasionally loses client.rb status messages when running >1 server process.
* Not sure, haven't stress tested it. Though this is my first EventMachine code
  and that stuff is super tricky to get the hang of. Streaming servers are
  *very* different from stateless HTTP servers.

## Running the example code

### Install

Make sure you have a recent version (version >= 2.0) of Ruby installed. Then
download and install this project's requirements, like so:

```
$ git clone git@github.com:abachman/einhorn-em-websocket.git
$ cd einhorn-em-websocket
$ bundle install
```

### Starting the server

`$ sh run.sh`

This will launch the einhorn process, which launches server.rb.

### Starting the client

Open index.html in the browser of your choice and hit the "Start" button.

***OR***

Run `ruby client.rb` from the project directory. The Ruby client takes one
argument which is the number of clients to launch in parallel. For example:
`ruby client.rb 24` will launch 24 clients in parallel.

It should be noted that the ruby client puts *way* less stress on your CPU.

### Restarting the server

You can use the restart script: `sh restart.sh`

OR you can use the einhorn shell, `einhornsh`, and the `upgrade` command.

Any modifications to the server code will be picked up when the server is
restarted.
