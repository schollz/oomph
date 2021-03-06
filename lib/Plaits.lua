local Plaits={}
local MusicUtil=require("musicutil")
local er=require("er")

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
    {name="volume",eng="amp",min=-64,max=32,default=-64,div=0.5,unit="dB",mod={-32,0}},
    {name="pan",eng="pan",min=-1,max=1,default=-0.5,div=0.01,mod={-1,1}},
    {name="attack env",eng="attack",min=0,max=10,default=0.01,div=0.01,unit="s",mod={0.01,0.2}},
    {name="decay env",eng="decayEnv",min=0,max=10,default=clock.get_beat_sec(),div=0.01,unit="s",mod={1,4}},
    {name="engine",eng="engine",min=1,max=15,default=13,div=0.1,mod={13,15}},
    {name="harm",eng="harm",min=0,max=1,default=0.15,div=0.01,mod={0.1,0.5}},
    {name="timbre",eng="timbre",min=0,max=1,default=0.87,div=0.01,mod={0.5,1}},
    {name="morph",eng="morph",min=0,max=1,default=0.38,div=0.01,mod={0.1,0.5}},
    {name="decay",eng="decay",min=0,max=1,default=0.9,div=0.01,mod={0.5,1}},
  }
  local prams_extra={
    {name="euclid n",eng="n",min=1,max=64,default=16,div=1,mod={12,24}},
    {name="euclid k",eng="k",min=0,max=64,default=4,div=1,mod={3,6}},
    {name="euclid shift",eng="w",min=0,max=64,default=0,div=1,mod={0,4}},
  }
  params:add_group("PLAITS"..self.id,#prams+1+#prams_extra)
  params:add{type="number",id="plaits_pitch"..self.id,name="note",min=0,max=127,default=36,formatter=function(param) return MusicUtil.note_num_to_name(param:get(),true) end}
  params:set_action("plaits_pitch"..self.id,function(x)
    engine["plaits_pitch"..self.id]("lag",0,x,0.2)
  end)
  for _,p in ipairs(prams) do
    params:add_control("plaits_"..p.eng..self.id,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action("plaits_"..p.eng..self.id,function(x)
      engine["plaits_"..p.eng..self.id]("lag",0,x,0.2)
      params:set("plaits_"..p.eng..self.id.."modtrig",0)
    end)
  end
  for _,p in ipairs(prams_extra) do
    params:add_control("plaits_"..p.eng..self.id,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))

  end

  params:add_group("PLAITS MOD",#prams*5+#prams_extra*4)
  local mod_ops_ids={"sine","xline","line"}
  local mod_ops_nom={"sine","exp ramp","linear ramp"}
  local debounce_clock=nil
  for _,p in ipairs(prams) do
    params:add_option("plaits_"..p.eng.."modoption",p.name.." form",mod_ops_nom,1)
    params:add_control("plaits_"..p.eng.."modperiod",p.name.." period",controlspec.new(0.1,120,'exp',0.1,math.random(4,32),"beats",0.1/119.9))
    params:add_control("plaits_"..p.eng.."modmin",p.name.." min",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.mod[1],p.unit or "",p.div/(p.max-p.min)))
    params:add_control("plaits_"..p.eng.."modmax",p.name.." max",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.mod[2],p.unit or "",p.div/(p.max-p.min)))
    for _,pp in ipairs({"modoption","modperiod","modmin","modmax"}) do
      params:set_action("plaits_"..p.eng..pp,function(x)
        if params:get("plaits_"..p.eng.."modtrig")==1 then
          if debounce_clock~=nil then
            clock.cancel(debounce_clock)
          end
          debounce_clock=clock.run(function()
            clock.sleep(1)
            params:set("plaits_"..p.eng.."modtrig",0)
            clock.sleep(0.1)
            params:set("plaits_"..p.eng.."modtrig",1)
            debounce_clock=nil
          end)
        end
      end)
    end
    params:add_binary("plaits_"..p.eng.."modtrig",p.name.." trig","toggle")
    params:set_action("plaits_"..p.eng.."modtrig",function(x)
      if x~=1 then
        clock.run(function()
          clock.sleep(0.2)
          if params:get("plaits_"..p.eng.."modtrig")==0 then
            params:delta("plaits_"..p.eng,0.0001)
            params:delta("plaits_"..p.eng,-0.0001)
          end
        end)
        do return end
      end
      local min_val=params:get("plaits_"..p.eng.."modmin")
      local max_val=params:get("plaits_"..p.eng.."modmax")
      local period=params:get("plaits_"..p.eng.."modperiod")*clock.get_beat_sec()
      if p.beats then
        min_val=min_val*clock.get_beat_sec()
        max_val=max_val*clock.get_beat_sec()
      end
      print(p.eng,mod_ops_ids[params:get("plaits_"..p.eng.."modoption")],min_val,max_val,period)
      engine["plaits_"..p.eng](mod_ops_ids[params:get("plaits_"..p.eng.."modoption")],min_val,max_val,period)
    end)
  end

  for _,p in ipairs(prams_extra) do
    params:add_control("plaits_"..p.eng.."modperiod",p.name.." period",controlspec.new(0.1,120,'exp',0.1,math.random(4,32),"beats",0.1/119.9))
    params:add_control("plaits_"..p.eng.."modmin",p.name.." min",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.mod[1],p.unit or "",p.div/(p.max-p.min)))
    params:add_control("plaits_"..p.eng.."modmax",p.name.." max",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.mod[2],p.unit or "",p.div/(p.max-p.min)))
    params:add_binary("plaits_"..p.eng.."modtrig",p.name.." trig","toggle")
  end

  for _,nn in ipairs({"n","k","w"}) do
    params:set_action("plaits_"..nn..self.id,function(x)
      self.euclid=er.gen(params:get("plaits_k"..self.id),params:get("plaits_n"..self.id),params:get("plaits_w"..self.id))
      if self.leavemod==nil then
        params:set("plaits_"..nn.."modtrig",0)
      end
    end)
  end
  self.euclid=er.gen(4,16,0)
end

function Plaits:process(beat)
  local beat=beat%params:get("plaits_n"..self.id)+1
  for _,n in ipairs({"n","k","w"}) do
    if params:get("plaits_"..n.."modtrig")==1 then
      local val=util.linlin(
        -1,1,params:get("plaits_"..n.."modmin"),params:get("plaits_"..n.."modmax"),
      math.sin(2*math.pi*clock.get_beats()/params:get("plaits_"..n.."modperiod")))
      self.leavemod=true
      params:set("plaits_"..n..self.id,val)
      self.leavemod=nil
    end
  end
  if self.euclid[beat] and params:get("plaits_amp")>-60 then
    engine.plaits()
  end
end

return Plaits
