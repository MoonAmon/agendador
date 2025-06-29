import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TestAudioScreen extends StatefulWidget {
  const TestAudioScreen({super.key});

  @override
  State<TestAudioScreen> createState() => _TestAudioScreenState();
}

class _TestAudioScreenState extends State<TestAudioScreen> {
  final AudioPlayer _player = AudioPlayer();

  final List<String> _audios = [
    'audio/default_alarm.mp3',
    'audio/birds_singing.mp3',
    'audio/gentle_bell.mp3',
    'audio/nature_sounds.mp3',
    'audio/piano_melody.mp3',
  ];

  final List<String> _nomes = [
    'Alarme Padrão',
    'Canto dos Pássaros',
    'Sino Suave',
    'Sons da Natureza',
    'Melodia de Piano',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste de Áudios')),
      body: ListView.builder(
        itemCount: _audios.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_nomes[index]),
            subtitle: Text(_audios[index]),
            trailing: ElevatedButton(
              onPressed: () => _testarAudio(_audios[index]),
              child: const Text('Testar'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _testarAudio(String audioPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(audioPath));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tocando: $audioPath'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Parar após 3 segundos
      Future.delayed(const Duration(seconds: 3), () async {
        await _player.stop();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao tocar $audioPath: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
