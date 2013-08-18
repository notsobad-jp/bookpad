require 'net/http'
uri = URI.parse('http://bookpad.herokuapp.com/')
Net::HTTP.get(uri)
