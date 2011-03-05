module('class', package.seeall)

Object = {get = {}}

function Object:makeMetatable()
   mt = {
      __index = function(o, name)
                   getter = self.get[name]
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

   c.get = c.get or {}

   for k, v in pairs(self) do
      c[k] = c[k] or v
   end

   for k, v in pairs(self.get) do
      c.get[k] = c.get[k] or v
   end

   c.metatable = c:makeMetatable()
   return c
end

function Object:make(o)
   o = o or {}
   --o.class = self
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
