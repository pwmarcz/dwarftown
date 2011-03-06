module('class', package.seeall)

Object = {_get = {}}

function Object:makeMetatable()
   mt = {
      __index = function(o, name)
                   getter = self._get[name]
                   if getter then
                      return getter(o)
                   else
                      return self[name]
                   end
                end
   }
   return mt
end

function Object:subclass(c)
   c = c or {}
   c.super = self

   c._get = c._get or {}

   for k, v in pairs(self) do
      if c[k] == nil then
         c[k] = v
      end
   end

   for k, v in pairs(self._get) do
      c._get[k] = c._get[k] or v
   end

   c.metatable = c:makeMetatable()
   return c
end

function Object:make(o)
   o = o or {}
   o.class = self
   setmetatable(o, self.metatable)
   self:initialize(o)
   return o
end

function Object:initialize(o)
   if self.init then
      self.init(o)
   end
   if self.super then
      self.super:initialize(o)
   end
end

function Object:copy()
   local o = {}
   for k, v in pairs(self) do
      o[k] = v
   end
   setmetatable(o, getmetatable(self))
   return o
end

-- Copies object (not all table!) fields
function Object:deepCopy()
   local o = {}
   for k, v in pairs(self) do
      if type(v) == 'table' and v.class then
         o[k] = v:copy()
      else
         o[k] = v
      end
   end
   setmetatable(o, getmetatable(self))
   return o
end
