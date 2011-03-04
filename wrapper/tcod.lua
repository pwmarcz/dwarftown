module('tcod', package.seeall)

require "libtcodlua"

local tcod = {}

local function translate(from, to, patterns, exec)
   for key, value in pairs(from) do
      for _, pattern in pairs(patterns) do
         local s1, s2 = key:match(pattern)
         local t
         if s1 then
            if s2 then
               s1 = s1:lower()
               to[s1] = to[s1] or {}
               t = to[s1]
            else
               t = to
               s2 = s1
            end
            if exec then
               t[s2] = value()
            else
               t[s2] = value
            end
            break
         end
      end
   end
end

translate(libtcodlua, tcod,
          {"^TCOD([^_]+)_(.*)",
           "^TCOD([^_]+)",
           "^TCOD_(.+)",
           "(.+)"},
          false)

translate(getmetatable(libtcodlua)[".get"], tcod,
          {"^TCOD([^_]+)_(.+)",
           "^TCOD_(.+)",
           "(.+)"},
          true)
--[[
function _alpha(alpha)
	return tcod.Alpha + math.floor(alpha*255)*(2^8)
end
function _addAlpha(alpha)
	return tcod.AddAlpha + math.floor(alpha*255)*(2^8)
end
tcod.console.Alpha=_alpha
tcod.console.AddAlpha=_addAlpha
--]]

function list(tbl, pre, offset)
   tbl = tbl or tcod
   pre = pre or 'tcod.'
   offset = offset or 0
   local keys = {}
   for k, _ in pairs(tbl) do
      table.insert(keys, k)
   end
   table.sort(keys)
   for _, k in ipairs(keys) do
      local v = tbl[k]
      for _=1,offset do
         io.write(' ')
      end
      print(pre .. k)
      if type(v) == 'table' then
         list(v, pre .. k .. '.', offset+2)
      end
   end
end

for k, v in pairs(tcod) do
   _G[k] = v
end
