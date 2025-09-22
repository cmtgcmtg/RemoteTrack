local copas = require("copas")
local socket = require("socket")
local json = require("cjson")

local HttpInfoFromClient = "None"
local DataBase = {}

function DecipherSendHomeComputer()
  local ClientInfo = json.decode(HttpInfoFromClient)
  local Direct = ClientInfo.Password
  local IP = DataBase[Direct]
  local payload = json.encode({
    MouseX = ClientInfo.MouseX,
    MouseY = ClientInfo.MouseY,
    Key = ClientInfo.Key
  })

  local client = assert(socket.tcp())
  client:connect(IP, 8080)
  client:send(payload .. "\n")
  client:close()
end

function AddToDataBase(IP)
  local ClientInfo = json.decode(HttpInfoFromClient)
  local Password = ClientInfo.Password
  DataBase[Password] = IP

  local client = assert(socket.tcp())
  client:connect(IP, 9000)
  client:send("Successfully Entered\n")
  client:close()
end

-- Server 1: Port 8080
local server1 = socket.bind("*", 8080)
copas.addserver(server1, function(c)
  copas.settimeout(c, 10)
  HttpInfoFromClient = copas.receive(c, "*l")
  if HttpInfoFromClient then
    DecipherSendHomeComputer()
    HttpInfoFromClient = "None"
  end
  copas.send(c, "HTTP/1.1 200 OK\r\n\r\n")
  copas.close(c)
end)

-- Server 2: Port 9000
local server2 = socket.bind("*", 9000)
copas.addserver(server2, function(c)
  copas.settimeout(c, 10)
  HttpInfoFromClient = copas.receive(c, "*l")
  if HttpInfoFromClient then
    local IP, Port = c:getpeername()
    AddToDataBase(IP)
    HttpInfoFromClient = "None"
  end
  copas.send(c, "HTTP/1.1 200 OK\r\n\r\n")
  copas.close(c)
end)

print("Listening on ports 8080 and 9000...")
copas.loop()
