# Struct for parsing and storing http request information  from a socket
defmodule HttpRequest do
	
	# Struct stuff 
	defstruct [ :verb, :path, :version, :socket ]
	
	# Parse HTTPRequest information from a socket 
	def parse(socket) do
		first = read_line(socket)
		[ verb, path, version ] = String.split(first, " ")
		
		%HttpRequest{ verb: verb, path: path, version: version, socket: socket }
	end
		
	# read from socket helper function
	defp read_line(socket) do
		# Multiple return values from 
		{:ok, data} = :gen_tcp.recv(socket, 0)
		# return data from the function 
		data
	end

end


# Module for actual http 
defmodule HttpServer do
	require Logger

	def accept(port) do
		#Multiple return values from function call.
		{:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
		
		Logger.info "Accepting connections on port #{port}"
		# begin looping for accepting connections
		loop_acceptor(socket)
	end

	# Loop for connecting acceptions
	defp loop_acceptor(socket) do
		# Get a connection to some client
		{:ok, client} = :gen_tcp.accept(socket)
		# Serve that connection in a different thread
		Task.start_link(fn -> serve(client) end)
		# begin looping for another connection (tail recursion too!)
		loop_acceptor(socket)
	end

	# Serve logic for a client connection 
	defp serve(socket) do
		
		# Parse some information out of the socket
		request = HttpRequest.parse(socket)
		
		# Write some http header stuff
		write("HTTP/1.1 200 OK\n", socket)
		write("Content-Type: text/html; charset=utf-8\n", socket)
		write("\n", socket)
		
		# write(read_file(".", request.path), socket)
		"." |> read_file(request.path)
			|> write(socket)
		
		
		:ok = :gen_tcp.close(socket)
	end
	
	# read file from disk helper function 
	defp read_file(servePath, path) do
		{ status, data } = :file.read_file(servePath <> path)
		
		#like java switch...
		case status do
			# like java case (ok): ... break
			:ok -> data
			# like java default: ... break
			_ -> ("404 " <> path <> " not found")
		end
	end
		

	# read from socket helper function
	defp read_line(socket) do
		{:ok, data} = :gen_tcp.recv(socket, 0)
		data
	end

	# write to socket helper function 
	defp write(line, socket) do
		:gen_tcp.send(socket, line)
	end
	
	
	def main(_args \\ []) do
		accept(9999)
	end
	
end


HttpServer.main 



