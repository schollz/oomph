Engine_Emu303 : CroneEngine {
// All norns engines follow the 'Engine_MySynthName' convention above

    // <Emu303>
	var params;
    var busAccent;
    var busTape;
    var synth;
    var synTape;
    // </Emu303>

    // <Amen>
    var sampleBuffAmen;
    var playerAmen;
    var playerVinyl; 
    var sampleVinyl;
    var playerSwap;
    var amenparams;
    var fxbus;
    var fxsyn;
    // </Amen>

	alloc { 
        
        // <Amen>
        fxbus=Dictionary.new();
        fxsyn=Dictionary.new();
        sampleBuffAmen = Buffer.new(context.server);
        sampleVinyl = Buffer.read(context.server, "/home/we/dust/code/acid-pattern/lib/vinyl2.wav"); 
        playerSwap = 0;

        SynthDef("vinylSound",{
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

        SynthDef("playerAmen",{ 
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

        SynthDef("TapeFX",{
			arg in, auxin=0.0,tape_wet=0.9,tape_bias=0.9,saturation=0.9,drive=0.5,
			tape_oversample=2,mode=0,
			dist_wet=0.5,drivegain=0.5,dist_bias=0,lowgain=0.1,highgain=0.1,
			shelvingfreq=600,dist_oversample=2,
			wowflu=1.0,
			wobble_rpm=33, wobble_amp=0.05, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
			hpf=60,hpfqr=0.6,
			lpf=18000,lpfqr=0.6,
			buf;
			var snd=In.ar(in,2);
            snd=snd+(auxin*SoundIn.ar([0,1]));
			snd=SelectX.ar(Lag.kr(tape_wet,1),[snd,AnalogTape.ar(snd,tape_bias,saturation,drive,tape_oversample,mode)]);
			snd=SelectX.ar(Lag.kr(dist_wet/10,1),[snd,AnalogVintageDistortion.ar(snd,drivegain,dist_bias,lowgain,highgain,shelvingfreq,dist_oversample)]);			
			snd=RHPF.ar(snd,hpf,hpfqr);
			snd=RLPF.ar(snd,lpf,lpfqr);
			Out.ar(0,snd);
		}).add;
		
        SynthDef("Emu303Accent",{
            arg out,decay;
            Out.kr(out,EnvGen.ar( Env.new([10e-9, 1, 10e-9], [0.01, decay],  'exp'),doneAction:2));
        }).add;

        SynthDef("Emu303", {
            arg out, busAccent, 
            t_trig=1, note=33, pw=0.5, detune=0.05,wave=0.0, amp=1.0, sub=0.0,
            cutoff=200, gain=1, portamento=0.5, slide=0,
            duration=0.0, sustain=0.0, decay=10,
            resAdjust=0.303, resAccent=0.1,
            envAdjust=500,   envAccent=0.1, latency=0;
            var env,waves,filterEnv,filter,snd,res,accentVal,noteVal;
            noteVal=Lag.kr(note,portamento*slide);
            accentVal=In.kr(busAccent);
            res = resAdjust+(resAccent*accentVal);
            env = EnvGen.ar(Env.new([10e-3,1,1,10e-9],[0.03,sustain*duration,decay],'exp'),t_trig)+(envAccent*accentVal);
            waves = [Saw.ar([noteVal-detune,noteVal+detune].midicps, mul: env), Pulse.ar([note-detune,note+detune].midicps, 0.5, mul: env)];
            filterEnv =  EnvGen.ar( Env.new([10e-9, 1, 10e-9], [0.01, decay],  'exp'), t_trig);
            filter = RLPFD.ar(SelectX.ar(wave, waves), cutoff +(filterEnv*envAdjust), res,gain);
            snd=(filter*amp).tanh;
            snd=snd+SinOsc.ar([noteVal-12-detune,noteVal-12+detune].midicps,mul:sub*env/10.0);
            Out.ar(out, DelayN.ar(snd,delaytime:latency));
        }).add;


        SynthDef("line",{
            arg out, msg1=0,msg2=1.0,msg3=1.0;
            Out.kr(out,Line.kr(start:msg1,end:msg2,dur:msg3,doneAction:2));
        }).add;

        SynthDef("dc",{
            arg out, msg1=0,msg2=1.0,msg3=1.0;
            FreeSelf.kr(TDelay.kr(Trig.kr(1)));
            Out.kr(out,DC.kr(msg1));
        }).add;

        SynthDef("xline",{
            arg out, msg1=0,msg2=1.0,msg3=1.0;
            Out.kr(out,XLine.kr(start:msg1+0.00001,end:msg2,dur:msg3,doneAction:2));
        }).add;

        SynthDef("sine",{
            arg out, msg1=2,msg2=0.0,msg3=1.0;
            Out.kr(out,SinOsc.kr(freq:msg3).range(msg1,msg2));
        }).add;

        context.server.sync;
        busTape=Bus.audio(context.server,2);
        busAccent=Bus.control(context.server,1);
        context.server.sync;
        synth=Synth("Emu303",[\busAccent,busAccent,\out,busTape]);
        playerVinyl = Synth("vinylSound",[\bufnum,sampleVinyl,\amp,0],target:context.xg);
        playerAmen = Array.fill(2,{arg i;
            Synth.head(context.server,"playerAmen",[\out,busTape])
        });

        synTape=Synth.tail(context.server,"TapeFX",[\in,busTape]);

        context.server.sync;

		params = Dictionary.newFrom([
			\pw, 0.5,
			\detune, 0.05,
			\wave, 0,
			\amp, 0.0,
			\sub, 1.0,
			\cutoff, 200.0,
            \gain, 1.0,
            \duration, 0.0,
            \sustain, 0.0,
            \decay, 1.0,
            \resAdjust, 0.303,
            \resAccent, 0.1,
            \envAdjust, 500,
            \envAccent, 0.1,
            \portamento, 0.5,
            \latency,0.0,
		]);

		params.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				params[key] = msg[1];
                synth.set(key,msg[1]);
			});
		});

		this.addCommand("trig", "ffff", { arg msg;
			synth.set(\t_trig,1,\note,msg[1],\duration,msg[2],\slide,msg[3]);
            if (msg[4].asFloat>0.0,{
                // trigger accent
                Synth("Emu303Accent",[\out,busAccent,\decay,params[\decay]]);
            });
		});

		[\auxin,\hpf,\hpfqr,\lpf,\lpfqr,\wowflu,\wobble_rpm,\wobble_amp,\flutter_amp,\flutter_fixedfreq,\flutter_variationfreq,\amp,\tape_wet,\tape_bias,\saturation,\drive,\tape_oversample,\mode,\dist_wet,\drivegain,\dist_bias,\lowgain,\highgain,\shelvingfreq,\dist_oversample].do({ arg key;
			this.addCommand(key, "f", { arg msg;
				synTape.set(key,msg[1]);
			});
		});


        // <Amen>

        amenparams = Dictionary.newFrom([
            \bpm_target, 0,
            \bpm_sample, 0,
            \lpf,18000,
        ]);


        this.addCommand("amen_release","", { arg msg;
            playerAmen.do({ arg item,i;
                item.set(\amp,0);
            });
            sampleBuffAmen.free;
        });

        this.addCommand("amen_load","sf", { arg msg;
            // lua is sending 1-index
            sampleBuffAmen.free;
            postln("loading "++msg[1]);
            Buffer.read(context.server,msg[1],action:{
                arg buf;
                postln("loaded "++msg[1]++"into buf "++buf.bufnum);
                sampleBuffAmen=buf;
                amenparams[\bpm_sample] = msg[2];
                playerAmen.do({ arg item,i;
                    item.set(\bufnum,buf,\bpm_sample,msg[2]);
                });
            });
        });

        [\fxbus_amp,\fxbus_lpf].do({ arg key;
            fxbus.put(key,Bus.control(context.server,1));
            fxbus.at(key).value=1.0;
            playerAmen.do({ arg item,i;
                item.set(key,fxbus.at(key).index);
            });
            this.addCommand("amen_"++key, "sfff", { arg msg;
                if (fxsyn.at(key).notNil,{
                    fxsyn.at(key).free;
                });
                fxsyn.put(key,Synth.new(msg[1].asString,[\out,fxbus.at(key),\msg1,msg[2],\msg2,msg[3],\msg3,msg[4]]));
            });
        });


        [\stroberate,\scratchrate,\bpm_target,\latency,\amp,\rate,\rateslew,\scratch,\lpf,\lpflag,\hpf,\hpflag,\strobe,\vinyl,\bitcrush,\bitcrush_bits,\bitcrush_rate,\timestretch,\timestretch_slow,\timestretch_beats].do({ arg key;
            this.addCommand("amen_"++key, "f", { arg msg;
                amenparams[key] = msg[1];
                playerAmen.do({ arg item,i;
                    item.set(key,msg[1]);
                });  
            });
        });


        this.addCommand("amen_jump","fff", { arg msg;
            // lua is sending 1-index
            playerSwap=1-playerSwap;
            playerAmen.do({ arg item,i;
                item.set(
                    \t_trig,playerSwap==i,
                    \amp_crossfade,playerSwap==i,
                    \samplePos,msg[1],
                    \sampleStart,msg[2],
                    \sampleEnd,msg[3],
                )
            });
        });


        // </Amen>


	}

    free {
        // <Amen>
        playerAmen.do({ arg item,i; item.free; i.postln; });
        fxbus.keysValuesDo{ |key,value| value.free };
        fxsyn.keysValuesDo{ |key,value| value.free };
        playerAmen.free;
        sampleBuffAmen.free;
        playerVinyl.free;
        sampleVinyl.free;
        // </Amen>

        busAccent.free;
        synth.free;
        synTape.free;
        busTape.free;
    }

}