Engine_Emu303 : CroneEngine {
// All norns engines follow the 'Engine_MySynthName' convention above
    // all
    var fxbus;
    var fxsyn;

    // <Emu303>
	var synThreeOhThree;
    var busAccent;
    var busTape;
    // </Emu303>

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

	alloc { 
        
        // <Amen>
        fxbus=Dictionary.new();
        fxsyn=Dictionary.new();
        sampleBuffAmen = Buffer.new(context.server);
        sampleVinyl = Buffer.read(context.server, "/home/we/dust/code/acid-pattern/lib/vinyl2.wav"); 
        playerSwap = 0;

        SynthDef("defVinyl",{
            | bufnum = 0,amp=0,hpf=800,lpf=4000,rate=1,rateslew=4,scratch=0,bpm_target=120,t_trig=1|
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
            Out.ar(0,snd*amp);
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
            var snd,pos,timestretchPos,timestretchWindow;
            var amp=In.kr(ampBus);//bus2
            var rate=In.kr(rateBus);//bus2
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

            rate = rate * bpm_target / bpm_sample;
            // scratch effect
            rate = SelectX.kr(scratch,[rate,LFTri.kr(bpm_target/60*scratchrate)]);
            pos = Phasor.ar(
                trig:t_trig,
                rate:BufRateScale.kr(bufnum)*rate,
                start:((sampleStart*(rate>0))+(sampleEnd*(rate<0)))*BufFrames.kr(bufnum),
                end:((sampleEnd*(rate>0))+(sampleStart*(rate<0)))*BufFrames.kr(bufnum),
                resetPos:samplePos*BufFrames.kr(bufnum)
            );
            timestretchPos = Phasor.ar(
                trig:t_trigtime,
                rate:BufRateScale.kr(bufnum)*rate/timestretch_slow,
                start:((sampleStart*(rate>0))+(sampleEnd*(rate<0)))*BufFrames.kr(bufnum),
                end:((sampleEnd*(rate>0))+(sampleStart*(rate<0)))*BufFrames.kr(bufnum),
                resetPos:pos
            );
            timestretchWindow = Phasor.ar(
                trig:t_trig,
                rate:BufRateScale.kr(bufnum)*rate,
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
            bitcrush = VarLag.kr(bitcrush,1,warp:\cubed);
            snd = (snd*(1-bitcrush))+(bitcrush*Decimator.ar(snd,VarLag.kr(bitcrush_rate,1,warp:\cubed),VarLag.kr(bitcrush_bits,1,warp:\cubed)));

            // vinyl wow + compressor
            snd=(vinyl<1*snd)+(vinyl>0* Limiter.ar(Compander.ar(snd,snd,0.5,1.0,0.1,0.1,1,2),dur:0.0008));
            snd =(vinyl<1*snd)+(vinyl>0* DelayC.ar(snd,0.01,VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0,0.01)));                

            // manual panning
            snd = Balance2.ar(snd[0],snd[1],
                pan+SinOsc.kr(60/bpm_target*stroberate,mul:strobe*0.5),
                level:amp*Lag.kr(amp_crossfade,0.2)
            );

            Out.ar(out,DelayN.ar(snd,delaytime:latency));
        }).add; 
        // </Amen>




        SynthDef("defThreeOhThree", {
            arg out, busAccent, 
            t_trig=1, note=33, latency=0.0,pwBus, detuneBus, waveBus, ampBus, subBus,
            cutoffBus, gainBus, portamentoBus, slideBus,
            durationBus, sustainBus, decayBus,
            res_adjustBus, res_accentBus,
            env_adjustBus,   env_accentBus, latencyBus;
            var env,waves,filterEnv,filter,snd,res,accentVal,noteVal;
            var pw=In.kr(pwBus);
            var amp=In.kr(ampBus);
            var cutoff=In.kr(cutoffBus);
            var detune=In.kr(detuneBus);
            var wave=In.kr(waveBus);
            var sub=In.kr(subBus);
            var gain=In.kr(gainBus);
            var portamento=In.kr(portamentoBus);
            var slide=In.kr(slideBus);
            var duration=In.kr(durationBus);
            var sustain=In.kr(sustainBus);
            var decay=In.kr(decayBus);
            var res_adjust=In.kr(res_adjustBus);
            var res_accent=In.kr(res_accentBus);
            var env_adjust=In.kr(env_adjustBus);
            var env_accent=In.kr(env_accentBus);
            noteVal=Lag.kr(note,portamento*slide);
            accentVal=In.kr(busAccent);
            res = res_adjust+(res_accent*accentVal);
            env = EnvGen.ar(Env.new([10e-3,1,1,10e-9],[0.03,sustain*duration,decay],'exp'),t_trig)+(env_accent*accentVal);
            waves = [Saw.ar([noteVal-detune,noteVal+detune].midicps, mul: env), Pulse.ar([note-detune,note+detune].midicps, 0.5, mul: env)];
            filterEnv =  EnvGen.ar( Env.new([10e-9, 1, 10e-9], [0.01, decay],  'exp'), t_trig);
            filter = RLPFD.ar(SelectX.ar(wave, waves), cutoff +(filterEnv*env_adjust), res,gain);
            snd=(filter*amp).tanh;
            snd=snd+SinOsc.ar([noteVal-12-detune,noteVal-12+detune].midicps,mul:sub*env/10.0);
            Out.ar(out, DelayN.ar(snd,delaytime:latency));
        }).add;
        
        SynthDef("defThreeOhThreeAccent",{
            arg out,decay;
            Out.kr(out,EnvGen.ar( Env.new([10e-9, 1, 10e-9], [0.01, decay],  'exp'),doneAction:2));
        }).add;

        SynthDef("defTape",{
            arg in, auxinBus,tape_wetBus,tape_biasBus,tape_satBus,tape_driveBus,
            tape_oversample=1,mode=0,
            dist_wetBus,dist_driveBus,dist_biasBus,dist_lowBus,dist_highBus,
            dist_shelfBus,dist_oversample=2,
            wowflu=1.0,
            wobble_rpm=33, wobble_amp=0.05, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
            hpf=60,hpfqr=0.6,
            lpf=18000,lpfqr=0.6,
            buf;
            var snd=In.ar(in,2);
            var auxin=In.kr(auxinBus);//bus
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
            snd=snd+(auxin*SoundIn.ar([0,1]));
            snd=SelectX.ar(Lag.kr(tape_wet,1),[snd,AnalogTape.ar(snd,tape_bias,tape_sat,tape_drive,tape_oversample,mode)]);
            snd=SelectX.ar(Lag.kr(dist_wet,1),[snd,AnalogVintageDistortion.ar(snd,dist_drive,dist_bias,dist_low,dist_high,dist_shelf,dist_oversample)]);          
            snd=RHPF.ar(snd,hpf,hpfqr);
            snd=RLPF.ar(snd,lpf,lpfqr);
            Out.ar(0,snd);
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
        busAccent=Bus.control(context.server,1);
        context.server.sync;        
        // define always-on synths
        synThreeOhThree=Synth("defThreeOhThree",[\busAccent,busAccent,\out,busTape]); // TODO: switch back to busTape
        //TODO add back playerVinyl = Synth("defVinyl",[\bufnum,sampleVinyl,\amp,0],target:context.xg);
        synAmen = Array.fill(2,{arg i;
            Synth("defAmen",[\out,busTape])
        });
        synTape=Synth.tail(context.server,"defTape",[\in,busTape]);
        context.server.sync;

        // <303>
        [\amp,\pw,\detune,\wave,\sub,\cutoff,\gain,\duration,\sustain,\decay,\res_adjust,\res_accent,\env_adjust,\env_accent,\portamento].do({ arg fx;
            var domain="threeohthree";
            var key=domain++"_"++fx;
            fxbus.put(key,Bus.control(context.server,1));
            fxbus.at(key).value=1.0;
            synThreeOhThree.set(fx++"Bus",fxbus.at(key).index);
            this.addCommand(key, "sfff", { arg msg;
                if (key=="lag",{
                    if (fxsyn.at(key).isNil,{
                        fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));
                    },{
                        fxsyn.at(key).set(\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]);
                    });
                },{
                    if (fxsyn.at(key).notNil,{
                        fxsyn.at(key).free;
                    });
                    fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));
                })
            });
        });
        [\latency].do({ arg key;
            this.addCommand("threeohthree_"++key, "f", { arg msg;
                synThreeOhThree.set(key,msg[1]);
            });
        });

        this.addCommand("threeohthree_trig", "ffff", { arg msg;
            synThreeOhThree.set(\t_trig,1,\note,msg[1],\duration,msg[2],\slide,msg[3]);
            if (msg[4].asFloat>0.0,{
                // trigger accent
                fxbus.at("threeohthree_decay").get({ arg val;
                    Synth("defThreeOhThreeAccent",[\out,busAccent,\decay,val]);
                });
            });
        });
        // </303>


        // <Tape>
        [\auxin,\tape_wet,\tape_bias,\tape_sat,\tape_drive,\dist_wet,\dist_drive,\dist_bias,\dist_low,\dist_high,\dist_shelf].do({ arg fx;
            var domain="tape";
            var key=domain++"_"++fx;
            fxbus.put(key,Bus.control(context.server,1));
            fxbus.at(key).value=1.0;
            // MAKE SURE TO CHANGE THE SYNTH
            synTape.set(fx++"Bus",fxbus.at(key).index);
            this.addCommand(key, "sfff", { arg msg;
                if (key=="lag",{
                    if (fxsyn.at(key).isNil,{
                        fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));
                    },{
                        fxsyn.at(key).set(\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]);
                    });
                },{
                    if (fxsyn.at(key).notNil,{
                        fxsyn.at(key).free;
                    });
                    fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));
                })
            });
        });
        // </Tape>




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
                if (key=="lag",{
                    if (fxsyn.at(key).isNil,{
                        fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));
                    },{
                        fxsyn.at(key).set(\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]);
                    });
                },{
                    if (fxsyn.at(key).notNil,{
                        fxsyn.at(key).free;
                    });
                    fxsyn.put(key,Synth.new("defMod_"++msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));
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
                    item.set(\bufnum,buf,\bpm_sample,msg[2],
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

        [\bpm_target,\latency].do({ arg key;
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
        synAmen.do({ arg item,i; item.free; i.postln; });
        fxbus.keysValuesDo{ |key,value| value.free };
        fxsyn.keysValuesDo{ |key,value| value.free };
        synAmen.free;
        sampleBuffAmen.free;
        playerVinyl.free;
        sampleVinyl.free;
        // </Amen>
        synThreeOhThree.free;
        busAccent.free;
        synTape.free;
        busTape.free;
    }

}