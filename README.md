# acid-pattern

## install

install mx.samples2
```
;install https://github.com/schollz/mx.samples2
```

get the nessecary patch

```
os.execute("mkdir -p ~/dust/audio/mx.samples/ultra_synth")
os.execute("wget https://github.com/schollz/mx.samples/releases/download/samples/ultra_synth.zip -P /tmp/")
os.execute("unzip /tmp/ultra_synth.zip -d ~/dust/audio/mx.samples/ultra_synth/")
```

install tapedeck

```
os.execute("cd /tmp && wget https://github.com/schollz/tapedeck/releases/download/PortedPlugins/PortedPlugins.tar.gz && tar -xvzf PortedPlugins.tar.gz && rm PortedPlugins.tar.gz && sudo rsync -avrP PortedPlugins /home/we/.local/share/SuperCollider/Extensions/")
```

install acid-pattern

```
;install https://github.com/schollz/acid-pattern
```


## todos

- ~~lfos for each parameter (depth and period)~~
- ~~clamps on all the variables in SuperCollider~~
- ~~duration working~~
- ~~fix amen cleanup~~
- ~~add scale changes? root note changes?~~
- ~~recover sequence on save~~
- use toggles instead of triggers for lfos: TODO test
- stutter fx (gated etc): TODO test
- ~~allow pattern to draw itself~~
- ~~allow multiple patterns~~
- add more chaotic lfos
- ~~add start and stop buttons~~
- ~~add start and stop transport~~
- allow using other samples for the pad
- allow 16 tracks