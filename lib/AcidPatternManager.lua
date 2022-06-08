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
    {name="decay",eng="decay",min=0.01,max=64,default=4,div=0.01,unit="beats",exp=true,beats=true},
    {name="accent decay mult",eng="decayfactor",min=0.01,max=4,default=1,div=0.01,unit="x"},
    {name="saw/square",eng="wave",min=0.0,max=1,default=0.0,div=0.01},
    {name="detune",eng="detune",min=0.0,max=1,default=0.02,div=0.01,'notes'},
  }
  params:add_group("BASS",#prams+1)
  params:add{type="number",id="root_note",name="root note",
  min=0,max=127,default=36,formatter=function(param) return MusicUtil.note_num_to_name(param:get(),true) end}

  for _,p in ipairs(prams) do
    params:add_control("threeohthree_"..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action("threeohthree_"..p.eng,function(x)
      if p.beats then
        x=x*clock.get_beat_sec()
      end
      engine["threeohthree_"..p.eng]("dc",0,x,0.2)
      params:set("threeohthree_"..p.eng.."modtrig",0)
      _menu.rebuild_params()
    end)
  end

  params:add_group("BASS SEQUENCER",self.pattern_num+1+3+1)
  params:add_binary("sequencer_on","sequencer on","toggle")
  params:add{type="number",id="copy_from",name="copy from",min=1,max=self.pattern_num,default=1}
  params:add{type="number",id="copy_to",name="copy to",min=1,max=self.pattern_num,default=1}
  params:add_trigger("do_copy","make copy")
  params:set_action("do_copy",function(x)
    if params:get("copy_to")~=params:get("copy_from") then
      print("copied "..params:get("copy_from").." to "..params:get("copy_to"))
      self.ap[params:get("copy_to")]:loads(self.ap[params:get("copy_from")]:dumps())
    end
  end)
  params:add_separator("pattern chaining")
  for i=1,self.pattern_num do
    local s=" ----------------"
    s=s..(i>9 and ">" or "->")
    params:add{type="number",id="pattern"..i,name="pattern "..i..s,min=1,max=self.pattern_num,default=i}
  end

  params:add_group("BASS MOD",#prams*5)
  local mod_ops_ids={"sine","xline","line"}
  local mod_ops_nom={"sine","exp ramp","linear ramp"}
  local debounce_clock=nil
  for _,p in ipairs(prams) do
    params:add_option("threeohthree_"..p.eng.."modoption",p.name.." form",mod_ops_nom,1)
    params:add_control("threeohthree_"..p.eng.."modperiod",p.name.." period",controlspec.new(0.1,120,'exp',0.1,math.random(4,32),"beats",0.1/119.9))
    params:add_control("threeohthree_"..p.eng.."modmin",p.name.." min",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.min,p.unit or "",p.div/(p.max-p.min)))
    params:add_control("threeohthree_"..p.eng.."modmax",p.name.." max",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.max,p.unit or "",p.div/(p.max-p.min)))
    for _,pp in ipairs({"modoption","modperiod","modmin","modmax"}) do
      params:set_action("threeohthree_"..p.eng..pp,function(x)
        if params:get("threeohthree_"..p.eng.."modtrig")==1 then
          if debounce_clock~=nil then
            clock.cancel(debounce_clock)
          end
          debounce_clock=clock.run(function()
            clock.sleep(1)
            params:set("threeohthree_"..p.eng.."modtrig",0)
            clock.sleep(0.1)
            params:set("threeohthree_"..p.eng.."modtrig",1)
            debounce_clock=nil
          end)
        end
      end)
    end
    params:add_binary("threeohthree_"..p.eng.."modtrig",p.name.." trig","toggle")
    params:set_action("threeohthree_"..p.eng.."modtrig",function(x)
      if x~=1 then
        clock.run(function()
          clock.sleep(0.2)
          if params:get("threeohthree_"..p.eng.."modtrig")==0 then
            params:delta("threeohthree_"..p.eng,0.0001)
            params:delta("threeohthree_"..p.eng,-0.0001)
          end
        end)
        do return end
      end
      local min_val=params:get("threeohthree_"..p.eng.."modmin")
      local max_val=params:get("threeohthree_"..p.eng.."modmax")
      local period=params:get("threeohthree_"..p.eng.."modperiod")*clock.get_beat_sec()
      if p.beats then
        min_val=min_val*clock.get_beat_sec()
        max_val=max_val*clock.get_beat_sec()
      end
      print(p.eng,mod_ops_ids[params:get("threeohthree_"..p.eng.."modoption")],min_val,max_val,period)
      engine["threeohthree_"..p.eng](mod_ops_ids[params:get("threeohthree_"..p.eng.."modoption")],min_val,max_val,period)
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
  if content==nil then
    do return end
  end
  local data=json.decode(content)
  for i,v in ipairs(data) do
    print(v)
    self.ap[i]:loads(v)
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

function APM:set_current(i)
  self.ap[i].current=self.ap[self.current].current
  self.current=i
end

function APM:process(beat)
  if self.ap[self.current].current==16 and params:get("sequencer_on")==1 then
    self.current=params:get("pattern"..self.current)
  end
  self.ap[self.current]:process(beat)
end

function APM:next_pattern()
  return params:get("pattern"..self.current)
end

function APM:redraw(x,y,sh,sw)
  self.ap[self.current]:redraw(x,y,sh,sw)
  local width=8
  for i=1,self.pattern_num do
    screen.rect(2+(i-1)*width-2,56,width-2,4)
    local level=self.current==i and 15 or 1
    if params:get("sequencer_on") and self.current~=i and i==params:get("pattern"..self.current) then
      level=4
    end
    screen.level(level)
    screen.fill()
  end
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
