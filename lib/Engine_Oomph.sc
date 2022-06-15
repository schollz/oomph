Engine_Oomph : CroneEngine {
// All norns engines follow the 'Engine_MySynthName' convention above
    // all
    var fxbus;
    var fxsyn;
    var fxlfo;

    // <Oomph>
	var synThreeOhThree;
    var busAccent;
    var busTape;
    var valDecayFactor;
    var latencyThreeOhThree;
    var lastSlide=0;
    var lastAccent=0;
    // </Oomph>

    // <Tape>
    var synTape;
    // </Tape>

    // <Amen>
    var sampleBuffAmen;
    var synAmen;
    var playerVinyl; 
    var sampleVinyl;
    var playerSwap;
    var amenparams;
    // </Amen>

    // <pad>
    var synPad;
    var synReverb;
    var bufCheby;
    var busReverb;
    var mxsamples;
    // </pad>

	alloc { 
        
        // <Amen>
        latencyThreeOhThree=0.0;
        fxbus=Dictionary.new();
        fxsyn=Dictionary.new();
        fxlfo=Dictionary.new();
        sampleBuffAmen = Buffer.new(context.server);
        sampleVinyl = Buffer.read(context.server, "/home/we/dust/code/oomph/lib/vinyl2.wav"); 
        playerSwap = 0;
        valDecayFactor=1.0;

        SynthDef("defVinyl",{
            | out=0,bufnum = 0,amp=0,hpf=800,lpf=4000,rate=1,rateslew=4,scratch=0,bpm_target=120,t_trig=1|
            var snd,pos;
            amp = Lag.kr(amp,2);
            amp = amp * VarLag.kr(LFNoise0.kr(1).range(0.1,1),2,warp:\sine);
            rate = Lag.kr(rate,rateslew);
            rate = (scratch<1*rate) + (scratch>0*LFTri.kr(bpm_target/60*2));
            pos = Phasor.ar(
                trig:t_trig,
                rate:BufRateScale.kr(bufnum)*rate,
                end:BufFrames.kr(bufnum),
            );
            snd=BufRd.ar(2,bufnum,pos,
                loop:1,
                interpolation:1
            );
            snd = HPF.ar(snd,hpf);
            snd = LPF.ar(snd,lpf);
            Out.ar(out,snd*amp*EnvGen.ar(Env.new([0,1],[4])));
        }).add;

        SynthDef("defPlaits",{
            arg out,ampBus=0.5,panBus,attackBus,decayEnvBus,engineBus,pitchBus,harmBus,morphBus,timbreBus,decayBus,latency=0;
            var snd,env;
            var amp=DC.kr(In.kr(ampBus)).dbamp;
            var attack=DC.kr(In.kr(attackBus));
            var decayEnv=DC.kr(In.kr(decayEnvBus));
            var engine=DC.kr(In.kr(engineBus));
            var pitch=DC.kr(In.kr(pitchBus));
            var harm=DC.kr(In.kr(harmBus));
            var morph=DC.kr(In.kr(morphBus));
            var timbre=DC.kr(In.kr(timbreBus));
            var decay=DC.kr(In.kr(decayBus));
            var pan=DC.kr(In.kr(panBus));
            env=EnvGen.ar(Env.perc(attack,decayEnv),TDelay.kr(Impulse.kr(0),latency),doneAction:2);
            snd=MiPlaits.ar(
                pitch:pitch,
                harm:harm,
                morph:morph,
                timbre:timbre,
                decay:decay,
                engine:engine.floor,
                trigger:TDelay.kr(Impulse.kr(0),latency),
            );
            snd=snd*env*amp;
            Out.ar(out,Balance2.ar(snd[0],snd[1],pan));
        }).add;

        SynthDef("defAmen",{ 
            arg out=0, bufnum, ampBus, t_trig=0,t_trigtime=0,amp_crossfade=0,loop=1,
            sampleStart=0,sampleEnd=1,samplePos=0, latency=0,
            rateBus,bpm_sample=1,bpm_target=1,
            bitcrushBus,bitcrush_bitsBus,bitcrush_rateBus,
            scratchBus,scratchrateBus,strobeBus,stroberateBus,vinylBus,
            timestretchBus,timestretch_slowBus,timestretch_beatsBus,
            panBus,lpfBus,hpfBus;

            // vars
            var rate;
            var snd,pos,timestretchPos,timestretchWindow;
            var amp=(In.kr(ampBus)-10).dbamp;//bus2
            var rateIn=In.kr(rateBus,1);//bus2
            var bitcrush=In.kr(bitcrushBus);//bus2
            var bitcrush_bits=In.kr(bitcrush_bitsBus);//bus2
            var bitcrush_rate=In.kr(bitcrush_rateBus);//bus2
            var scratch=In.kr(scratchBus);//bus2
            var scratchrate=In.kr(scratchrateBus);//bus2
            var strobe=In.kr(strobeBus);//bus2
            var stroberate=In.kr(stroberateBus);//bus2
            var vinyl=In.kr(vinylBus);//bus2
            var timestretch=In.kr(timestretchBus);//bus2
            var timestretch_slow=In.kr(timestretch_slowBus);//bus2
            var timestretch_beats=In.kr(timestretch_beatsBus);//bus2
            var pan=In.kr(panBus);//bus2
            var lpf=In.kr(lpfBus);//bus2
            var hpf=In.kr(hpfBus);//bus2


            rate = BufRateScale.kr(bufnum) * bpm_target / bpm_sample;
            rate = rate*LinSelectX.kr(EnvGen.kr(Env.new([0,1,1,0],[0.2,2,1]),gate:Changed.kr(rateIn)),[1,rateIn]);
            // scratch effect
            rate = SelectX.kr(scratch,[rate,LFTri.kr(bpm_target/60*scratchrate)],wrap:0);
            pos = Phasor.ar(
                trig:t_trig,
                rate:rate,
                start:((sampleStart*(rate>0))+(sampleEnd*(rate<0)))*BufFrames.kr(bufnum),
                end:((sampleEnd*(rate>0))+(sampleStart*(rate<0)))*BufFrames.kr(bufnum),
                resetPos:samplePos*BufFrames.kr(bufnum)
            );
            timestretchPos = Phasor.ar(
                trig:t_trigtime,
                rate:rate/timestretch_slow,
                start:((sampleStart*(rate>0))+(sampleEnd*(rate<0)))*BufFrames.kr(bufnum),
                end:((sampleEnd*(rate>0))+(sampleStart*(rate<0)))*BufFrames.kr(bufnum),
                resetPos:pos
            );
            timestretchWindow = Phasor.ar(
                trig:t_trig,
                rate:rate,
                start:timestretchPos,
                end:timestretchPos+((60/bpm_target/timestretch_beats)/BufDur.kr(bufnum)*BufFrames.kr(bufnum)),
                resetPos:timestretchPos,
            );

            snd=BufRd.ar(2,bufnum,pos,
                loop:1,
                interpolation:1
            );
            timestretch=Lag.kr(timestretch,2);
            snd=((1-timestretch)*snd)+(timestretch*BufRd.ar(2,bufnum,
                timestretchWindow,
                loop:1,
                interpolation:1
            ));

            snd = RLPF.ar(snd,lpf,0.707);
            snd = HPF.ar(snd,hpf);

            // strobe
            snd = ((strobe<1)*snd)+((strobe>0)*snd*LFPulse.ar(60/bpm_target*stroberate));

            // bitcrush
            snd = (snd*(1-bitcrush))+(bitcrush*Decimator.ar(snd,bitcrush_rate,bitcrush_bits));

            // // vinyl wow + compressor
            // snd=(vinyl<1*snd)+(vinyl>0* Limiter.ar(Compander.ar(snd,snd,0.5,1.0,0.1,0.1,1,2),dur:0.0008));
            // snd =(vinyl<1*snd)+(vinyl>0* DelayC.ar(snd,0.01,VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0,0.01)));                

            // manual panning
            snd = Balance2.ar(snd[0],snd[1],
                pan+SinOsc.kr(60/bpm_target*stroberate,mul:strobe*0.5)
            );
            snd=snd*amp*Lag.kr(amp_crossfade,0.2);

            snd=DelayN.ar(snd,delaytime:Lag.kr(latency));
            Out.ar(out,snd*EnvGen.ar(Env.new([0,1],[4])));
        }).add; 
        // </Amen>




        SynthDef("defThreeOhThree", {
            arg out, busAccent, 
            t_trig=1, note=33, latency=0.0, oneShot=0, ampMod=1, pwBus, detuneBus, waveBus, ampBus, subBus,
            cutoffBus, gainBus, portamentoBus, slide,
            duration=1, sustainBus, decayBus,
            res_adjustBus, res_accentBus,
            env_adjustBus,   env_accentBus, latencyBus;
            var env,waves,filterEnv,filter,snd,res,accentVal,noteVal;
            var pw=In.kr(pwBus);
            var amp=(In.kr(ampBus)-10).dbamp;
            var cutoff=In.kr(cutoffBus);
            var detune=In.kr(detuneBus);
            var wave=In.kr(waveBus);
            var sub=In.kr(subBus).dbamp;
            var gain=In.kr(gainBus);
            var portamento=In.kr(portamentoBus);
            var sustain=In.kr(sustainBus);
            var decay=In.kr(decayBus);
            var res_adjust=In.kr(res_adjustBus);
            var res_accent=In.kr(res_accentBus);
            var env_adjust=In.kr(env_adjustBus);
            var env_accent=In.kr(env_accentBus);
            noteVal=Lag.kr(note,portamento*slide);
            accentVal=In.kr(busAccent);
            res = Clip.kr(res_adjust+(res_accent*accentVal),0.001,2);
            env = EnvGen.ar(Env.new([10e-3,1,1,10e-9],[0.03,sustain*duration,decay],'exp'),t_trig,doneAction:oneShot*2)+(env_accent*accentVal);
            waves = [Saw.ar([noteVal-detune,noteVal+detune].midicps, mul: env), Pulse.ar([note-detune,note+detune].midicps, 0.5, mul: env)];
            filterEnv =  EnvGen.ar( Env.new([10e-9, 1, 10e-9], [0.01, decay],  'exp'), t_trig);
            filter = RLPFD.ar(SelectX.ar(wave, waves, wrap:0), cutoff +(filterEnv*env_adjust), res,gain);
            snd=(filter*amp).tanh;
            snd=snd+SinOsc.ar([noteVal-12-detune,noteVal-12+detune].midicps,mul:sub*env/10.0);
            snd=DelayN.ar(snd,delaytime:Lag.kr(latency));
            snd=snd*ampMod*EnvGen.ar(Env.new([oneShot,1],[4]));
            DetectSilence.ar(snd,0.001,doneAction:oneShot*2);
            Out.ar(out, snd);
        }).add;
        
        SynthDef("defThreeOhThreeAccent",{
            arg out,decay;
            Out.kr(out,EnvGen.ar( Env.new([0,1,0], [0.01, decay], -8),doneAction:2));
            // Out.kr(out,EnvGen.ar( Env.new([10e-9, 1, 10e-9], [0.01, decay],  'exp'),doneAction:2));
        }).add;

        SynthDef("defTape",{
            arg in, auxinBus,tape_wetBus,tape_biasBus,tape_satBus,tape_driveBus,
            tape_oversample=1,mode=0,
            dist_wetBus,dist_driveBus,dist_biasBus,dist_lowBus,dist_highBus,
            dist_shelfBus,dist_oversample=0,
            wowflu=1.0,
            wobble_rpm=33, wobble_amp=0.05, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
            hpfBus=60,hpfqrBus=0.6,
            lpfBus=18000,lpfqrBus=0.6,
            buf;
            var snd=In.ar(in,2);
            var auxin=In.kr(auxinBus).dbamp;//bus
            var tape_wet=In.kr(tape_wetBus);//bus
            var tape_bias=In.kr(tape_biasBus);//bus
            var tape_sat=In.kr(tape_satBus);//bus
            var tape_drive=In.kr(tape_driveBus);//bus
            var dist_wet=In.kr(dist_wetBus);//bus
            var dist_drive=In.kr(dist_driveBus);//bus
            var dist_bias=In.kr(dist_biasBus);//bus
            var dist_low=In.kr(dist_lowBus);//bus
            var dist_high=In.kr(dist_highBus);//bus
            var dist_shelf=In.kr(dist_shelfBus);//bus
            var hpf=In.kr(hpfBus);//bus
            var hpfqr=In.kr(hpfqrBus);//bus
            var lpf=In.kr(lpfBus);//bus
            var lpfqr=In.kr(lpfqrBus);//bus
            snd=snd+(auxin*SoundIn.ar([0,1]));
            snd=SelectX.ar(Lag.kr(tape_wet,1),[snd,AnalogTape.ar(snd,tape_bias,tape_sat,tape_drive,tape_oversample,mode)],wrap:0);
	    // TODO: add different type of distortion?
            //snd=SelectX.ar(Lag.kr(dist_wet/10,1),[snd,AnalogVintageDistortion.ar(snd,dist_drive,dist_bias,dist_low,dist_high,dist_shelf,dist_oversample)],wrap:0);          
            snd=RHPF.ar(snd,hpf,hpfqr);
            snd=RLPF.ar(snd,lpf,lpfqr);
            Out.ar(0,snd*EnvGen.ar(Env.new([0,1],[4])));
        }).add;


        // <pad>
        bufCheby = Buffer.alloc(context.server, 512, 1, { |buf| buf.chebyMsg([1,0,1,1,0,1])});
        SynthDef("defPad",{
            arg outDry, outWet, latency=0.0,amp=0.5, wet=1.0, buf=0,note=53,attack=1,decay=1,sustain=0.5,release=2,notelpf=80;
            var snd,env;
            snd=Shaper.ar(buf,Saw.ar(note.midicps,SinOsc.kr(rrand(1/30,1/5)).range(0.1,1.0)));
            snd=Pan2.ar(snd,rrand(-0.25,0.25));
            snd=RLPF.ar(snd,notelpf.midicps,0.707);
            snd=SelectX.ar(VarLag.kr(LFNoise0.kr(1/10),10,warp:\sine).range(0.1,0.7),[snd,snd*LFPar.ar(VarLag.kr(LFNoise0.kr(1/10),10,warp:\sine).range(1,6))],wrap:0); 
            env=EnvGen.ar(Env.new([0.00001,1.0,sustain,0.00001],[attack,decay,release],curve:[\welch,\sine,\exp]),doneAction:2);
            snd=snd*env*amp*EnvGen.ar(Env.new([0,1],[0.1]));
            snd=snd.tanh;
            Out.ar(outDry,snd*(1-wet));
            Out.ar(outWet,snd*wet);
        }).add;
        SynthDef("defReverb",{
            arg in, out;
            var snd=In.ar(in,2);
            5.do({ snd = AllpassN.ar(snd, 0.050, [Rand(0, 0.05), Rand(0, 0.05)], 1) });
            Out.ar(out,snd);
        }).add;

        // <mods>
        // msg1 = start value
        // msg2 = final value 
        // msg3 = period
        SynthDef("defMod_dc",{
            arg out, msg1=0,msg2=1.0,msg3=1.0;
            FreeSelf.kr(TDelay.kr(Trig.kr(1)));
            Out.kr(out,DC.kr(msg2));
        }).add;

        SynthDef("defMod_lag",{
            arg out, msg1=0,msg2=1.0,msg3=1.0;
            Out.kr(out,Lag.kr(msg2,msg3));
        }).add;

        SynthDef("defMod_drunk",{
            arg out, msg1=0,msg2=1.0,msg3=1.0;
            Out.kr(out,VarLag.kr(LFNoise0.kr(1/msg3),msg3,warp:\sine).range(msg1,msg2));
        }).add;

        SynthDef("defMod_sine",{
            arg out, msg1=2,msg2=0.0,msg3=1.0;
            Out.kr(out,SinOsc.kr(freq:1/msg3).range(msg1,msg2));
        }).add;

        SynthDef("defMod_line",{
            arg out, msg1=0,msg2=1.0,msg3=1.0;
            Out.kr(out,Line.kr(start:msg1,end:msg2,dur:msg3,doneAction:2));
        }).add;


        SynthDef("defMod_xline",{
            arg out, msg1=0,msg2=1.0,msg3=1.0;
            Out.kr(out,XLine.kr(start:msg1+0.00001,end:msg2,dur:msg3,doneAction:2));
        }).add;

        // </mods>

        context.server.sync;
        busTape=Bus.audio(context.server,2);
        busReverb=Bus.audio(context.server,2);
        busAccent=Bus.control(context.server,1);
        context.server.sync;
        synTape=Synth.new("defTape",[\in,busTape]);
        context.server.sync;        
        // define always-on synths
        synThreeOhThree=Synth.before(synTape,"defThreeOhThree",[\busAccent,busAccent,\out,busTape]);
        synReverb=Synth.before(synTape,"defReverb",[\in,busReverb,\out,busTape]); 
        //playerVinyl = Synth("defVinyl",[\bufnum,sampleVinyl,\amp,0,\out,busTape],target:context.xg);
        synAmen = Array.fill(2,{arg i;
            Synth.before(synTape,"defAmen",[\out,busTape])
        });
        context.server.sync;
        mxsamples=MxSamples(context.server,400,busTape);
        context.server.sync;

        // <pad>
        [\amp,\pan,\attack,\decay,\sustain,\release,\delaysend,\reverbsend,\lpf].do({ arg fx;
            var domain="pad";
            var key=domain++"_"++fx;
            this.addCommand(key, "sf", { arg msg;
                mxsamples.setParam(msg[1].asString,fx.asString,msg[2]);
            });
        });

        this.addCommand("pad_note", "sfff", { arg msg;
            mxsamples.noteOn(msg[1].asString,msg[2],msg[3]);
            Routine{
                msg[4].asFloat.wait;
                "note off".postln;
                mxsamples.noteOff(msg[1].asString,msg[2]);
            }.play;

        });
        // </pad>

        // <303>
        this.addCommand("threeohthree_oneshot", "ff", { arg msg;
            Synth.before(synTape,"defThreeOhThree",[\busAccent,busAccent,\out,busTape,
                \t_trig,1,\note,msg[1],\ampMod,msg[2],\oneShot,1,
                \ampBus,fxbus.at("threeohthree_amp").index,
                \pwBus,fxbus.at("threeohthree_pw").index,
                \detuneBus,fxbus.at("threeohthree_detune").index,
                \waveBus,fxbus.at("threeohthree_wave").index,
                \subBus,fxbus.at("threeohthree_sub").index,
                \cutoffBus,fxbus.at("threeohthree_cutoff").index,
                \gainBus,fxbus.at("threeohthree_gain").index,
                \sustainBus,fxbus.at("threeohthree_sustain").index,
                \decayBus,fxbus.at("threeohthree_decay").index,
                \res_adjustBus,fxbus.at("threeohthree_res_adjust").index,
                \res_accentBus,fxbus.at("threeohthree_res_accent").index,
                \env_adjustBus,fxbus.at("threeohthree_env_adjust").index,
                \env_accentBus,fxbus.at("threeohthree_env_accent").index,
                \portamentoBus,fxbus.at("threeohthree_portamento").index,
            ]);
        });

        [\amp,\pw,\detune,\wave,\sub,\cutoff,\gain,\sustain,\decay,\res_adjust,\res_accent,\env_adjust,\env_accent,\portamento].do({ arg fx;
            var domain="threeohthree";
            var key=domain++"_"++fx;
            fxbus.put(key,Bus.control(context.server,1));
            fxbus.at(key).value=1.0;
            synThreeOhThree.set(fx++"Bus",fxbus.at(key).index);
            this.addCommand(key, "sfff", { arg msg;
                var makeSynth=false;
                var freeSynth=false;
                //[msg[1],key,fxsyn.at(key),fxsyn.at(key).isNil].postln;
                if (msg[1].asString=="lag",{
                    if (fxsyn.at(key).isNil,{
                        makeSynth=true;
                    },{
                        if (fxsyn.at(key).isRunning,{
                            if (fxlfo.at(key).notNil,{
                                freeSynth=true;
                                makeSynth=true;
                                fxlfo.removeAt(key);
                            },{
                                //["setting",key].postln;
                                fxsyn.at(key).set(\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]);
                            });
                        },{
                            freeSynth=true;
                            makeSynth=true;
                        });
                    });
                },{
                    makeSynth=true;
                    freeSynth=fxsyn.at(key).notNil;
                    fxlfo.put(key,1);
                });
                if (freeSynth==true,{
                    ["freeing",key].postln; 
					fxsyn.at(key).free;
                });
                if (makeSynth==true,{
                    fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));NodeWatcher.register(fxsyn.at(key));
                });
            });
        });
        [\latency].do({ arg key;
            this.addCommand("threeohthree_"++key, "f", { arg msg;
                latencyThreeOhThree=msg[1].asFloat;
                synThreeOhThree.set(key,msg[1]);
            });
        });

        this.addCommand("threeohthree_trig", "ffff", { arg msg;
            lastSlide=msg[3];
            synThreeOhThree.set(\t_trig,1,\note,msg[1],\duration,msg[2],\slide,msg[3]);
            if (msg[4].asFloat>0.0,{
                // trigger accent
                fxbus.at("threeohthree_decay").get({ arg val;
                    Synth("defThreeOhThreeAccent",[\out,busAccent,\decay,val*valDecayFactor]);
                });
            });
        });


        this.addCommand("threeohthree_decayfactor", "sfff", { arg msg;
            valDecayFactor=msg[3].asFloat;
        });
        // </303>


        // <Tape>
        [\auxin,\tape_wet,\tape_bias,\tape_sat,\tape_drive,\dist_wet,\dist_drive,\dist_bias,\dist_low,\dist_high,\dist_shelf,\lpf,\lpfqr,\hpf,\hpfqr].do({ arg fx;
            var domain="tape";
            var key=domain++"_"++fx;
            fxbus.put(key,Bus.control(context.server,1));
            fxbus.at(key).value=1.0;
            // MAKE SURE TO CHANGE THE SYNTH
            synTape.set(fx++"Bus",fxbus.at(key).index);
            this.addCommand(key, "sfff", { arg msg;
                var makeSynth=false;
                var freeSynth=false;
                //[msg[1],key,fxsyn.at(key),fxsyn.at(key).isNil].postln;
                if (msg[1].asString=="lag",{
                    if (fxsyn.at(key).isNil,{
                        makeSynth=true;
                    },{
                        if (fxsyn.at(key).isRunning,{
                            if (fxlfo.at(key).notNil,{
                                freeSynth=true;
                                makeSynth=true;
                                fxlfo.removeAt(key);
                            },{
                                //["setting",key].postln;
                                fxsyn.at(key).set(\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]);
                            });
                        },{
                            freeSynth=true;
                            makeSynth=true;
                        });
                    });
                },{
                    makeSynth=true;
                    freeSynth=fxsyn.at(key).notNil;
                    fxlfo.put(key,1);
                });
                if (freeSynth==true,{
                    //["freeing",key].postln; 
					fxsyn.at(key).free;
                });
                if (makeSynth==true,{
                    fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));NodeWatcher.register(fxsyn.at(key));
                });
            });
        });
        // </Tape>

        // <Plaits>
        [\amp,\attack,\decayEnv,\engine,\pitch,\harm,\morph,\timbre,\decay,\pan].do({ arg fx;
            var domain="plaits";
            var key=domain++"_"++fx;
            fxbus.put(key,Bus.control(context.server,1));
            fxbus.at(key).value=1.0;
            this.addCommand(key, "sfff", { arg msg;
                var makeSynth=false;
                var freeSynth=false;
                //[msg[1],key,fxsyn.at(key),fxsyn.at(key).isNil].postln;
                if (msg[1].asString=="lag",{
                    if (fxsyn.at(key).isNil,{
                        makeSynth=true;
                    },{
                        if (fxsyn.at(key).isRunning,{
                            if (fxlfo.at(key).notNil,{
                                freeSynth=true;
                                makeSynth=true;
                                fxlfo.removeAt(key);
                            },{
                                //["setting",key].postln;
                                fxsyn.at(key).set(\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]);
                            });
                        },{
                            freeSynth=true;
                            makeSynth=true;
                        });
                    });
                },{
                    makeSynth=true;
                    freeSynth=fxsyn.at(key).notNil;
                    fxlfo.put(key,1);
                });
                if (freeSynth==true,{
                    //["freeing",key].postln; 
					fxsyn.at(key).free;
                });
                if (makeSynth==true,{
                    fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));NodeWatcher.register(fxsyn.at(key));
                });
            });
        });

        this.addCommand("plaits","", { arg msg;
            Synth.before(synTape,"defPlaits",[
                \out,busTape,
                \latency,latencyThreeOhThree,
                \ampBus,fxbus.at("plaits_amp"),
                \attackBus,fxbus.at("plaits_attack"),
                \decayEnvBus,fxbus.at("plaits_decayEnv"),
                \engineBus,fxbus.at("plaits_engine"),
                \pitchBus,fxbus.at("plaits_pitch"),
                \harmBus,fxbus.at("plaits_harm"),
                \morphBus,fxbus.at("plaits_morph"),
                \timbreBus,fxbus.at("plaits_timbre"),
                \decayBus,fxbus.at("plaits_decay"),
                \panBus,fxbus.at("plaits_pan"),
            ]);
        });

        // </Plaits>




        // <Amen>

        [\amp,\rate,\bitcrush,\bitcrush_bits,\bitcrush_rate,\scratch,\scratchrate,\strobe,\stroberate,\vinyl,\timestretch,\timestretch_slow,\timestretch_beats,\pan,\lpf,\hpf].do({ arg fx;
            var domain="amen";
            var key=domain++"_"++fx;
            fxbus.put(key,Bus.control(context.server,1));
            fxbus.at(key).value=1.0;
            // MAKE SURE TO CHANGE THE SYNTH
            synAmen.do({ arg item,i;
                item.set(fx++"Bus",fxbus.at(key).index);
            });  
            this.addCommand(key, "sfff", { arg msg;
                var makeSynth=false;
                var freeSynth=false;
                //[msg[1],key,fxsyn.at(key),fxsyn.at(key).isNil].postln;
                if (msg[1].asString=="lag",{
                    if (fxsyn.at(key).isNil,{
                        makeSynth=true;
                    },{
                        if (fxsyn.at(key).isRunning,{
                            if (fxlfo.at(key).notNil,{
                                freeSynth=true;
                                makeSynth=true;
                                fxlfo.removeAt(key);
                            },{
                                //["setting",key].postln;
                                fxsyn.at(key).set(\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]);
                            });
                        },{
                            freeSynth=true;
                            makeSynth=true;
                        });
                    });
                },{
                    makeSynth=true;
                    freeSynth=fxsyn.at(key).notNil;
                    fxlfo.put(key,1);
                });
                if (freeSynth==true,{
                    ["freeing",key].postln; 
					fxsyn.at(key).free;
                });
                if (makeSynth==true,{
                    fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));NodeWatcher.register(fxsyn.at(key));
                })
            });
        });


        this.addCommand("amen_load","sf", { arg msg;
            // lua is sending 1-index
            sampleBuffAmen.free;
            postln("loading "++msg[1]);
            Buffer.read(context.server,msg[1],action:{
                arg buf;
                postln("loaded "++msg[1]++"into buf "++buf.bufnum);
                sampleBuffAmen=buf;
                synAmen.do({ arg item,i;
                    item.set(\bufnum,sampleBuffAmen,\bpm_sample,msg[2],
                        \amp_crossfade,playerSwap==i,
                        \samplePos,0,
                        \sampleStart,0,
                        \sampleEnd,1.0
                    );
                });
            });
        });

        this.addCommand("amen_jump","fff", { arg msg;
            // lua is sending 1-index
            playerSwap=1-playerSwap;
            synAmen.do({ arg item,i;
                item.set(
                    \t_trig,playerSwap==i,
                    \amp_crossfade,playerSwap==i,
                    \samplePos,msg[1],
                    \sampleStart,msg[2],
                    \sampleEnd,msg[3],
                )
            });
        });

        [\bpm_target,\latency,\bpm_sample].do({ arg key;
            this.addCommand("amen_"++key, "f", { arg msg;
                synAmen.do({ arg item,i;
                    item.set(key,msg[1]);
                });  
            });
        });

        // </Amen>


	}

    free {
        // <Amen>
        synAmen[0].free;
        synAmen[1].free;
        fxbus.keysValuesDo{ |key,value| value.free };
        fxsyn.keysValuesDo{ |key,value| value.free };
        sampleBuffAmen.free;
        playerVinyl.free;
        sampleVinyl.free;
        // </Amen>
        synThreeOhThree.free;
        busAccent.free;
        synTape.free;
        busTape.free;
        synReverb.free;
        busReverb.free;
        mxsamples.free;
    }

}
