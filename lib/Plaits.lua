local Plaits={}
local MusicUtil=require("musicutil")

function Plaits:new(o)
  -- https://www.lua.org/pil/16.1.html
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self

  o.id=o.id or ""
  o:init()
  return o
end

function Plaits:init()
  local prams={
    {name="volume",eng="amp",min=0,max=4,default=0.5,div=0.01,unit="amp"},
    {name="attack env",eng="attack",min=0,max=10,default=0.01,div=0.01,unit="s"},
    {name="decay env",eng="decayEnv",min=0,max=10,default=clock.get_beat_sec(),div=0.01,unit="s"},
    {name="engine",eng="engine",min=1,max=15,default=13,div=1},
    {name="harm",eng="harm",min=0,max=1,default=0.15,div=0.01},
    {name="timbre",eng="timbre",min=0,max=1,default=0.87,div=0.01},
    {name="morph",eng="morph",min=0,max=1,default=0.76,div=0.01},
    {name="decay",eng="decay",min=0,max=1,default=0.9,div=0.01},
  }
  params:add_group("PLAITS"..self.id,#prams+1)
  params:add{type="number",id="plaits_pitch"..self.id,name="note",min=0,max=127,default=36,formatter=function(param) return MusicUtil.note_num_to_name(param:get(),true) end}
  for _,p in ipairs(prams) do
    params:add_control("plaits_"..p.eng..self.id,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
  end

end

function Plaits:process(beat)
  if beat%4~=0 then
    do return end
  end
  print(beat)
  self:hit()
end

function Plaits:hit()
  engine.plaits(
    params:get("plaits_amp"..self.id),
    params:get("plaits_attack"..self.id),
    params:get("plaits_decayEnv"..self.id),
    math.floor(params:get("plaits_engine"..self.id)),
    params:get("plaits_pitch"..self.id),
    params:get("plaits_harm"..self.id),
    params:get("plaits_morph"..self.id),
    params:get("plaits_timbre"..self.id),
  params:get("plaits_decay"..self.id))
end

return Plaits
