import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() {
    return _instance;
  }
  SocketService._internal();

  IO.Socket? _socket;


  IO.Socket? get socket => _socket;

  void initializeSocket({String? token}) {
    // Prevent multiple initializations
    if (_socket != null && _socket!.connected) {
      print("✅ Socket is already initialized and connected.");
      return;
    }
    
    try {
      const String socketUrl = 'http://34.93.60.221:3001/tracking';

      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'auth': token != null ? {'token': token} : null,
      });
    
      _socket!.connect();

      // CORRECTED: Use _socket instead of socket
      _socket!.onConnect((_) {
        print('✅ WebSocket Connected to server.');
      });

      // CORRECTED: Use _socket instead of socket
      _socket!.onDisconnect((_) {
        print('❌ WebSocket Disconnected from server.');
      });

      _socket!.onError((error) {
        print('Socket Error: $error');
      });

    } catch (e) {
      print('Error initializing socket: $e');
    }
  }
  
  // A generic method to send any event to the server
  void emit(String event, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Socket not initialized or disconnected. Cannot send event: $event');
      return;
    }
    _socket!.emit(event, data);
    print('📡 Emitted event: $event');
  }

  // Check if socket is connected
  bool get isConnected => _socket != null && _socket!.connected;

  // Reconnect if disconnected
  void reconnect() {
    if (_socket != null && !_socket!.connected) {
      _socket!.connect();
    }
  }

  // Test connection with a simple ping
  void testConnection() {
    if (isConnected) {
      emit('ping', {'message': 'Connection test from Flutter app'});
    } else {
      print('❌ Socket not connected. Cannot test connection.');
    }
  }

  // Join driver room for trip-specific communication (Official Guide Implementation)
  void joinDriverRoom(String tripId) {
    if (isConnected) {
      emit('joinDriverRoom', {'tripId': tripId});
      print('🚗 Joined driver room for trip: $tripId (following official guide)');
    } else {
      print('❌ Socket not connected. Cannot join driver room.');
    }
  }

  // Leave driver room when trip ends (Official Guide cleanup)
  void leaveDriverRoom(String tripId) {
    if (isConnected) {
      emit('leaveDriverRoom', {'tripId': tripId});
      print('🚪 Left driver room for trip: $tripId (official guide cleanup)');
    }
  }

  void notifyTripStarted(String tripId) {
    if (isConnected) {
      emit('tripStarted', {'tripId': tripId});
      print('🚀 Notified trip started: $tripId (passengers can now track live - Official Guide Step 2)');
    }
  }

  // Call this when the user logs out or the app is closing
  void disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}