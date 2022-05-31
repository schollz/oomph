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
    var amenSynthDef;
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
            arg out=0, bufnum, amp=0, t_trig=0,t_trigtime=0,t_quiet=0,quiet_time=1,amp_crossfade=0,loop=1,
            sampleStart=0,sampleEnd=1,samplePos=0, latency=0,
            rate=1,rateslew=0,bpm_sample=1,bpm_target=1,
            bitcrush=0,bitcrush_bits=24,bitcrush_rate=44100,
            scratch=0,scratchrate=2,strobe=0,stroberate=16,vinyl=0,
            timestretch=0,timestretch_slow=1,timestretch_beats=1,
            pan=0,lpf=20000,lpflag=0,hpf=10,hpflag=0,
            fxbus_amp=0,fxbus_lpf=0;

            // vars
            var snd,pos,timestretchPos,timestretchWindow,quiet;
            rate = Lag.kr(rate,rateslew);
            rate = rate * bpm_target / bpm_sample;
            // scratch effect
            rate = (scratch<1*rate) + (scratch>0*LFTri.kr(bpm_target/60*scratchrate));

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
                loop:loop,
                interpolation:1
            );
            timestretch=Lag.kr(timestretch,2);
            snd=((1-timestretch)*snd)+(timestretch*BufRd.ar(2,bufnum,
                timestretchWindow,
                loop:loop,
                interpolation:1
            ));

            snd = RLPF.ar(snd,Clip.kr(In.kr(fxbus_lpf),10,20000),0.707);
            snd = HPF.ar(snd,Lag.kr(hpf,hpflag));

            // strobe
            snd = ((strobe<1)*snd)+((strobe>0)*snd*LFPulse.ar(60/bpm_target*stroberate));

            // bitcrush
            bitcrush = VarLag.kr(bitcrush,1,warp:\cubed);
            snd = (snd*(1-bitcrush))+(bitcrush*Decimator.ar(snd,VarLag.kr(bitcrush_rate,1,warp:\cubed),VarLag.kr(bitcrush_bits,1,warp:\cubed)));

            // vinyl wow + compressor
            snd=(vinyl<1*snd)+(vinyl>0* Limiter.ar(Compander.ar(snd,snd,0.5,1.0,0.1,0.1,1,2),dur:0.0008));
            snd =(vinyl<1*snd)+(vinyl>0* DelayC.ar(snd,0.01,VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0,0.01)));                
            
            quiet=1-EnvGen.ar(Env.new([0,1,1,0],[0.025,quiet_time-0.05,0.025]),t_quiet);

            // manual panning
            snd = Balance2.ar(snd[0],snd[1],
                pan+SinOsc.kr(60/bpm_target*16,mul:strobe*0.5),
                level:Lag.kr(amp,0.2)*Lag.kr(amp_crossfade,0.2)*quiet*In.kr(fxbus_amp)
            );

            Out.ar(out,DelayN.ar(snd,delaytime:latency));
        }).add; 
        // </Amen>


        SynthDef("defThreeOhThree", {
            arg out, busAccent, 
            t_trig=1, note=33, pwBus, detuneBus, waveBus, ampBus, subBus,
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
            var latency=In.kr(latencyBus);
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
            tape_oversample=2,mode=0,
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
            snd=SelectX.ar(Lag.kr(dist_wet/10,1),[snd,AnalogVintageDistortion.ar(snd,dist_drive,dist_bias,dist_low,dist_high,dist_shelf,dist_oversample)]);          
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
        synThreeOhThree=Synth("defThreeOhThree",[\busAccent,busAccent,\out,0]); // TODO: switch back to busTape
        playerVinyl = Synth("defVinyl",[\bufnum,sampleVinyl,\amp,0],target:context.xg);
        amenSynthDef = Array.fill(2,{arg i;
            Synth.head(context.server,"defAmen",[\out,busTape])
        });
        synTape=Synth.tail(context.server,"defTape",[\in,busTape]);
        context.server.sync;

        // <303>
        [\amp,\pw,\detune,\wave,\sub,\cutoff,\gain,\duration,\sustain,\decay,\res_adjust,\res_accent,\env_adjust,\env_accent,\portamento,\latency].do({ arg fx;
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
        // </Tape>




        // // <Amen>

        // amenparams = Dictionary.newFrom([
        //     \bpm_target, 0,
        //     \bpm_sample, 0,
        //     \lpf,18000,
        // ]);


        // this.addCommand("amen_release","", { arg msg;
        //     amenSynthDef.do({ arg item,i;
        //         item.set(\amp,0);
        //     });
        //     sampleBuffAmen.free;
        // });

        // this.addCommand("amen_load","sf", { arg msg;
        //     // lua is sending 1-index
        //     sampleBuffAmen.free;
        //     postln("loading "++msg[1]);
        //     Buffer.read(context.server,msg[1],action:{
        //         arg buf;
        //         postln("loaded "++msg[1]++"into buf "++buf.bufnum);
        //         sampleBuffAmen=buf;
        //         amenparams[\bpm_sample] = msg[2];
        //         amenSynthDef.do({ arg item,i;
        //             item.set(\bufnum,buf,\bpm_sample,msg[2]);
        //         });
        //     });
        // });

        // [\fxbus_amp,\fxbus_lpf].do({ arg key;
        //     fxbus.put(key,Bus.control(context.server,1));
        //     fxbus.at(key).value=1.0;
        //     amenSynthDef.do({ arg item,i;
        //         item.set(key,fxbus.at(key).index);
        //     });
        //     this.addCommand("amen_"++key, "sfff", { arg msg;
        //         if (fxsyn.at(key).notNil,{
        //             fxsyn.at(key).free;
        //         });
        //         fxsyn.put(key,Synth.new(msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));
        //     });
        // });


        // [\stroberate,\scratchrate,\bpm_target,\latency,\amp,\rate,\rateslew,\scratch,\lpf,\lpflag,\hpf,\hpflag,\strobe,\vinyl,\bitcrush,\bitcrush_bits,\bitcrush_rate,\timestretch,\timestretch_slow,\timestretch_beats].do({ arg key;
        //     this.addCommand("amen_"++key, "f", { arg msg;
        //         amenparams[key] = msg[1];
        //         amenSynthDef.do({ arg item,i;
        //             item.set(key,msg[1]);
        //         });  
        //     });
        // });


        // this.addCommand("amen_jump","fff", { arg msg;
        //     // lua is sending 1-index
        //     playerSwap=1-playerSwap;
        //     amenSynthDef.do({ arg item,i;
        //         item.set(
        //             \t_trig,playerSwap==i,
        //             \amp_crossfade,playerSwap==i,
        //             \samplePos,msg[1],
        //             \sampleStart,msg[2],
        //             \sampleEnd,msg[3],
        //         )
        //     });
        // });


        // </Amen>


	}

    free {
        // <Amen>
        amenSynthDef.do({ arg item,i; item.free; i.postln; });
        fxbus.keysValuesDo{ |key,value| value.free };
        fxsyn.keysValuesDo{ |key,value| value.free };
        amenSynthDef.free;
        sampleBuffAmen.free;
        playerVinyl.free;
        sampleVinyl.free;
        // </Amen>

        busAccent.free;
        synTape.free;
        busTape.free;
    }

}