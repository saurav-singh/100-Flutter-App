import 'package:flutter/material.dart';
import 'package:podcast/player.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';
import 'notifiers.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final url = "https://itsallwidgets.com/podcast/feed";
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Podcast()..parse(url),
      child: MaterialApp(
        title: "Podcast App",
        home: MyPage(),
      ),
    );
  }
}

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  var navIndex = 0;

  final pages = List<Widget>.unmodifiable([
    EpisodeScreen(),
    DummyScreen(),
  ]);

  final iconList = List<IconData>.unmodifiable([
    Icons.hot_tub,
    Icons.timelapse,
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[navIndex],
      bottomNavigationBar: MyNavBar(
        icons: iconList,
        onPressed: (i) => setState(() => navIndex = i),
        activeIndex: navIndex,
      ),
    );
  }
}

class MyNavBar extends StatefulWidget {
  const MyNavBar(
      {@required this.icons,
      @required this.onPressed,
      @required this.activeIndex})
      : assert(icons != null);

  final List<IconData> icons;
  final Function(int) onPressed;
  final int activeIndex;

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar>
    with SingleTickerProviderStateMixin {
  double iconScale;
  double bubbleRadius;
  double maxBubbleRadius;
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    iconScale = 1.0;
    bubbleRadius = 0;
    maxBubbleRadius = 20;

    controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(MyNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      startAnimation();
    }
  }

  void startAnimation() {
    controller.reset();
    final curve = CurvedAnimation(parent: controller, curve: Curves.linear);
    Tween<double>(begin: 0, end: 1).animate(curve)
      ..addListener(() {
        setState(() {
          bubbleRadius = maxBubbleRadius * curve.value;
          if (bubbleRadius == maxBubbleRadius) {
            bubbleRadius = 0;
          }
          if (curve.value < 0.5) {
            iconScale = 1 + curve.value;
          } else {
            iconScale = 2 - curve.value;
          }
        });
      });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> iconTab = [];
    widget.icons.asMap().forEach((i, icon) {
      iconTab.add(NavBarItem(
          icon: icon,
          isActive: i == widget.activeIndex,
          bubbleRadius: bubbleRadius,
          maxBubbleRadius: maxBubbleRadius,
          iconScale: iconScale,
          onPressed: () => widget.onPressed(i)));
    });

    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: iconTab,
      ),
    );
  }
}

class NavBarItem extends StatelessWidget {
  final bool isActive;
  final double bubbleRadius;
  final double maxBubbleRadius;
  final double iconScale;
  final IconData icon;
  final VoidCallback onPressed;

  NavBarItem(
      {@required this.isActive,
      @required this.bubbleRadius,
      @required this.maxBubbleRadius,
      @required this.iconScale,
      @required this.icon,
      @required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.yellow[700] : Colors.black;
    final double radius = isActive ? bubbleRadius : 0;
    final double scale = isActive ? iconScale : 1;

    return CustomPaint(
      painter: IconPainter(
        radius: radius,
        maxRadius: maxBubbleRadius,
        color: Colors.purpleAccent,
      ),
      child: GestureDetector(
        child: Transform.scale(
          scale: scale,
          child: Icon(icon, color: color),
        ),
        onTap: () => onPressed(),
      ),
    );
  }
}

class IconPainter extends CustomPainter {
  final double radius;
  final double maxRadius;
  final Color color;
  final Color endColor;

  IconPainter({
    @required this.radius,
    @required this.maxRadius,
    @required this.color,
  }) : endColor = Color.lerp(color, Colors.white, 0.6);

  @override
  void paint(Canvas canvas, Size size) {
    if (radius == maxRadius) return;

    double strokeWidth = radius < maxRadius * 0.5 ? radius : maxRadius - radius;
    double animProgress = radius / maxRadius;
    final paint = Paint()
      ..color = Color.lerp(color, endColor, animProgress)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(const Offset(12, 12), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DummyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text("Dummy Page"),
      ),
    );
  }
}

class EpisodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<Podcast>(
      builder: (context, podcast, _) {
        return podcast.feed != null
            ? EpisodeListView(rssFeed: podcast.feed)
            : Center(child: CircularProgressIndicator());
      },
    );
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key key,
    @required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items
          .map((i) => ListTile(
                title: Text(i.title),
                subtitle: Text(
                  i.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.cloud_download),
                  onPressed: () {
                    Provider.of<Podcast>(context, listen: false).download(i);
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Downloading ${i.title}"),
                    ));
                  },
                ),
                onTap: () {
                  Provider.of<Podcast>(context, listen: false).selectedItem = i;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(),
                    ),
                  );
                },
              ))
          .toList(),
    );
  }
}
