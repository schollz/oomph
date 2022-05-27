Engine_Emu303 : CroneEngine {
// All norns engines follow the 'Engine_MySynthName' convention above

	var params;
    var busAccent;
    var busTape;
    var synth;
    var synTape;

	alloc { 
        
        SynthDef("TapeFX",{
			arg in, tape_wet=0.9,tape_bias=0.9,saturation=0.9,drive=0.5,
			tape_oversample=2,mode=0,
			dist_wet=0.5,drivegain=0.5,dist_bias=0,lowgain=0.1,highgain=0.1,
			shelvingfreq=600,dist_oversample=1,
			wowflu=1.0,
			wobble_rpm=33, wobble_amp=0.05, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
			hpf=60,hpfqr=0.6,
			lpf=18000,lpfqr=0.6,
			buf;
			var snd=In.ar(in,2);
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
            envAdjust=500,   envAccent=0.1;
            var env,waves,filterEnv,filter,snd,res,accentVal,noteVal;
            noteVal=Lag.kr(note,portamento*slide);
            accentVal=In.kr(busAccent);
            res = resAdjust+(resAccent*accentVal);
            env = EnvGen.ar(Env.new([10e-3,1,1,10e-9],[0.03,sustain+duration,decay],'exp'),t_trig)+(envAccent*accentVal);
            waves = [Saw.ar([noteVal-detune,noteVal+detune].midicps, mul: env), Pulse.ar([note-detune,note+detune].midicps, 0.5, mul: env)];
            filterEnv =  EnvGen.ar( Env.new([10e-9, 1, 10e-9], [0.01, decay],  'exp'), t_trig);
            filter = RLPFD.ar(SelectX.ar(wave, waves), cutoff +(filterEnv*envAdjust), res,gain);
            snd=(filter*amp).tanh;
            snd=snd+SinOsc.ar([noteVal-12-detune,noteVal-12+detune].midicps,mul:sub*env);
            Out.ar(out, snd);
        }).add;

        context.server.sync;
        busTape=Bus.audio(context.server,2);
        busAccent=Bus.control(context.server,1);
        context.server.sync;
        synth=Synth("Emu303",[\busAccent,busAccent,\out,busTape]);
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

		[\hpf,\hpfqr,\lpf,\lpfqr,\wowflu,\wobble_rpm,\wobble_amp,\flutter_amp,\flutter_fixedfreq,\flutter_variationfreq,\amp,\tape_wet,\tape_bias,\saturation,\drive,\tape_oversample,\mode,\dist_wet,\drivegain,\dist_bias,\lowgain,\highgain,\shelvingfreq,\dist_oversample].do({ arg key;
			this.addCommand(key, "f", { arg msg;
				synTape.set(key,msg[1]);
			});
		});


	}

    free {
        busAccent.free;
        synth.free;
        synTape.free;
        busTape.free;
    }

}