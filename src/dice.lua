module('dice', package.seeall)

require 'tcod'

local gen = tcod.Random()

function getInt(a, b)
   return gen:getInt(a, b)
end

-- roll AdB+C
function roll(d)
   local a, b, c = unpack(d)
   local n = c
   for i = 1, a do
      n = n + gen:getInt(1, b)
   end
   return n
end

function describe(d)
   local a, b, c = unpack(d)

   s = a .. 'd' .. b
   if c > 0 then
      s = s .. '+' .. c
   elseif c < 0 then
      s = s .. '-' .. -c
   end
   return s
end

function choice(tbl)
   return tbl[gen:getInt(1, #tbl)]
end

-- TODO frequencies
function choiceEx(tbl, level)
   -- returns nothing or (item, freq)
   local function process(v)
      if level and level > 0 and v.level > level then
         return
      else
         return v, (v.freq or 1)
      end
   end

   local sum = 0
   for _, v in ipairs(tbl) do
      local it, freq = process(v)
      if it then
         sum = sum + freq
      end
   end
   sum = gen:getFloat(0, sum-0.01)
   for _, v in ipairs(tbl) do
      local it, freq = process(v)
      if it then
         sum = sum - freq
         if sum < 0 then
            return it
         end
      end
   end
   assert(false)
end

-- Fisher-Yates shuffle
function shuffle(tbl)
   for i = #tbl, 2, -1 do
      local j = gen:getInt(1, i)
      tbl[j], tbl[i] = tbl[i], tbl[j]
   end
end
