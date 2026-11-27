// Original procedural wood and bell recordings. No external audio sources.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  const rate = 22050;
  final lengths = {
    'key': .085,
    'wrong': .18,
    'win': 1.05,
    'reward': .60,
    'buy': .45,
    'stage': .70,
  };
  for (final entry in lengths.entries) {
    final samples = Float64List((rate * entry.value).round());
    var random = 74123;
    void note(
      double start,
      double frequency,
      double duration,
      double gain, {
      bool bell = false,
      bool pop = false,
      bool wood = false,
      bool tap = false,
    }) {
      final first = (start * rate).round();
      final count = (duration * rate).round();
      var filteredNoise = 0.0;
      for (var i = 0; i < count && first + i < samples.length; i++) {
        final t = i / rate;
        random = (1664525 * random + 1013904223) & 0xffffffff;
        filteredNoise =
            filteredNoise * .77 + ((random / 0xffffffff) * 2 - 1) * .23;
        final phase =
            2 *
            math.pi *
            frequency *
            (t + (pop ? .001 * (1 - math.exp(-t * 60)) : 0));
        final voice = tap
            ? math.sin(phase) * math.exp(-t * 48) +
                  .22 * math.sin(phase * 3) * math.exp(-t * 100) +
                  filteredNoise * .08 * math.exp(-t * 160)
            : wood
            ? math.sin(phase) * math.exp(-t * 9) +
                  .16 * math.sin(phase * 4) * math.exp(-t * 25) +
                  .035 * math.sin(phase * 10) * math.exp(-t * 50)
            : bell
            ? math.sin(phase) * math.exp(-t * 7) +
                  .25 * math.sin(phase * 2.76) * math.exp(-t * 13) +
                  .08 * math.sin(phase * 5.4) * math.exp(-t * 24)
            : math.sin(phase) * math.exp(-t * (pop ? 22 : 38)) +
                  .32 * math.sin(phase * 2.71) * math.exp(-t * 65) +
                  .12 * math.sin(phase * 4.89) * math.exp(-t * 105) +
                  filteredNoise * .3 * math.exp(-t * 120);
        final attack = math.min(1.0, t / (tap ? .006 : (wood ? .008 : .003)));
        final release = math.min(1.0, (count - i) / (rate * .018));
        samples[first + i] += voice * attack * release * gain;
      }
    }

    switch (entry.key) {
      case 'key':
        note(0, 760, .085, .38, tap: true);
      case 'wrong':
        note(0, 245, .18, .28, pop: true);
      case 'win':
        // A low, rounded wooden phrase, with a pause before the final note.
        // Avoid the bright, evenly spaced ringing of an alert melody.
        note(0, 392.00, .42, .32, wood: true);
        note(.14, 523.25, .44, .29, wood: true);
        note(.40, 659.25, .65, .27, wood: true);
      case 'reward':
        note(0, 1046.50, .45, .22, bell: true);
        note(.16, 1567.98, .44, .13, bell: true);
      case 'buy':
        note(0, 659.25, .14, .26);
        note(.12, 1046.50, .33, .20, bell: true);
      case 'stage':
        // A soft, rising wooden chime distinct from the general button sound.
        note(0, 523.25, .25, .18, wood: true);
        note(.13, 659.25, .27, .16, wood: true);
        note(.30, 783.99, .30, .14, wood: true);
        note(.48, 987.77, .20, .12, wood: true);
    }
    final data = ByteData(44 + samples.length * 2);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        data.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + samples.length * 2, Endian.little);
    ascii(8, 'WAVEfmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, samples.length * 2, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      data.setInt16(
        44 + i * 2,
        (samples[i].clamp(-.48, .48) * 32767).round(),
        Endian.little,
      );
    }
    final file = File('assets/sounds/${entry.key}.wav');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data.buffer.asUint8List());
  }
}
