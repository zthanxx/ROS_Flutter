import 'package:flutter/material.dart';
import 'package:control_pad/control_pad.dart';
import 'dart:math';
import 'package:roslib/roslib.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Ros ros = Ros();
  Topic chatter = Topic();
  Topic counter = Topic();
  Topic cmd_vel = Topic();

  void _move(double _degrees, double _distance) {
    print(
        'Degree:' + _degrees.toString() + ' Distance:' + _distance.toString());
    double radians = _degrees * ((22 / 7) / 180);
    double linear_speed = cos(radians) * _distance;
    double angular_speed = -sin(radians) * _distance;

    publishCmd(linear_speed, angular_speed);
  }

  @override
  void initState() {
    ros = Ros(url: 'ws://192.168.1.4:9090');
    chatter = Topic(
        ros: ros,
        name: '/chatter',
        type: "std_msgs/String",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10);

    cmd_vel = Topic(
        ros: ros,
        name: '/cmd_vel',
        type: "geometry_msgs/Twist",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10);

    counter = Topic(
      ros: ros,
      name: '/counter',
      type: "std_msgs/String",
      reconnectOnClose: true,
      queueSize: 10,
      queueLength: 10,
    );
    super.initState();
  }

  void initConnection() async {
    ros.connect();
    await chatter.subscribe();

    await counter.advertise();
    await cmd_vel.advertise();
    setState(() {});
  }

  void publishCounter() async {
    var msg = {'data': 'hello'};
    await counter.publish(msg);
    print('done publihsed');
  }

  void publishCmd(double _linear_speed, double _angular_speed) async {
    var linear = {'x': _linear_speed, 'y': 0.0, 'z': 0.0};
    var angular = {'x': 0.0, 'y': 0.0, 'z': _angular_speed};
    var twist = {'linear': linear, 'angular': angular};
    await cmd_vel.publish(twist);
    print('cmd published');
  }

  void destroyConnection() async {
    await chatter.unsubscribe();

    await counter.unadvertise();
    await ros.close();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Object>(
        stream: ros.statusStream,
        builder: (context, snapshot) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  label: Text(snapshot.data == Status.CONNECTED
                      ? 'DISCONNECT'
                      : 'CONNECT'),
                  backgroundColor: snapshot.data == Status.CONNECTED
                      ? Colors.green[300]
                      : Colors.grey[300],
                  onPressed: () {
                    print(snapshot.data);
                    if (snapshot.data != Status.CONNECTED) {
                      this.initConnection();
                    } else {
                      this.destroyConnection();
                    }
                  },
                ),
                Padding(padding: EdgeInsets.all(20)),
                JoystickView(
                  onDirectionChanged: (_degrees, _distance) =>
                      _move(_degrees, _distance),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
