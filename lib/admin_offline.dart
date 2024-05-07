import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';

class OfflineAdmin extends StatefulWidget {
  final List<String> alertMessages;

  const OfflineAdmin({Key? key, required this.alertMessages}) : super(key: key);

  @override
  _OfflineAdminState createState() => _OfflineAdminState();
}

class _OfflineAdminState extends State<OfflineAdmin> {
  final String adminName = 'admin';
  final Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = {};
  List<String> connectedDevices = [];
  List<String> allAlerts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  bool a = await Nearby().startAdvertising(
                    adminName,
                    strategy,
                    onConnectionInitiated: onConnectionInit,
                    onConnectionResult: (id, status) {
                      showSnackbar(status);
                    },
                    onDisconnected: (id) {
                      showSnackbar(
                          "Disconnected from: ${endpointMap[id]?.endpointName}, id $id");
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
              child: Text('Start Advertising'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Nearby().stopAdvertising();
                showSnackbar('Advertising stopped');
              },
              child: Text('Stop Advertising'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  bool a = await Nearby().startDiscovery(
                    adminName,
                    strategy,
                    onEndpointFound: (id, name, serviceId) {
                      showModalBottomSheet(
                        context: context,
                        builder: (builder) {
                          return Center(
                            child: Column(
                              children: [
                                Text("id: $id"),
                                Text("Name: $name"),
                                Text("ServiceId: $serviceId"),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Nearby().requestConnection(
                                      adminName,
                                      id,
                                      onConnectionInitiated: (id, info) {
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
                                            "Disconnected from: ${endpointMap[id]?.endpointName}, id $id");
                                      },
                                    );
                                  },
                                  child: Text('Request Connection'),
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
              child: Text('Start Discovery'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Nearby().stopDiscovery();
                showSnackbar('Discovery stopped');
              },
              child: Text('Stop Discovery'),
            ),
            Text('Connected Devices:'),
            ListView.builder(
              shrinkWrap: true,
              itemCount: connectedDevices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(connectedDevices[index]),
                );
              },
            ),
            SizedBox(height: 16),
            Text('All Alerts:'),
            ListView.builder(
              shrinkWrap: true,
              itemCount: allAlerts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(allAlerts[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void showSnackbar(dynamic message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message.toString())));
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: [
              Text("id: $id"),
              Text("Token: ${info.authenticationToken}"),
              Text("Name: ${info.endpointName}"),
              Text("Incoming: ${info.isIncomingConnection}"),
              ElevatedButton(
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
                child: Text('Accept Connection'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
                child: Text('Reject Connection'),
              ),
            ],
          ),
        );
      },
    );
  }
}
