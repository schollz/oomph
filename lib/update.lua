
--- Check if a file or directory exists in this path
function file_exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
 else
	 return false
      end
   end
   return true
end

scandir=function(directory)
  local i,t,popen=0,{},io.popen
  local pfile=popen('ls -pL --group-directories-first "'..directory..'"')
  for filename in pfile:lines() do
    i=i+1
    t[i]=filename
  end
  pfile:close()
  return t
end

function update()
  -- update self
  print("oomph: updating oomph...")
  os.execute("cd /home/we/dust/code/oomph && git pull")

  -- install or update mx.samples2
  if not file_exists("/home/we/dust/code/mx.samples2") then
    print("oomph: installing mx.samples2...")
    os.execute("git clone https://github.com/schollz/mx.samples2 /home/we/dust/code/mx.samples2")
  else
    print("oomph: updating mx.samples2...")
    os.execute("cd /home/we/dust/code/mx.samples2 && git pull")
  end

  -- install ultra synth patch
  if not file_exists("/home/we/dust/audio/mx.samples/ultra_synth") then
    print("oomph: installing synth samples...")
    os.execute("mkdir -p /home/we/dust/audio/mx.samples/ultra_synth")
    os.execute("wget --quiet https://github.com/schollz/mx.samples/releases/download/samples/ultra_synth.zip -P /tmp/")
    os.execute("unzip /tmp/ultra_synth.zip -d /home/we/dust/audio/mx.samples/ultra_synth/")
    os.execute("rm /tmp/ultra_synth.zip")
  end

  -- install ported plugins if not already
  if not file_exists("/home/we/.local/share/SuperCollider/Extensions/PortedPlugins") then
    print("oomph: installing PortedPlugins...")
    os.execute("wget --quiet https://github.com/schollz/tapedeck/releases/download/PortedPlugins/PortedPlugins.tar.gz -P /tmp/")
    os.execute("tar -xvzf /tmp/PortedPlugins.tar.gz -C /home/we/.local/share/SuperCollider/Extensions/")
    os.execute("rm PortedPlugins.tar.gz")
  end

  -- install miugens if not already
  local files=scandir("/home/we/.local/share/SuperCollider/Extensions/")
  local has_mi=false
  for _,fname in ipairs(files) do
    if string.find(fname,"mi") then
      has_mi=true
    end
  end
  if not has_mi then
    print("oomph: installing mi-UGens")
    os.execute("wget --quiet https://github.com/schollz/oomph/releases/download/prereqs/mi-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz")
    os.execute("tar -xvzf mi-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz -C /home/we/.local/share/SuperCollider/Extensions/")
    os.execute("rm i-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz")
  end
end

function check()
  print("oomph: checking your installation...")
  local files=scandir("/home/we/.local/share/SuperCollider/Extensions/")
  local has_mi=false
  local has_port=false
  for _,fname in ipairs(files) do
    if string.find(fname,"mi") then
      has_mi=true
    end
    if string.find(fname,"Ported") then
      has_port=true
    end
  end
  print(has_mi and "mi-UGens installed." or "mi-UGens not found!!!")
  print(has_port and "PortedPlugins installed." or "PortedPlugins not found!!!")
  if file_exists("/home/we/dust/code/mx.samples2") then
    print("mx.samples2 installed.")
  else
    print("mx.samples2 not found!!!")
  end
end

update()
check()
