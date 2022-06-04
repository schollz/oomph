local AP={}
local MusicUtil=require("musicutil")

local PUNCUATION_NOTE=1
local PUNCTUATION_REST=2
local PUNCTUATION_TIE=3

function APM:new(o)
  -- https://www.lua.org/pil/16.1.html
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self

  -- define defaults if they are not defined
  o.id=o.id or 1
  o:init()
  return o
end

function APM:init()
  local prams={
    {name="volume",eng="amp",min=0,max=1,default=0.5,div=0.01},
    {name="sub volume",eng="sub",min=0,max=2,default=0.0,div=0.01},
    {name="cutoff",eng="cutoff",min=10,max=10000,default=200.0,div=10,exp=true,unit="Hz"},
    {name="cutoff env",eng="env_adjust",min=10,max=10000,default=500.0,div=10,exp=true,unit="Hz"},
    {name="env accent",eng="env_accent",min=0.0,max=10,default=0,div=0.01},
    {name="res",eng="res_adjust",min=0.01,max=0.99,default=0.303,div=0.01},
    {name="res accent",eng="res_accent",min=0.01,max=0.99,default=0.303,div=0.01},
    {name="portamento",eng="portamento",min=0,max=2,default=0.1,div=0.01,unit="s"},
    {name="sustain",eng="sustain",min=0,max=2,default=clock.get_beat_sec(),div=0.01,unit="s"},
    {name="decay",eng="decay",min=0.01,max=30,default=clock.get_beat_sec()*4,div=0.01,unit="s",exp=true},
    {name="saw/square",eng="wave",min=0.0,max=1,default=0.0,div=0.01},
    {name="detune",eng="detune",min=0.0,max=1,default=0.02,div=0.01,'notes'},
  }
  params:add_group("303",#prams+1)
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 36, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end}

  for _,p in ipairs(prams) do
    params:add_control(self.id..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action(self.id..p.eng,function(x)
      engine["threeohthree_"..p.eng]("dc",0,x,0.2)
    end)
  end
  params:add_group("303 MOD",#prams*5)
  local mod_ops_ids={"sine","xline","line"}
  local mod_ops_nom={"sine","exp ramp","linear ramp"}
  for _,p in ipairs(prams) do
    params:add_option(self.id..p.eng.."modoption",p.name.." form",mod_ops_nom,1)
    params:add_control(self.id..p.eng.."modperiod",p.name.." period",controlspec.new(0.1,120,'exp',0.1,2,"s",0.1/119.9))
    params:add_control(self.id..p.eng.."modmin",p.name.." min",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.min,p.unit or "",p.div/(p.max-p.min)))
    params:add_control(self.id..p.eng.."modmax",p.name.." max",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.max,p.unit or "",p.div/(p.max-p.min)))
    params:add_trigger(self.id..p.eng.."modtrig",p.name.." trig")
    params:set_action(self.id..p.eng.."modtrig",function(x)
      print(mod_ops_ids[params:get(self.id..p.eng.."modoption")],params:get(self.id..p.eng.."modmin"),
        params:get(self.id..p.eng.."modmax"),
      params:get(self.id..p.eng.."modperiod"))
      engine["threeohthree_"..p.eng](mod_ops_ids[params:get(self.id..p.eng.."modoption")],params:get(self.id..p.eng.."modmin"),
        params:get(self.id..p.eng.."modmax"),
      params:get(self.id..p.eng.."modperiod"))
    end)
  end
end

function APM:save(filename)
end

function APM:open(filename)
end

function APM:set(ind,pos,d)

end


function APM:process(beat)
end

function APM:redraw(x,y,sh,sw)
end

return APM
