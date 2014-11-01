module("uci.precommit", package.seeall)
require("posix")
require("uci")
require("nixio")
local fs = require "nixio.fs"

function commit(pkg)
   -- Create a directory to store the history, then
   -- copy the live history to this directory.  This
   -- copy acts as a cache and decouples the broadcasting
   -- function from the actual system commit function.
   nixio.fs.mkdir("/tmp/.uci-precommit" )
   fs.copy( "/tmp/.uci/" .. pkg[1], "/tmp/.uci-precommit/" .. pkg[1] )
   nixio.fs.mkdir("/tmp/.uci-precommit-cfg-bk" )
   fs.copy( "/etc/config/" .. pkg[1], "/tmp/.uci-precommit-cfg-bk/" .. pkg[1] )
   os.execute("/usr/sbin/apply_precommit " .. pkg[1])
end

