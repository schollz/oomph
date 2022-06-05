local Amen={}

local sox=include("acid-pattern/lib/sox")

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
    {name="volume",eng="amp",min=0,max=1,default=0.4,div=0.01},
    {name="rate",eng="rate",min=-1,max=2,default=1,div=0.01},
    {name="vinyl",eng="vinyl",min=0,max=1,default=0,div=0.01},
    {name="bitcrush",eng="bitcrush",min=0,max=1,default=0,div=0.01},
    {name="bitcrush bits",eng="bitcrush_bits",min=4,max=32,default=8,div=0.1,unit='bits'},
    {name="bitcrush rate",eng="bitcrush_rate",min=100,max=44100,default=4000,div=100,exp=true,unit='Hz'},
    {name="scratch",eng="scratch",min=0,max=1,default=0,div=0.01},
    {name="scratch rate",eng="scratchrate",min=0.1,max=20,default=1.2,div=0.1,unit='Hz'},
    {name="strobe",eng="strobe",min=0,max=1,default=0,div=0.01},
    {name="strobe rate",eng="stroberate",min=0.1,max=60,default=1/(clock.get_beat_sec()/8),div=0.1,unit='Hz'},
    {name="timestretch",eng="timestretch",min=0,max=1,default=0,div=0.01},
    {name="timestretch slow",eng="timestretch_slow",min=1,max=20,default=6,div=0.1},
    {name="timestretch beats",eng="timestretch_beats",min=1,max=20,default=6,div=0.1},
    {name="pan",eng="pan",min=-1,max=1,default=0,div=0.01},
    {name="lpf",eng="lpf",min=50,max=20000,default=20000,div=100,exp=true,unit='Hz'},
    {name="hpf",eng="hpf",min=20,max=500,default=20,div=10,exp=true,unit='Hz'},
  }
  params:add_group("AMEN",#prams)
  for _,p in ipairs(prams) do
    params:add_control("amen_"..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action("amen_"..p.eng,function(x)
      engine["amen_"..p.eng]("dc",0,x,0)
    end)
  end
  params:add_group("AMEN MOD",#prams*5)
  local mod_ops_ids={"sine","xline","line"}
  local mod_ops_nom={"sine","exp ramp","linear ramp"}
  for _,p in ipairs(prams) do
    params:add_option("amen_"..p.eng.."modoption",p.name.." form",mod_ops_nom,1)
    params:add_control("amen_"..p.eng.."modperiod",p.name.." period",controlspec.new(0.1,120,'exp',0.1,2,"s",0.1/119.9))
    params:add_control("amen_"..p.eng.."modmin",p.name.." min",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.min,p.unit or "",p.div/(p.max-p.min)))
    params:add_control("amen_"..p.eng.."modmax",p.name.." max",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.max,p.unit or "",p.div/(p.max-p.min)))
    params:add_trigger("amen_"..p.eng.."modtrig",p.name.." trig")
    params:set_action("amen_"..p.eng.."modtrig",function(x)
      print(mod_ops_ids[params:get("amen_"..p.eng.."modoption")],params:get("amen_"..p.eng.."modmin"),
        params:get("amen_"..p.eng.."modmax"),
      params:get("amen_"..p.eng.."modperiod"))
      engine["amen_"..p.eng](mod_ops_ids[params:get("amen_"..p.eng.."modoption")],params:get("amen_"..p.eng.."modmin"),
        params:get("amen_"..p.eng.."modmax"),
      params:get("amen_"..p.eng.."modperiod"))
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
      if math.round(measures)%2==0 then
        local dif=math.abs(math.round(measures)-measures)
        dif=dif-math.round(measures)/60
        if dif<closet_bpm[2] then
          closet_bpm[2]=dif
          closet_bpm[1]=bpm
        end
      end
    end
    bpm=closet_bpm[1]
  end

  self.bpm=bpm
  self.duration=duration
  self.beats_total=duration/(60/bpm)
  self.beats_eigth_notes=self.beats_total*4
  self.beats_reset=true
  self.beat=self.beats_eigth_notes
  self.playing=false
  -- engine.amenload("/home/we/dust/code/acid-pattern/lib/amenbreak_bpm136.wav",136)
  engine.amen_load(fname,self.bpm)
  engine.amen_bpm_target(clock.get_tempo())
  engine.amen_amp("dc",0,0,0)
end

function Amen:toggle_start(start)
  if start==nil then 
    start=not self.playing
  end
  self.playing=start 
  if self.playing then 
    engine.amen_bpm_target(clock.get_tempo())
    engine.amen_jump(0.0,0.0,1.0)
    engine.amen_amp("dc",0,params:get("amen_amp"),0)
  else 
    engine.amen_amp("dc",0,0,0)
  end
end

function Amen:stutter()
  if not self.stutter_ready then
    self.stutter_ready=true
    do return end
  end
  self.stutter_ready=nil

end

function Amen:process(beat)
  -- modify the known tempo if it changes
  if clock.get_tempo()~=self.tempo_known then
    self.tempo_known=clock.get_tempo()
    engine.amen_bpm_target(self.tempo_known)
  end

  -- if incoming beat is anew and beats reset, then reset the internal beat
  if beat==1 and self.beats_reset==true then
    self.beats_reset=false
    self.beat=self.beats_eigth_notes
  end

  -- iterate the internal beat
  self.beat=self.beat+1
  if self.beat>self.beats_eigth_notes then
    self.beat=1
  end

  -- if the internal beat hits 1, reset the drums
  if self.beat==1 then
    engine.amen_jump(0.0,0.0,1.0)
  end

  -- if a stutter is activated then play it
  if self.stutter_ready then
    self:stutter()
  end
end

return Amen
