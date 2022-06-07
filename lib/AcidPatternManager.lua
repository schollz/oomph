local APM={}
local ap_=include("lib/AcidPattern")
local MusicUtil=require("musicutil")

function APM:new(o)
  -- https://www.lua.org/pil/16.1.html
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self

  -- define defaults if they are not defined
  o.pattern_num=o.pattern_num or 16
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
  params:add{type="number",id="root_note",name="root note",
  min=0,max=127,default=36,formatter=function(param) return MusicUtil.note_num_to_name(param:get(),true) end}

  for _,p in ipairs(prams) do
    params:add_control("threeohthree_"..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action("threeohthree_"..p.eng,function(x)
      engine["threeohthree_"..p.eng]("dc",0,x,0.2)
    end)
  end
  params:add_group("303 MOD",#prams*5)
  local mod_ops_ids={"sine","xline","line"}
  local mod_ops_nom={"sine","exp ramp","linear ramp"}
  for _,p in ipairs(prams) do
    params:add_option("threeohthree_"..p.eng.."modoption",p.name.." form",mod_ops_nom,1)
    params:add_control("threeohthree_"..p.eng.."modperiod",p.name.." period",controlspec.new(0.1,120,'exp',0.1,2,"s",0.1/119.9))
    params:add_control("threeohthree_"..p.eng.."modmin",p.name.." min",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.min,p.unit or "",p.div/(p.max-p.min)))
    params:add_control("threeohthree_"..p.eng.."modmax",p.name.." max",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.max,p.unit or "",p.div/(p.max-p.min)))
    params:add_trigger("threeohthree_"..p.eng.."modtrig",p.name.." trig")
    params:set_action("threeohthree_"..p.eng.."modtrig",function(x)
      print(mod_ops_ids[params:get("threeohthree_"..p.eng.."modoption")],params:get("threeohthree_"..p.eng.."modmin"),
        params:get("threeohthree_"..p.eng.."modmax"),
      params:get("threeohthree_"..p.eng.."modperiod"))
      engine["threeohthree_"..p.eng](mod_ops_ids[params:get("threeohthree_"..p.eng.."modoption")],params:get("threeohthree_"..p.eng.."modmin"),
        params:get("threeohthree_"..p.eng.."modmax"),
      params:get("threeohthree_"..p.eng.."modperiod"))
    end)
  end

  self.ap={}
  self.current=1
  for i=1,self.pattern_num do
    table.insert(self.ap,ap_:new{id=i})
  end
end

function APM:save(filename)
  local data={}
  for i=1,self.pattern_num do
    table.insert(data,self.ap[i]:dumps())
  end

  filename=filename..".json"
  local file=io.open(filename,"w+")
  io.output(file)
  io.write(json.encode(data))
  io.close(file)
end

function APM:open(filename)
  filename=filename..".json"
  if not util.file_exists(filename) then
    do return end
  end
  local f=io.open(filename,"rb")
  local content=f:read("*all")
  f:close()
  local data=json.decode(content)
  for i,v in ipairs(data) do
    self.ap[i].loads(data)
  end
end

function APM:set(ind,pos,d)
  self.ap[self.current]:set(ind,pos,d)
end

function APM:get(ind,i)
  return self.ap[self.current][ind][i]
end

function APM:current_step()
  return self.ap[self.current].current
end

function APM:process(beat)
  -- TODO: allow chaining?
  self.ap[self.current]:process(beat)
end

function APM:redraw(x,y,sh,sw)
  self.ap[self.current]:redraw(x,y,sh,sw)
  local width=8
  for i=1,self.pattern_num do
    screen.rect(2+(i-1)*width-2,59,width-2,4)
    screen.level(self.current==i and 15 or 2)
    screen.fill()
  end
  screen.move(5+10*self.current,60)
  screen.text_center(".")
end

function APM:change_pattern(d)
  self.current=self.current+d
  if self.current>self.pattern_num then
    self.current=self.current-self.pattern_num
  elseif self.current<1 then
    self.current=self.current+self.pattern_num
  end
end

return APM
