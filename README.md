# oomph

> put a little oomph into it.


oomph is sequencer with multiple built-in voices. this script combines some previously contributed projects with additions. it currently encompasses:

- a monophonic synthesizer with accented filters (from [acid-test](https://github.com/schollz/acid-test))
- a sample loop player with customizable effects (from [amen](https://github.com/schollz/amen))
- a sample-based chord sequencer (from [synthy](https://github.com/schollz/synthy))
- a [plaits module](TODO) (from [mi-ugens]())
- a tape emulator (from [portedplugins]()/[tapedeck](https://github.com/schollz/tapedeck))

the additional features that differ scripts from their original counterparts include:

- better accenting dynamics for the monophonic synth
- internal modulation toggles for nearly every parameter
- chainable sequencer with 16 tracks and 16 steps/track for monophonic synth

## Requirements

- norns
- (optional) midi controller
- (optional) grid

## Documentation

most of the usage can be found in the parameters - you can directly edit parameters or use a midi controller to map devices for easy manipulation. there are also LFOs for nearly every parameter accessible through the "MOD" menus. 

the main screen allows you to sequence the monophonic synth.

- K2 changes a parameter
- K3 stops/starts 
- E1 changes pattern
- E2/E3 navigate the individual parameters

the parameters are set out in columns, where each column is one of the sixteen steps of the sequence. 

the first row is the note in the C major scale (this scale is transposed in parameters but still displays as the C major scale.

the second row allows you to modify the accidentals of each note (b = flat, and # = sharp).

the third row allows you to change the octave of each note - M for minus octave (-1) and P for plus octave (+1).

the fourth row allows you to add an accent or slide. "O" does an accent (i.e. provides **O**mph) and "H" provides a slide (i.e. **H**olds the note longer during a change).

the fifth row can change the articulation of the sequence. the "@" denotes a gate, the "o" is a rest" and a "-" after a gate provides a legato. the actual strength of a legato is controlled in teh parameters by the "sustain" parameter.

### audio input

audio input is re-routed through norns into the tape emulator. because of this, instead of using the "MONITOR" control in the audio mixer, you should instead use the "INPUT LEVEL" control in the parameters menu.

### grid

grid is simply an alternative interface for the main norns screen - it is totally optional.

the first five rows edit the parameters of the monophonic synth. the sixth row can be used to change patterns. the sixth row also allows chaining patterns by holding down one pattern key and pressing another *while playing*. the sixth row also allows copying patterns by holding down one pattern key and pressing another *while not playing*.


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
- ~~add start and stop buttons~~
- ~~add start and stop transport~~
- ~~allow using other samples for the pad~~
- ~~allow 16 tracks~~
- add more chaotic lfos
- add midi out to things

## known bugs

- (cosmetic bug) if you goto a "MOD" and toggle one, and you go to the non-MOD page and change the parameter it will automatically turn off the toggle *but the toggle won't appeared to be turned off in the menu* until you exit the menu and come back into the menu.
- (ux bug) MOD lfos are set according to the current tempo, if you change tempos the MOD lfos will stay with periods from the previous tempo
- the sample looper may not work with mono sound files


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
