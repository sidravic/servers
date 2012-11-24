require 'socket'
require 'http_parser.rb'
require 'pry'

class Server
  READ_CHUNK = 1024

  attr_accessor :message_complete  

  def initialize(host = '127.0.0.1', port = 9799)
    @port = port 
    @host = host
    @server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
    addr = Socket.pack_sockaddr_in(port, host)
    @server.bind(addr)
    @server.listen(Socket::SOMAXCONN)
    @parser = Http::Parser.new(self)    
    prepare_parser
    trap(:INT) {
      @client.flush
      exit
    }
  end 

  def prepare_parser
    @parser.on_message_begin = Proc.new do 
      @body = ""
    end

    @parser.on_body = Proc.new do |chunk|
      @body << chunk
    end

    @parser.on_message_complete = Proc.new {puts "Message complete...#{@body} \r\n #{@parser.headers}"; @message_incomplete = false;}
  end

  def run
    loop do 
      puts "Back here..."
      @client, @addr = @server.accept
      puts "addrinfo #{@addr.inspect}"
      @message_incomplete = true
      process_loop
      respond
    end

    puts "Loop running is done...."
    
  end

  def respond
    headers = "HTTP/1.1 200 OK \n\r" \
              "Date: #{Time.now.utc} \n\r" \
              "Status: 200 OK" \
              "Connection: close \n\r"

    @client.write(headers << "\n\r")
    @client.write("It Works \n\r")
    @client.close
  end

  def process_loop    
    while @message_incomplete             
      begin
        puts "Stuck here..."
        data = @client.readpartial(READ_CHUNK)
        @parser << data
      rescue => e        
        break
      end
    end     
  end

end

s = Server.new
puts "======================= #{s.message_complete}"
s.run
