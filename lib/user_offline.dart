import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class OfflineUser extends StatefulWidget {
  const OfflineUser({Key? key}) : super(key: key);

  @override
  _MyBodyState createState() => _MyBodyState();
}

class _MyBodyState extends State<OfflineUser> {
  final String userName = Random().nextInt(10000).toString();
  List<String> alertMessages = [];
  final Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = {};
  List<String> connectedDevices = [];

  String? tempFileUri;
  Map<int, String> map = {};

  bool isAdmin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("NearbyConnections"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: <Widget>[
                const Text(
                  "Permissions",
                ),
                Wrap(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () async {
                        await _checkAllPermissions();
                      },
                    ),
                  ],
                ),
                const Divider(),
                const Text("Location Enabled"),
                Wrap(
                  children: <Widget>[
                    ElevatedButton(
                      child: const Text("enableLocationServices"),
                      onPressed: () async {
                        if (await Location.instance.requestService()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Location Service Enabled :)")));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Enabling Location Service Failed :(")));
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),
                Text("User Name: $userName"),
                Wrap(
                  children: <Widget>[
                    ElevatedButton(
                      child: const Text("Start Advertising"),
                      onPressed: () async {
                        try {
                          bool a = await Nearby().startAdvertising(
                            isAdmin ? 'admin' : 'user-$userName',
                            strategy,
                            onConnectionInitiated: onConnectionInit,
                            onConnectionResult: (id, status) {
                              showSnackbar(status);
                            },
                            onDisconnected: (id) {
                              showSnackbar(
                                  "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
                              setState(() {
                                endpointMap.remove(id);
                              });
                            },
                          );
                          showSnackbar("ADVERTISING: $a");
                        } catch (exception) {
                          showSnackbar(exception);
                        }
                      },
                    ),
                    ElevatedButton(
                      child: const Text("Stop Advertising"),
                      onPressed: () async {
                        await Nearby().stopAdvertising();
                      },
                    ),
                  ],
                ),
                Wrap(
                  children: <Widget>[
                    ElevatedButton(
                      child: const Text("Start Discovery"),
                      onPressed: () async {
                        try {
                          bool a = await Nearby().startDiscovery(
                            isAdmin ? 'admin' : 'user-$userName',
                            strategy,
                            onEndpointFound: (id, name, serviceId) {
                              showModalBottomSheet(
                                context: context,
                                builder: (builder) {
                                  return Center(
                                    child: Column(
                                      children: <Widget>[
                                        Text("id: $id"),
                                        Text("Name: $name"),
                                        Text("ServiceId: $serviceId"),
                                        ElevatedButton(
                                          child:
                                              const Text("Request Connection"),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Nearby().requestConnection(
                                              isAdmin
                                                  ? 'admin'
                                                  : 'user-$userName',
                                              id,
                                              onConnectionInitiated:
                                                  (id, info) {
                                                onConnectionInit(id, info);
                                              },
                                              onConnectionResult: (id, status) {
                                                showSnackbar(status);
                                              },
                                              onDisconnected: (id) {
                                                setState(() {
                                                  endpointMap.remove(id);
                                                });
                                                showSnackbar(
                                                    "Disconnected from: ${endpointMap[id]!.endpointName}, id $id");
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            onEndpointLost: (id) {
                              showSnackbar(
                                  "Lost discovered Endpoint: ${endpointMap[id]?.endpointName}, id $id");
                            },
                          );
                          showSnackbar("DISCOVERING: $a");
                        } catch (e) {
                          showSnackbar(e);
                        }
                      },
                    ),
                    ElevatedButton(
                      child: const Text("Stop Discovery"),
                      onPressed: () async {
                        await Nearby().stopDiscovery();
                      },
                    ),
                  ],
                ),
                Text("Connected Devices:"),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: connectedDevices.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(connectedDevices[index]),
                    );
                  },
                ),
                Text("Number of connected devices: ${endpointMap.length}"),
                ElevatedButton(
                  child: const Text("Stop All Endpoints"),
                  onPressed: () async {
                    await Nearby().stopAllEndpoints();
                    setState(() {
                      endpointMap.clear();
                    });
                  },
                ),
                const Divider(),
                const Text(
                  "Sending Data",
                ),
                ElevatedButton(
                  child: const Text("Send Random Bytes Payload"),
                  onPressed: () async {
                    endpointMap.forEach((key, value) {
                      String a = Random().nextInt(100).toString();
                      showSnackbar(
                          "Sending $a to ${value.endpointName}, id: $key");
                      Nearby().sendBytesPayload(
                          key, Uint8List.fromList(a.codeUnits));
                    });
                  },
                ),
                ElevatedButton(
                  child: const Text("Send File Payload"),
                  onPressed: () async {
                    XFile? file = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);

                    if (file == null) return;

                    for (MapEntry<String, ConnectionInfo> m
                        in endpointMap.entries) {
                      int payloadId =
                          await Nearby().sendFilePayload(m.key, file.path);
                      showSnackbar("Sending file to ${m.key}");
                      Nearby().sendBytesPayload(
                          m.key,
                          Uint8List.fromList(
                              "$payloadId:${file.path.split('/').last}"
                                  .codeUnits));
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("Print file names."),
                  onPressed: () async {
                    final dir = (await getExternalStorageDirectory())!;
                    final files = (await dir.list(recursive: true).toList())
                        .map((f) => f.path)
                        .toList()
                        .join('\n');
                    showSnackbar(files);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.warning),
                  onPressed: () async {
                    await _sendAlertMessage();
                  },
                ),
              ],
            ),
          ),
        ));
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  Future<void> _checkBluetoothPermission() async {
    if (!(await Future.wait([
      Permission.bluetooth.isGranted,
      Permission.bluetoothAdvertise.isGranted,
      Permission.bluetoothConnect.isGranted,
      Permission.bluetoothScan.isGranted,
    ]))
        .any((element) => false)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bluethooth permissions granted :)")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Bluetooth permissions not granted :(")));
    }
  }

  Future<void> _checkNearbyWifiDevicesPermission() async {
    if (await Permission.nearbyWifiDevices.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("NearbyWifiDevices permissions granted :)")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("NearbyWifiDevices permissions not granted :(")));
    }
  }

  Future<void> _checkAllPermissions() async {
    await _checkBluetoothPermission();
    await _checkNearbyWifiDevicesPermission();
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: $id"),
              Text("Token: ${info.authenticationToken}"),
              Text("Name: ${info.endpointName}"),
              Text("Incoming: ${info.isIncomingConnection}"),
              ElevatedButton(
                child: const Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    endpointMap[id] = info;
                    connectedDevices.add(info.endpointName);
                  });
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {},
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {},
                  );
                },
              ),
              ElevatedButton(
                child: const Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendAlertMessage() async {
    LocationData currentLocation = await Location.instance.getLocation();
    String alertMessage =
        "Alert: Device at (${currentLocation.latitude}, ${currentLocation.longitude})";

    endpointMap.forEach((key, value) {
      Nearby()
          .sendBytesPayload(key, Uint8List.fromList(alertMessage.codeUnits))
          .then((_) {
        showSnackbar("Alert message sent to ${value.endpointName}");
      }).catchError((error) {
        showSnackbar(
            "Error sending alert message to ${value.endpointName}: $error");
      });
    });
  }

  void onPayloadReceived(String id, Payload payload) {
    String alertMessage = String.fromCharCodes(payload.bytes!);

    if (!map.containsValue(alertMessage)) {
      map[payload.id] = alertMessage;
      endpointMap.forEach((key, value) {
        if (key != id) {
          Nearby().sendBytesPayload(key, payload.bytes!);
        }
      });
    }

    if (isAdmin) {
      setState(() {
        alertMessages.add(alertMessage);
      });
    }
  }
}
