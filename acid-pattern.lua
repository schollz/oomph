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
s=require("sequins")
ap_=include("lib/AcidPattern")
local shift=false

function init()
  ap=ap_:new()

  -- initialize metro for updating screen
  timer=metro.init()
  timer.time=1/15
  timer.count=-1
  timer.event=update_screen
  timer:start()

  lattice=lattice_:new()
  lattice:new_pattern{
    action=function(t)
      ap:process()
    end,
    division=1/16,
  }
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
    elseif k==2 then
    else
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
    elseif k==2 then
    else
    end
  end
end

function redraw()
  screen.clear()
  local x=1
  local y=1
  local sh=7
  local sw=7
  for i=1,16 do
    screen.text_center(x+sw*(i-1),y,i)
    screen.text_center(x+sw*(i-1),y+sw*1,ap.note[i])
    screen.text_center(x+sw*(i-1),y+sw*2,ap.octave[i])
    screen.text_center(x+sw*(i-1),y+sw*3,ap.accent[i])
    screen.text_center(x+sw*(i-1),y+sw*4,ap.duration[i])
  end
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
