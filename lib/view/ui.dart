import 'package:flutter/material.dart';

import 'terminal.dart';
import 'device.dart';

class navUI extends StatefulWidget {
  const navUI({super.key});

  @override
  State<navUI> createState() => _navUIState();
}

class _navUIState extends State<navUI> {
  final List<RemoteDevice> _devices = [];
  int? _selectedIndex;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  double groupAlignment = -1.0;

  Future<void> _addDevice() async {
    final device = await showDialog<RemoteDevice>(
      context: context,
      builder: (context) => const deviceUI(),
    );
    if (!mounted || device == null) return;

    setState(() {
      _devices.add(device);
      _selectedIndex = _devices.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice =
        _selectedIndex == null ? null : _devices[_selectedIndex!];

    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          tabs: <Widget>[
            Tab(icon: Icon(Icons.drive_folder_upload)),
            Tab(icon: Icon(Icons.terminal)),
          ],
        ),
      ),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: _selectedIndex,
              groupAlignment: groupAlignment,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: labelType,
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _addDevice,
                          icon: const Icon(Icons.add),
                        ),
                        const IconButton(
                          onPressed: null,
                          icon: Icon(Icons.settings),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations:
                  _devices
                      .map(
                        (device) => NavigationRailDestination(
                          icon: const Icon(Icons.devices_other),
                          selectedIcon: const Icon(Icons.devices),
                          label: Text(device.host),
                        ),
                      )
                      .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // This is the main content.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        Center(child: Text("Hello!")),
                        CreateTerm(device: selectedDevice),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
