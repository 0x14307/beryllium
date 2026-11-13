import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'terminal.dart';
import 'device.dart';
import 'files.dart';

const _devicesPreferenceKey = 'saved_devices';

class navUI extends StatefulWidget {
  const navUI({super.key});

  @override
  State<navUI> createState() => _navUIState();
}

class _navUIState extends State<navUI> {
  final List<RemoteDevice> _devices = [];
  int? _selectedIndex;
  bool _isLoadingDevices = true;
  bool _isSavingDevice = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDevices());
  }

  Future<void> _loadDevices() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedDevices = preferences.getString(_devicesPreferenceKey);
      final devices =
          savedDevices == null
              ? <RemoteDevice>[]
              : (jsonDecode(savedDevices) as List<dynamic>)
                  .map(RemoteDevice.fromJson)
                  .toList();

      if (!mounted) return;
      setState(() {
        _devices.addAll(devices);
        _isLoadingDevices = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingDevices = false;
      });
      _showError('Unable to load saved devices: $error');
    }
  }

  Future<void> _addDevice() async {
    if (_isLoadingDevices || _isSavingDevice) return;

    final device = await showFDialog<RemoteDevice>(
      context: context,
      builder: (context, style, animation) => deviceUI(animation: animation),
    );
    if (!mounted || device == null) return;

    setState(() {
      _isSavingDevice = true;
    });

    try {
      final devices = [..._devices, device];
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _devicesPreferenceKey,
        jsonEncode(devices.map((device) => device.toJson()).toList()),
      );
      if (!saved) throw StateError('Device preferences were not saved');

      if (!mounted) return;
      setState(() {
        _devices.add(device);
        _selectedIndex = _devices.length - 1;
      });
    } catch (error) {
      if (mounted) _showError('Unable to save device: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDevice = false;
        });
      }
    }
  }

  Future<void> _removeDevice(int index) async {
    if (_isLoadingDevices ||
        _isSavingDevice ||
        index < 0 ||
        index >= _devices.length) {
      return;
    }

    final devices = [..._devices]..removeAt(index);
    setState(() {
      _isSavingDevice = true;
    });

    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _devicesPreferenceKey,
        jsonEncode(devices.map((device) => device.toJson()).toList()),
      );
      if (!saved) throw StateError('Device preferences were not saved');

      if (!mounted) return;
      setState(() {
        _devices.removeAt(index);
        if (_selectedIndex == index) {
          _selectedIndex =
              _devices.isEmpty
                  ? null
                  : (index < _devices.length ? index : _devices.length - 1);
        } else if (_selectedIndex != null && _selectedIndex! > index) {
          _selectedIndex = _selectedIndex! - 1;
        }
      });
    } catch (error) {
      if (mounted) _showError('Unable to remove device: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDevice = false;
        });
      }
    }
  }

  Future<void> _confirmRemoveDevice(int index) async {
    if (_isLoadingDevices ||
        _isSavingDevice ||
        index < 0 ||
        index >= _devices.length) {
      return;
    }

    final device = _devices[index];
    final confirmed = await showFDialog<bool>(
      context: context,
      builder:
          (context, style, animation) => FDialog(
            animation: animation,
            builder:
                (context, style) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Remove device?', style: style.titleTextStyle),
                      const SizedBox(height: 8),
                      Text('Remove ${device.host} from saved devices?'),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FButton(
                            variant: FButtonVariant.ghost,
                            onPress: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FButton(
                            variant: FButtonVariant.secondary,
                            onPress: () => Navigator.pop(context, true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );

    if (mounted && confirmed == true) {
      await _removeDevice(index);
    }
  }

  void _showError(String message) {
    showFToast(
      context: context,
      title: Text(message),
      variant: FToastVariant.destructive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice =
        _selectedIndex == null ? null : _devices[_selectedIndex!];

    final navigationRail = FSidebar(
      header: const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Devices'),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FButton(
              variant: FButtonVariant.secondary,
              onPress: _isLoadingDevices || _isSavingDevice ? null : _addDevice,
              mainAxisAlignment: MainAxisAlignment.start,
              prefix: const Icon(FLucideIcons.plus),
              child: const Text('Add device'),
            ),
            const SizedBox(height: 8),
            FButton(
              variant: FButtonVariant.ghost,
              onPress: () {},
              mainAxisAlignment: MainAxisAlignment.start,
              prefix: const Icon(FLucideIcons.settings),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
      children:
          _devices.asMap().entries.map((entry) {
            final index = entry.key;
            final device = entry.value;
            final isSelected = _selectedIndex == index;

            return GestureDetector(
              onSecondaryTap:
                  _isSavingDevice
                      ? null
                      : () => unawaited(_confirmRemoveDevice(index)),
              child: FButton(
                variant:
                    isSelected
                        ? FButtonVariant.secondary
                        : FButtonVariant.ghost,
                onPress:
                    _isSavingDevice
                        ? null
                        : () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                mainAxisAlignment: MainAxisAlignment.start,
                prefix: const Icon(FLucideIcons.server),
                child: Text(device.host),
              ),
            );
          }).toList(),
    );

    return FScaffold(
      sidebar: navigationRail,
      childPad: false,
      child: FTabs(
        expands: true,
        children: [
          FTabEntry(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(FLucideIcons.folder),
                SizedBox(width: 8),
                Text('Files'),
              ],
            ),
            child: FileTree(device: selectedDevice),
          ),
          FTabEntry(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(FLucideIcons.terminal),
                SizedBox(width: 8),
                Text('Terminal'),
              ],
            ),
            child: CreateTerm(device: selectedDevice),
          ),
        ],
      ),
    );
  }
}
