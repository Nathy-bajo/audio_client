import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:sound_stream/sound_stream.dart';
import 'package:web_socket_channel/io.dart';
import 'package:json_annotation/json_annotation.dart';
part 'sound_packet.g.dart';

const String url = 'ws://192.168.100.103:8000/ws';

enum PacketType {
  Audio,
  Video,
}

class Uint8ListJsonConverter extends JsonConverter<Uint8List, List<dynamic>> {
  const Uint8ListJsonConverter();

  @override
  Uint8List fromJson(List<dynamic> json) =>
      Uint8List.fromList(json.cast<int>());

  @override
  List<dynamic> toJson(Uint8List object) => object;
}

@JsonSerializable()
class SoundPacket {
  @Uint8ListJsonConverter()
  Uint8List data;

  SoundPacket({
    required this.data,
  });

  factory SoundPacket.fromJson(Map<String, dynamic> json) =>
      _$SoundPacketFromJson(json);

  Map<String, dynamic> toJson() => _$SoundPacketToJson(this);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RecorderStream _recorder = RecorderStream();
  final PlayerStream _player = PlayerStream();

  bool _isRecording = false;
  bool _isPlaying = false;

  late StreamSubscription _playerStatus;
  late StreamSubscription _recorderStatus;
  late StreamSubscription _audioStream;

  final channel = IOWebSocketChannel.connect(Uri.parse(url));

  @override
  void initState() {
    super.initState();
    initPlugin();
  }

  @override
  void dispose() {
    _recorderStatus.cancel();
    _playerStatus.cancel();
    _audioStream.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlugin() async {
    channel.stream.listen((event) async {
      Map<String, dynamic> audioPacket = jsonDecode(event);
      final data = Uint8List.fromList(
        base64Decode(
          (audioPacket["data"]),
        ),
      );
      if (_isPlaying) _player.writeChunk(data);
      print('Data: $data');
    });

    _audioStream = _recorder.audioStream.listen((data) {
      final test = jsonEncode(SoundPacket(data: data));
      channel.sink.add(test);

      print('Audio: $data');


    });

    _recorderStatus = _recorder.status.listen((status) {
      if (mounted) {
        setState(() {
          _isRecording = status == SoundStreamStatus.Playing;
        });
      }
      print('recorder status: $status');
    });

    _playerStatus = _player.status.listen((status) {
      if (mounted) {
        setState(() {
          _isPlaying = status == SoundStreamStatus.Playing;
        });
      }
      print('player status: $status');
    });

    await Future.wait([
      _recorder.initialize(),
      _player.initialize(),
    ]);
  }

  void _startRecord() async {
    await _player.stop();
    await _recorder.start();
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecord() async {
    await _recorder.stop();
    await _player.start();
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: (tap) {
                _startRecord();
              },
              onTapUp: (tap) {
                _stopRecord();
              },
              onTapCancel: () {
                _stopRecord();
              },
              child: Icon(
                _isRecording ? Icons.mic_off : Icons.mic,
                size: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

