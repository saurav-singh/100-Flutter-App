import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:podcast/notifiers.dart';
import 'package:provider/provider.dart';

class PlayerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final item = Provider.of<Podcast>(context).selectedItem;
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
      ),
      body: SafeArea(
        child: PodcastPlayer(),
      ),
    );
  }
}

class PodcastPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    final item = podcast.selectedItem;
    return Column(
      children: [
        Flexible(
          flex: 5,
          child: Image.network(podcast.feed.image.url),
        ),
        Flexible(
          flex: 4,
          child: SingleChildScrollView(
            child: Text(item.description),
          ),
        ),
        Flexible(
          flex: 2,
          child: AudioControls(),
        ),
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [PlaybackButtons()],
    );
  }
}

class PlaybackButtons extends StatefulWidget {
  @override
  _PlaybackButtonState createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButtons> {
  bool _isPlaying = false;
  AudioPlayer player;
  double playPosition;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    playPosition = 0.0;
  }

  void stop() async {
    int result = await player.stop();
    print(result);
  }

  void play(String url) async {
    int result = await player.play(url);
    print(result);
  }

  void fastForward() {}

  void rewind() {}

  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    final item = podcast.selectedItem;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Slider(
          value: playPosition,
          onChanged: null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.fast_rewind),
              onPressed: null,
            ),
            IconButton(
              icon: _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
              onPressed: () {
                if (_isPlaying) {
                  stop();
                } else {
                  var url = podcast.downloadLocations[item] ?? item.guid;
                  print("url $url");
                  play(url);
                }

                setState(() => _isPlaying = !_isPlaying);
              },
            ),
            IconButton(
              icon: Icon(Icons.fast_forward),
              onPressed: null,
            )
          ],
        ),
      ],
    );
  }
}
