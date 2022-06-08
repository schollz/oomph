# oomph

> put a little oomph into it.


oomph is a norns script that combines some previously contributed projects with additions. it currently encompasses:

- a monophonic synthesizer with accented filters (from [acid-test](https://github.com/schollz/acid-test))
- a sample loop player with customizable effects (from [amen](https://github.com/schollz/amen))
- a sample-based chord sequencer (from [synthy](https://github.com/schollz/synthy))
-  a [plaits module](TODO) (from [mi-ugens]())
-  a tape emulator (from [portedplugins]()/[tapedeck](https://github.com/schollz/tapedeck))

the additional features include:

- better accenting dynamics for the monophonic synth
- internal modulation toggles for nearly every parameter
- chainable sequencer with 16 tracks and 16 steps/track for monophonic synth


## instructions

### mono synth sequencer

the screen shows the monophonic synth sequencer.

### grid

the first five rows edit the parameters of the monophonic synth. the sixth row can be used to change patterns. the sixth row also allows chaining patterns by holding down one pattern key and pressing another *while playing*. the sixth row also allows copying patterns by holding down one pattern key and pressing another *while not playing*.


## install

*oomph* will need 100mb of disk space (95 mb for wav files and 5 mb for SuperCollider files).

there are three steps to install.

**first** open maiden and run the following:

```
;install https://github.com/schollz/oomph
```

**secondly**, keep maiden open and run the following line to make sure everything is copasetic:

```lua
dofile("~/dust/code/oomph/lib/update.lua")
```

**thirdly**, you need to restart your norns.

## update

to update the script just run the following in maiden:

```lua
dofile("~/dust/code/oomph/lib/update.lua")
```


## todos

- ~~lfos for each parameter (depth and period)~~
- ~~clamps on all the variables in SuperCollider~~
- ~~duration working~~
- ~~fix amen cleanup~~
- ~~add scale changes? root note changes?~~
- ~~recover sequence on save~~
- ~~use toggles instead of triggers for lfos~~
- ~~stutter fx (gated etc)~~
- ~~allow pattern to draw itself~~
- ~~allow multiple patterns~~
- add more chaotic lfos
- ~~add start and stop buttons~~
- ~~add start and stop transport~~
- ~~allow using other samples for the pad~~
- ~~allow 16 tracks~~
- add midi out to things

## known bugs

- (cosmetic bug) if you goto a "MOD" and toggle one, and you go to the non-MOD page and change the parameter it will automatically turn off the toggle *but the toggle won't appeared to be turned off in the menu* until you exit the menu and come back into the menu.
- (ux bug) MOD lfos are set according to the current tempo, if you change tempos the MOD lfos will stay with periods from the previous tempo
