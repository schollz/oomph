file_exists=function(name)
  local f=io.open(name,"r")
  if f~=nil then
    io.close(f)
    return true
  else
    return false
  end
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

-- install ultra synth patch
if not file_exists("~/dust/code/mx.samples/ultra_synth") then
  os.execute("mkdir -p ~/dust/audio/mx.samples/ultra_synth")
  os.execute("wget https://github.com/schollz/mx.samples/releases/download/samples/ultra_synth.zip -P /tmp/")
  os.execute("unzip /tmp/ultra_synth.zip -d ~/dust/audio/mx.samples/ultra_synth/")
  os.execute("rm /tmp/ultra_synth.zip")
end

-- install or update mx.samples2
if not file_exists("~/dust/code/mx.samples2") then 
	os.execute("git clone https://github.com/schollz/mx.samples2 ~/dust/code/mx.samples2")
else
	os.execute("cd ~/dust/code/mx.samples2 && git pull")
end

-- install ported plugins if not already
if not file_exists("~/.local/share/SuperCollider/Extensions/PortedPlugins") then
  os.execute("wget https://github.com/schollz/tapedeck/releases/download/PortedPlugins/PortedPlugins.tar.gz -P /tmp/")
  os.execute("tar -xvzf /tmp/PortedPlugins.tar.gz -C ~/.local/share/SuperCollider/Extensions/")
  os.execute("rm PortedPlugins.tar.gz")
end

-- install miugens if not already
local files=scandir("~/.local/share/SuperCollider/Extensions/")
local has_mi=false
for _,fname in ipairs(files) do
  if string.find(fname,"mi") then
    has_mi=true
  end
end
if not has_mi then
  os.execute("wget https://github.com/schollz/oomph/releases/download/prereqs/mi-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz")
  os.execute("tar -xvzf mi-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz -C ~/.local/share/SuperCollider/Extensions/")
  os.execute("rm i-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz")
end
