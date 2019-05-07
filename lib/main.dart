import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:ui' show Color;
import 'dart:io';
import 'dart:async';

import 'variables.dart' as variables;
import 'krlx.dart' as krlx;

void main() => runApp(KRLX());

class KRLX extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KRLX',
      theme: variables.theme,
      home: Home(title: 'KRLX'),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  VideoPlayerController _controller;
  Stream<krlx.KRLXUpdate> dataStream;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.network('http://garnet.krlx.org:8000/krlx')
          ..initialize().then((_) {
            // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
            setState(() {});
          });
  }

  _HomeState() {
    // Instantiate the stream
    print("Instantiating KRLX data stream");
    this.dataStream = krlx.fetchStream();
  }

  Future<void> refreshStream() async {
    print("Getting stream");
    // Start the stream

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });
  }

  List<Widget> _djCards(Map<String, String> djs, bool isCurrent) {
    List<Widget> dj_cards = new List<Widget>();
    djs.forEach((String dj_string, String image_url) {
      if (isCurrent) {
        dj_cards.add(ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(image_url)),
            title: Text(dj_string)));
      } else {
        dj_cards.add(ListTile(title: Text(dj_string)));
      }
    });
    return dj_cards;
  }

  List<Widget> _showCard(krlx.Show show){
    String showTitle = show.showData["title"] ?? "No title found";
    String showDesc = show.showData["description"] ?? "No description found";
    List<Widget> cardChildren = new List<Widget>();
    List<Widget> hostCards = _djCards(show.hosts, show.isCurrent);
    cardChildren.add(ListTile(
        title: Text(
          showTitle,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(showDesc)));
    cardChildren.addAll(hostCards);
    cardChildren.add(ListTile(
        title:
            Text(show.relTime, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
            "${show.showData['day']}, ${show.startDisplay}-${show.endDisplay}")));
    return cardChildren;
  }

  Image getSongImage(song){
    if (song.albumCover != null){
      return Image.network(song.albumCover,
          width: MediaQuery
          .of(context)
          .size
          .width-5,
    fit: BoxFit.fill,
    height: 150);
    }
    else{
      return Image.asset("album.png",
          width: MediaQuery
              .of(context)
              .size
              .width-5,
          height: 150,
          );
    }
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _songCard(krlx.Song song){
    // Add YouTube first because the YouTube link will always be there,
    // and users should be able to find it in a consistent location
    List<Widget> buttonChildren = [ OutlineButton.icon(icon:
    new Icon(FontAwesomeIcons.youtube, color: Color(0xFFFF0000)),
         onPressed: (){
          _launchURL(song.youtubeLink);
        },
        label: Text("YouTube"), shape: StadiumBorder())];
    // Add the Spotify link next if it exists
    if (song.spotifyLink != null) {
      buttonChildren.add(
          OutlineButton.icon(icon: new Icon(FontAwesomeIcons.spotify,
              color: Color(0xFF1ED760)), onPressed: () {
                _launchURL(song.spotifyLink);
              },
              label: Text("Spotify"),
              shape: StadiumBorder()
          ),
      );
    }
    List<Widget> bottomButtonChildren = new List<Widget>();
    if (song.spotifyLink != null){
      bottomButtonChildren.add(
        OutlineButton.icon(icon: new Icon(FontAwesomeIcons.apple,
            color: Colors.black),
            onPressed: () {
              _launchURL(song.spotifyLink);
            },
            label: Text("Apple Music"),
            shape: StadiumBorder()
        ),
      );
    }
    Widget topButtonRow = ButtonBar(
        children: buttonChildren, mainAxisSize: MainAxisSize.min);
    Widget bottomButtonRow = ButtonBar(
        children: bottomButtonChildren, mainAxisSize: MainAxisSize.min);
    List<Widget> cardChildren =  [
      getSongImage(song),
      Text(song.songTitle, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 25),
          overflow: TextOverflow.ellipsis),
      Text("Artist: ${song.artist}", overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15)),
      Text("Played By: ${song.playedBy}", overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15)),
      topButtonRow
    ];

    // Add buttons
    return Builder(
      builder: (BuildContext context) {
        return Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            margin: EdgeInsets.symmetric(horizontal: 5.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
            ),
            child: Column(
                children: cardChildren
            )
        );
      }
    );
  }

  List<Widget> _songCards(Map<String, krlx.Song> songs){
    List<Widget> cards = new List<Widget>();
    songs.forEach((String queryID, krlx.Song song) =>
        cards.add(_songCard(song)));
    return cards;
  }

  Widget _render(krlx.KRLXUpdate data){
    List<List<Widget>> showWidgets = new List<List<Widget>>();
    List<Widget> nowShowWidget;
    data.shows.forEach((String showId, krlx.Show show){
      List<Widget> showWidget = _showCard(show);
      if (show.isCurrent){
        nowShowWidget = showWidget;
      } else {
        showWidgets.add(showWidget);
      }
    });
    return Center(
      child: Column(
          children: [
            Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: nowShowWidget
                ),
            ),
            Text("Songs", textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)
            ),
            CarouselSlider(
              height: 300.0,
              items: _songCards(data.songs),
              enableInfiniteScroll: false,
            )
          ]
      )
    );
  }

  ///
  /// Go to the end of the stream when the user clicks play
  void playSeek(){
    _controller.seekTo(_controller.value.duration);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    // Construct a Stream Builder widget
    return StreamBuilder(
      stream: this.dataStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        Widget body;
        if (snapshot.hasError) body = Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            body = Text("Can't connect to KRLX");
            break;
          case ConnectionState.waiting:
            body = Center(
                child: SpinKitRotatingCircle(
              color: variables.theme.accentColor,
              size: 50.0,
            ));
            break;
          case ConnectionState.active:
            body = _render(snapshot.data);
            break;
          case ConnectionState.done:
            // Reinstate the dataStream, wait, and
            this.dataStream = krlx.fetchStream();
            body = Center(
                child: Column(
                  children: [SpinKitRotatingCircle(
                    color: variables.theme.accentColor,
                    size: 50.0,
                  ),
                    Text("Can't connect to KRLX, reloading...")
                  ]
                )
            );
        }
        return MaterialApp(
            title: 'KRLX',
            home: Scaffold(
              appBar: AppBar(
                title: Image.asset("KRLXTitleBar.png"),
              ),
              body: body,
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : this.playSeek();
                  });
                },
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ),
            theme: variables.theme);
      },
    );
  }
}
