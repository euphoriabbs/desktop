#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require "socksify"

trap("INT") {exit}

TCPSocket::socks_server = "127.0.0.1"
TCPSocket::socks_port = 9050

class BBSTerm < EM::Connection

  def post_init
    @initialization = true
    init_buffer
  end

  def init_buffer
    @read_buffer = ""
  end

  def receive_data(data)
    @read_buffer += data.force_encoding(Encoding::IBM437).encode(Encoding::UTF_8)

    if @initialization and @read_buffer =~ /\e\[6n/
      @initialization = false
      send_data "\e[6n\r\n"
    end

    @read_buffer.gsub!(/\r\n/, "\n")
    print @read_buffer

    init_buffer
  end
end

class STDINReader < EM::Connection

  def initialize(em)
    @em = em
  end

  def receive_data(data)
    my_data = data.force_encoding(Encoding::UTF_8).encode(Encoding::IBM437)
    my_data.gsub!(/\n/, "\r\n")
    EM.next_tick { @em.send_data(my_data) }
  end
end

EM.run do
  obj = EM.connect(ARGV[0], ARGV[1] || 23, BBSTerm)
  EM.attach($stdin, STDINReader, obj)
end
