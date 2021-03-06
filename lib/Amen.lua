local Amen={}

--local sox=include("oomph/lib/sox")

function Amen:new(o)
  -- https://www.lua.org/pil/16.1.html
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self

  o:init()
  return o
end

function Amen:init()

  local prams={
    {name="volume",eng="amp",min=-64,max=32,default=-64,div=0.5,unit="dB",mod={-32,0}},
    {name="rate",eng="rate",min=-1,max=2,default=1,div=0.01,mod={-1,1}},
    -- {name="vinyl",eng="vinyl",min=0,max=1,default=0,div=0.01},
    {name="bitcrush",eng="bitcrush",min=0,max=1,default=0,div=0.01,mod={0,1}},
    {name="bitcrush bits",eng="bitcrush_bits",min=4,max=32,default=8,div=0.1,unit='bits',mod={8,16}},
    {name="bitcrush rate",eng="bitcrush_rate",min=100,max=44100,default=4000,div=100,exp=true,unit='Hz',mod={4000,16000}},
    {name="scratch",eng="scratch",min=0,max=1,default=0,div=0.01,mod={0,1}},
    {name="scratch rate",eng="scratchrate",min=0.1,max=20,default=1.2,div=0.1,unit='Hz',mod={0.5,2}},
    {name="strobe",eng="strobe",min=0,max=1,default=0,div=0.01,mod={0,1}},
    {name="strobe rate",eng="stroberate",min=0.1,max=60,default=1/(clock.get_beat_sec()/8),div=0.1,unit='Hz',mod={1,10}},
    {name="timestretch",eng="timestretch",min=0,max=1,default=0,div=0.01,mod={0,1}},
    {name="timestretch slow",eng="timestretch_slow",min=1,max=20,default=6,div=0.1,mod={2,10}},
    {name="timestretch beats",eng="timestretch_beats",min=1,max=20,default=6,div=0.1,mod={2,10}},
    {name="pan",eng="pan",min=-1,max=1,default=0,div=0.01,mod={-1,1}},
    {name="lpf",eng="lpf",min=50,max=20000,default=20000,div=100,exp=true,unit='Hz',mod={1000,15000}},
    {name="hpf",eng="hpf",min=20,max=500,default=20,div=10,exp=true,unit='Hz',mod={20,1000}},
  }
  local fxs={"stutter1","jump1","reverse1"}
  params:add_group("LOOP",#prams+#fxs+5)
  params:add_file("amen_file","load file",_path.audio.."oomph/amenbreak_bpm136.wav")
  params:set_action("amen_file",function(x)
    self:load(x)
  end)

  for _,p in ipairs(prams) do
    params:add_control("amen_"..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action("amen_"..p.eng,function(x)
      engine["amen_"..p.eng]("lag",0,x,params:get("amen_slew"))
      params:set("amen_"..p.eng.."modtrig",0)
    end)
  end
  params:add_control("amen_sync","sync probability",controlspec.new(0,100,'lin',1,75,"%"))
  params:add_control("amen_slew","param slew time",controlspec.new(0.01,30,'exp',0.05,0.2,"s",0.05/30))
  params:add_control("amen_bpm_sample","loop tempo",controlspec.new(40,240,'lin',1,120,"bpm",1/200))
  params:set_action("amen_bpm_sample",function(x) engine.amen_bpm_sample(x) end)
  params:add_control("drumlatency","sample latency",controlspec.new(-1,1,'lin',0.01,0,"beats",0.01/2))
  params:set_action("drumlatency",function(x)
    x=x*clock.get_beat_sec()
    if x>0.2 then
      x=0.2
    elseif x<-0.2 then
      x=-0.2
    end
    print(x)
    engine.amen_latency(x>0 and x or 0)
    engine.threeohthree_latency(x<0 and math.abs(x) or 0)
  end)
  for _,fxname in ipairs(fxs) do
    params:add{type="binary",name=fxname,id="amen_"..fxname,behavior="trigger",action=function(x)
      print(fxname)
      self.fx=self[fxname](self)
    end}
  end

  params:add_group("LOOP MOD",#prams*5)
  local mod_ops_ids={"sine","drunk","xline","line"}
  local mod_ops_nom={"sine","drunk","exp ramp","linear ramp"}
  local debounce_clock=nil
  for _,p in ipairs(prams) do
    params:add_option("amen_"..p.eng.."modoption",p.name.." form",mod_ops_nom,1)
    params:add_control("amen_"..p.eng.."modperiod",p.name.." period",controlspec.new(0.1,120,'exp',0.1,math.random(4,32),"beats",0.1/119.9))
    params:add_control("amen_"..p.eng.."modmin",p.name.." min",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.mod[1],p.unit or "",p.div/(p.max-p.min)))
    params:add_control("amen_"..p.eng.."modmax",p.name.." max",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.mod[2],p.unit or "",p.div/(p.max-p.min)))
    for _,pp in ipairs({"modoption","modperiod","modmin","modmax"}) do
      params:set_action("amen_"..p.eng..pp,function(x)
        if params:get("amen_"..p.eng.."modtrig")==1 then
          if debounce_clock~=nil then
            clock.cancel(debounce_clock)
          end
          debounce_clock=clock.run(function()
            clock.sleep(1)
            params:set("amen_"..p.eng.."modtrig",0)
            clock.sleep(0.1)
            params:set("amen_"..p.eng.."modtrig",1)
            debounce_clock=nil
          end)
        end
      end)
    end
    params:add_binary("amen_"..p.eng.."modtrig",p.name.." trig","toggle")
    params:set_action("amen_"..p.eng.."modtrig",function(x)
      if x~=1 then
        clock.run(function()
          clock.sleep(0.2)
          if params:get("amen_"..p.eng.."modtrig")==0 then
            params:delta("amen_"..p.eng,0.0001)
            params:delta("amen_"..p.eng,-0.0001)
          end
        end)
        do return end
      end
      local min_val=params:get("amen_"..p.eng.."modmin")
      local max_val=params:get("amen_"..p.eng.."modmax")
      local period=params:get("amen_"..p.eng.."modperiod")*clock.get_beat_sec()
      print(p.eng,mod_ops_ids[params:get("amen_"..p.eng.."modoption")],min_val,max_val,period)
      engine["amen_"..p.eng](mod_ops_ids[params:get("amen_"..p.eng.."modoption")],min_val,max_val,period)
    end)
  end

  self.til_stutter=0
  self.tempo_known=0
end

function Amen:load(fname)
  self.fname=fname
  pathname,filename,ext=string.match(self.fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  self.filename=filename
  local ch,samples,samplerate=audio.file_info(fname)
  if samples<10 or samples==nil then
    print("ERROR PROCESSING FILE: "..fname)
    do return end
  end
  local duration=samples/samplerate

  local bpm=fname:match("bpm%d+")
  if bpm~=nil then
    bpm=bpm:match("%d+")
    if bpm~=nil then
      bpm=tonumber(bpm)
    end
  end
  if bpm==0 or bpm==nil then
    local closet_bpm={0,100000}
    for bpm=100,200 do
      local measures=duration/((60/bpm)*4)
      if util.round(measures)%2==0 then
        local dif=math.abs(util.round(measures)-measures)
        dif=dif-util.round(measures)/60
        if dif<closet_bpm[2] then
          closet_bpm[2]=dif
          closet_bpm[1]=bpm
        end
      end
    end
    bpm=closet_bpm[1]
  end

  self.beats_total=util.round(duration/(60/bpm))
  if self.beats_total==0 then 
    self.beats_total=4
  end
  -- recalculate the exact bpm based on the rounded beats
  self.bpm=self.beats_total/(duration/60)
  self.duration=duration
  self.beats_eigth_notes=self.beats_total*4
  self.beats_reset=true
  self.beat=self.beats_eigth_notes
  self.playing=false

  print(fname,self.bpm,self.beats_total)
  params:set("amen_bpm_sample",self.bpm)
  engine.amen_load(fname,self.bpm)
  engine.amen_bpm_target(clock.get_tempo())
end

function Amen:toggle_start(start)
  if start==nil then
    start=not self.playing
  end
  self.playing=start
  if self.playing then
    engine.amen_bpm_target(clock.get_tempo())
    engine.amen_jump(0.0,0.0,1.0)
    engine.amen_amp("lag",0,params:get("amen_amp"),0.2)
  else
    engine.amen_amp("lag",0,-72,0.2)
  end
end

function Amen:stutter1()
  local stutters=math.random(4,24)
  local divisions={4,6,8}
  local division=divisions[math.random(#divisions)]
  local total_time=stutters*clock.get_beat_sec()/division
  engine.amen_amp("xline",params:get("amen_amp")/3,params:get("amen_amp"),total_time)
  engine.amen_lpf("xline",200,params:get("amen_lpf"),total_time)
  local s=math.random(0,31)/32
  local e=s+(clock.get_beat_sec()/division)/self.duration
  engine.amen_jump(s,s,e)
  clock.run(function()
    clock.sleep(total_time)
    engine.amen_jump(s,0.0,1.0)
  end)
end

function Amen:jump1()
  engine.amen_jump(math.random(0,31)/32,0.0,1.0)
end

function Amen:reverse1()
  engine.amen_rate("line",params:get("amen_rate"),-1*params:get("amen_rate"),0.01)
  clock.run(function()
    clock.sync(math.random(1,4))
    engine.amen_rate("line",-1*params:get("amen_rate"),params:get("amen_rate"),0.01)
  end)
end

function Amen:process(beat)
  self.beat=beat%self.beats_eigth_notes

  -- modify the known tempo if it changes
  if clock.get_tempo()~=self.tempo_known then
    self.tempo_known=clock.get_tempo()
    engine.amen_bpm_target(self.tempo_known)
  end

  -- if the internal beat hits 1, reset the drums
  if beat%(math.ceil(self.beats_eigth_notes/16)*16)==0 and math.random(1,100)<params:get("amen_sync") then
    print("reset")
    engine.amen_jump(0.0,0.0,1.0)
  end

  -- if a stutter is activated then play it
  if self.fx~=nil then
    self.fx()
  end
end

return Amen
