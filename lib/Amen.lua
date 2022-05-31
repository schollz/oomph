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
    {name="volume",eng="amenamp",min=0,max=1,default=0.5,div=0.01},
  }
  params:add_group("AMEN",#prams)
  for _,p in ipairs(prams) do
    params:add_control(p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action(p.eng,function(x)
      engine[p.eng](x)
    end)
  end

  self.til_stutter=0
  self.tempo_known=0
end

function Amen:stutter_build()
  if self.fname==nil then
    do return end
  end
  local divs={8,12,14,16,24}
  local gains={0.808,0.909}
  local bends={-100,0,0,0,0,100,200}

  for i=1,16 do
    local fname2=string.format("/home/we/dust/audio/acid-pattern/stutter_%s_%d.wav",self.filename,i)
    samples=nil
    repeat
      _,samples,_=audio.file_info(fname2)
      sox.stutter({
        fname=self.fname,
        fname2=fname2,
        bpm=self.bpm,
        start=self.duration*math.random(2,30)/32,
        beat=1/divs[math.random(#divs)],
        div=1/16,
        repeats=math.random(9,18),
        gain=gains[math.random(#gains)],
        bend=bends[math.random(#bends)],
        no_reverse=false,
      })
      print(samples)
    until(samples~=nil and samples>10)
  end
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

  -- engine.amenload("/home/we/dust/code/acid-pattern/lib/amenbreak_bpm136.wav",136)
  engine.amenload(fname,self.bpm)
  engine.amenbpm_target(clock.get_tempo())
  engine.amenamp(params:get("amenamp"))
  engine.amenjump(0.0,0.0,1.0)
end

function Amen:stutter()
  if not self.stutter_ready then
    self.stutter_ready=true
    do return end
  end
  self.stutter_ready=nil
  fname=string.format("/home/we/dust/audio/acid-pattern/stutter_%s_%d.wav",self.filename,math.random(1,16))
  local ch,samples,samplerate=audio.file_info(fname)
  local duration=samples/samplerate
  duration=duration*self.tempo_known/self.bpm
  print(fname,duration)
  engine.amenswap(fname,duration)
end

function Amen:process(beat)
  -- modify the known tempo if it changes
  if clock.get_tempo()~=self.tempo_known then
    self.tempo_known=clock.get_tempo()
    engine.amenbpm_target(self.tempo_known)
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
    engine.amenjump(0.0,0.0,1.0)
  end

  -- if a stutter is activated then play it
  if self.stutter_ready then
    self:stutter()
  end
end

return Amen
