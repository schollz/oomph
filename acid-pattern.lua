-- acid pattern v0.0.1
-- ?
--
-- llllllll.co/t/?
--
--
--
--    ▼ instructions below ▼
--
-- ?

engine.name="Emu303"
local lattice_=require("lattice")
local ap_=include("lib/AcidPattern")
local amen_=include("lib/Amen")
local shift=false
local pos={1,3}

function init()
  -- setup audio folders
  util.os_capture("mkdir -p /home/we/dust/audio/acid-pattern")

  ap=ap_:new()
  amen=amen_:new()

  -- setup global parameters
  params:add_control("drumlatency","drum latency",controlspec.new(-1,1,'lin',0.01,0,"beats",0.01/2))
  params:set_action("drumlatency",function(x)
    x=x*clock.get_beat_sec()
    if x>0.2 then
      x=0.2
    elseif x<-0.2 then
      x=-0.2
    end
    print(x)
    engine.amen_latency(x>0 and x or 0)
    engine.latency(x<0 and math.abs(x) or 0)
  end)

  -- load in the default parameters
  params:default()
  params:bang()

  -- initialize metro for updating screen
  timer=metro.init()
  timer.time=1/15
  timer.count=-1
  timer.event=update_screen
  timer:start()

  -- setup the lattice clock
  local beat_num=16
  local beat_count=beat_num
  lattice=lattice_:new()
  lattice:new_pattern{
    action=function(t)
      beat_count=beat_count+1
      if beat_count>beat_num then
        beat_count=1
      end
      -- process
      amen:process(beat_count)
      ap:process(beat_count)
    end,
    division=1/16,
  }

  -- dev stuff
  amen:load("/home/we/dust/code/acid-pattern/lib/beats16_bpm150_Ultimate_Jack_Loops_014__BPM_150_.wav")
  -- amen:stutter_build()

  -- start the lattice
  lattice:start()
end

function update_screen()
  redraw()
end

function key(k,z)
  if k==1 then
    shift=z==1
  end
  if shift then
    if k==1 then
    elseif k==2 then
    else
    end
  else
    if k==1 then
    elseif k>1 and z==1 then
      local d=k*2-5
      ap:set(pos[1],pos[2],d)
    end
  end
end

function enc(k,d)
  if shift then
    if k==1 then
    elseif k==2 then
    else
    end
  else
    if k==1 then
    elseif k>1 then
      local k_=k==2 and 2 or 1
      pos[k_]=pos[k_]+(k==2 and d or-d)
      if pos[k_]>16 and k_==2 then
        pos[k_]=pos[k_]-16
      end
      if pos[k_]<1 and k_==2 then
        pos[k_]=pos[k_]+16
      end
      if pos[k_]>4 and k_==1 then
        pos[k_]=pos[k_]-4
      end
      if pos[k_]<1 and k_==1 then
        pos[k_]=pos[k_]+4
      end
    end
  end
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.blend_mode(0)
  local x=2.5
  local y=13
  local sh=9
  local sw=8
  for i=1,16 do
    screen.move(x+sw*(i-1),y)
    screen.text_center(i)
    screen.move(x+sw*(i-1),y+sh*1)
    screen.text_center(ap.key_notes[ap.note[i]])
    screen.move(x+sw*(i-1),y+sh*2)
    screen.text_center(ap.key_octave[ap.octave[i]])
    screen.move(x+sw*(i-1),y+sh*3)
    screen.text_center(ap.key_accent[ap.accent[i]])
    screen.move(x+sw*(i-1),y+sh*4)
    screen.text_center(ap.key_punctuation[ap.punct[i]])
  end
  screen.move(x+sw*(ap.current-1),y-5)
  screen.text_center("^")
  screen.blend_mode(1)
  screen.rect(x+sw*(pos[2]-1)-4,y+sh*(pos[1]-1)+2,10,9)
  screen.fill()
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
