local sox={}

debugging=true

function os.capture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

function os.cmd(cmd)
  if debugging then
    print(cmd)
  end
  os.execute(cmd.." 2>&1")
end

local charset={}
-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i=48,57 do table.insert(charset,string.char(i)) end
for i=65,90 do table.insert(charset,string.char(i)) end
for i=97,122 do table.insert(charset,string.char(i)) end

function string.random(length)
  if length>0 then
    return string.random(length-1)..charset[math.random(1,#charset)]
  else
    return ""
  end
end

function string.random_filename(suffix,prefix)
  suffix=suffix or ".wav"
  prefix=prefix or "soxtemp-"
  return prefix..string.random(8)..suffix
end

function sox.stutter(data)
  -- bpm = tempo
  -- start = start time in seconds
  -- stop = stop time in seconds
  -- div = delay echo time in 1/4,1/8,1/16th note
  -- repeats = # of repeats
  -- bend = semitones to bend
  -- fname = file input
  -- fname2 = file to output
  local bpm=data.bpm or 120
  local start_pos=data.start or 0
  local beat=data.beat or 1/8
  local stop_pos=start_pos+(60/bpm*beat*4)
  local div=data.div or 1/16
  local repeat_length=(60/bpm*div*4)
  local repeats=data.repeats or 8
  local no_reverse=data.no_reverse
  local seconds=stop_pos-start_pos
  local bend=data.bend or 0
  local fname2=data.fname2 or string.random_filename()
  local gain=data.gain or 0.8
  local gain=data.gain or 0.8
  local sox_cmd=""
  local delay_ms=repeat_length*1000 -- in milliseconds
  local total_time=repeat_length*repeats
  local reverse_string=no_reverse and "" or "reverse "
  sox_cmd=string.format("/home/we/dust/code/acid-pattern/lib/sox %s %s trim %2.6f %2.6f %secho 1.0 1.0",data.fname,fname2,start_pos,seconds,reverse_string)
  local vol=gain
  for i=1,repeats do
    sox_cmd=sox_cmd..string.format(" %2.6f %2.6f ",delay_ms*i,vol)
    vol=vol*gain
  end
  sox_cmd=sox_cmd.." "..reverse_string.."silence 1 0.1 0.01% "
  if bend>0 then
    sox_cmd=sox_cmd..string.format(" bend 0,%d,%2.4f ",bend,total_time)
  end
  os.cmd(sox_cmd)
  return fname2
end

return sox
