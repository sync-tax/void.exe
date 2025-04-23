"_- void.exe ~ by TRIBΞHOLZ -_'
_-_-__--_-_--__-_--__-___--_-_--_--_-_-_-__-."
#---------------------------------------------------------
#PRESETS
use_bpm 146
use_debug false
use_real_time

#---------------------------------------------------------
#METRONOME
live_loop :metro do
  sleep 1
end

#---------------------------------------------------------
#SAMPLES
s_path = "C:/Users/rober/Desktop/TRIBΞHOLZ/!SonicPi/Tracks/void.exe/samples"

sAll_path = "C:/Users/rober/Desktop/TRIBΞHOLZ/!SonicPi/samples/!ALL/"


s = {
  kick: "#{s_path}/kick.wav",
  bass: "#{s_path}/bass.wav",
  tz: "#{s_path}/tz.wav",
  snare: "#{s_path}/snare.wav",
  tsch: "#{s_path}/perc.wav", #perc 21, 47!!, 22, 31(DÜSTER!!) hats19
  piep: "#{s_path}/piep.wav",
  atmo_loop:  "#{s_path}/atmo_loop.wav",
  vocal:  "#{s_path}/void2.wav",
}

#---------------------------------------------------------
#PATTERNS
define :pattern do |p|
  return p.ring.tick == "x"
end

kick_pattern = ("xoxoxoxoxoxoxoxo")

#---------------------------------------------------------
#MIDI MIXER
define :scale_midi do |val, min, max|
  return min + (val.to_f / 127) * (max - min)
end

$midi_values ||= Hash.new(0.01)

live_loop :midi_controls do
  key, value = sync "/midi:midi_mix_1:1/control_change"
  
  case key
  when 19
    $midi_values[19] = scale_midi(value, 0, 1.2) # kick_amp + bass_amp
  when 23
    $midi_values[23] = scale_midi(value, 0, 0.8) # tz_amp
  when 27
    $midi_values[27] = scale_midi(value, 0, 0.2) # snare_amp
  when 30
    $midi_values[30] = scale_midi(value, 0.5, 8) # piep_phase
  when 31
    $midi_values[31] = scale_midi(value, 0, 0.6) # piep_amp
  when 49
    $midi_values[49] = scale_midi(value, 0, 0.3) # atmo_amp
  when 53
    $midi_values[53] = scale_midi(value, 0, 0.15) # tsch_amp
  when 57
    $midi_values[57] = scale_midi(value, 0, 1) # vocal_amp
  when 59
    $midi_values[59] = scale_midi(value, 0.1, 6) # synth1_attack
  when 60
    $midi_values[60] = scale_midi(value, 60, 100) # synth1_cutoff
  when 61
    $midi_values[61] = scale_midi(value, 0, 0.5) # synth1_amp
  end
end

#---------------------------------------------------------
#LOOPS

with_fx :distortion, distort: 0.4, mix: 0.3  do
  with_fx :eq, low_shelf: 0.05, low: 0.05 do
    with_fx :mono do
      live_loop :kick do
        if pattern(kick_pattern)
          sample s[:kick],
            amp: $midi_values[19],
            beat_stretch: 1,
            cutoff: 130
        end
        sleep 0.5
      end
    end
  end
end

with_fx :mono do
  live_loop :bass do
    sleep 0.5
    sample s[:bass],
      amp: $midi_values[19] * 1,
      rate: 1 # 0.5 | 1 | ring(0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1).tick
    sleep 0.5
  end
end

with_fx :reverb, mix: 0.3 do
  live_loop :tz, sync: :kick do
    sample s[:tz],
      amp: $midi_values[23] ,
      rate: 2,
      cutoff: 120,
      beat_stretch: 1,
      rpitch: 20,
      release: 0.08,
      attack: 0.01
    sleep 1
  end
end

with_fx :distortion, distort: 0.25 do
  with_fx :reverb, mix: 0.5, room: 0.15 do
    live_loop :snare do
      sample s[:snare],
        amp: $midi_values[27],
        beat_stretch: 0.6,
        cutoff: 120,
        rate: 1
      sleep 2
    end
  end
end


with_fx :ixi_techno, phase: 8, phase_offset: 0, cutoff_min: 100, cutoff_max: 110 do
  live_loop :tsch, sync: :kick do
    sample s[:tsch],
      amp: $midi_values[53],
      beat_stretch: 0.1,
      rpitch: ring(4, 3, -8, -3).tick
    sleep 0.25
  end
end

live_loop :piep, sync: :metro do
  with_fx :reverb, mix: 0.5, room: 0.75 do
    with_fx :slicer, phase: $midi_values[30] do
      sample s[:piep],
        amp: $midi_values[31],
        beat_stretch: 2,
        rpitch: ring(8, 3, -8, -3).tick
      sleep 4
    end
  end
end


with_fx :reverb, mix: 0.5, room: 0.9  do
  with_fx :echo, phase: 1 do
    live_loop :atmo, sync: :metro do
      sample s[:atmo_loop],
        amp: $midi_values[49],
        beat_stretch: 32,
        rate: (ring 0.5, 0.7, 1, -0.7).tick,
        pitch: -12
      sleep 32
    end
  end
end

with_fx :reverb, mix: 0.5, room: 0.75  do
  with_fx :ixi_techno, phase: 8, phase_offset: 0, cutoff_min: 100, cutoff_max: 110 do
    live_loop :vocal, sync: :metro do
      sample s[:vocal],
        amp: $midi_values[57],
        beat_stretch: 52,
        pitch: -3
      sleep 180
    end
  end
end

with_fx :flanger, phase: 4, feedback: 0.4 do
  with_fx :reverb, mix: 0.6, room: 0.1 do
    live_loop :synth1, sync: :metro do
      #stop
      synth_co = range(85, 65, 0.5).mirror
      use_random_seed ring(11111).tick
      4.times do
        with_synth :bass_foundation do
          n1 = (ring :f3, :d3, :e3).choose
          play n1,
            release: 6,
            cutoff: $midi_values[60],
            res: 0.1,
            attack: $midi_values[59],
            amp: $midi_values[61],
            pitch: -10
          sleep 4
        end
      end
    end
  end
end
