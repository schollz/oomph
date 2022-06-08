# oomph


oomph is combines together a monophonic synthesizer with accented filters, a sample loop player with customizable effects, a sample-based chord sequencer, a [plaits module](TODO), and a tape emulator.
 
you may recognize some of these aspects as they are combinations of scripts I've previously contributed - notably [amen](https://github.com/schollz/amen) (sample looper), [acid-test](https://github.com/schollz/acid-test) (303-style monosynth), [synthy](https://github.com/schollz/synthy) (chord sequencer) and [tapedeck](https://github.com/schollz/tapedeck) (tape emulator). I thought it would be fun to have a single norns script to serve as a
"groovebox" that would have all these pieces to play with.


## instructions

### grid

the first five rows edit the parameters of the monophonic synth. the last row can be used to control the patterns by holding down one button and clicking another to register changing patterns.

## about


I wanted to make a 303-esque thing and at the heart its very simple - a resonant filter with a saw/square wave. the tricky bit is having the right "accent", the accent envelope circuit affects the amplitude and the filter opening. apparently its not a typical envelope generator - it has a capacitor that doesn't completely discharge allowing you to get "higher" as you add more accents. its well described [in this classic article](https://www.firstpr.com.au/rwi/dfish/303-unique.html):

![article](https://user-images.githubusercontent.com/6550035/172177968-8fa32b81-0b3b-4ae7-a253-93f263fcdd7f.png)

it took a bit but I figured out I could recapitulate this exact behavior using a single bus with multiple envelope generators in SuperCollider:

![supercollider](https://user-images.githubusercontent.com/6550035/172177717-bbd0b5ca-ab4c-4dff-b3eb-4199df110f84.PNG)

<details><summary>sc code</summary><pre>b=Bus.control(s);
c=Bus.control(s);
(
{
	Out.kr(0,EnvGen.ar( Env.new([0, 1, 0], [0.04, 4],-8),TDelay.kr(Impulse.kr(0),0.08),doneAction:2));
}.play;
{
	Out.kr(1,EnvGen.ar( Env.new([0, 1, 0], [0.04, 4],-8),TDelay.kr(Impulse.kr(0),0.08),doneAction:2));
}.play;
{
	Out.kr(0,EnvGen.ar( Env.new([0, 1, 0], [0.04, 4],-8),TDelay.kr(Impulse.kr(0),0.3),doneAction:2));
}.play;
{
	Out.kr(0,EnvGen.ar( Env.new([0, 1, 0], [0.04, 4],-8),TDelay.kr(Impulse.kr(0),0.6),doneAction:2));
}.play;
{
	[In.kr(1),In.kr(0)];
}.plot(2);
)</pre></details>


## install


there are three steps to install.

**first* open maiden and run the following:

```
;install https://github.com/schollz/oomph
```

**second*, keep maiden open and run the following line to make sure everything is copasetic:

```lua
dofile("~/dust/code/oomph/lib/update.lua")
```

**finally* you need to restart your norns.

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
