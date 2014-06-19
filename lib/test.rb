
require "net/http"
http_conn = Net::HTTP.new('192.168.10.8', 2080)

puts   http_conn.address

