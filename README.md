ios-websocketapi
================
High level SockJS/Vertx client api for iOS.
Use this to enable communication with a vertx server with sockjs like functionality through the use of websockets.

Installation Instructions:
There are 2 ways to add this to your project:

1. Include this project as a subproject in your iOS project and use libWebsocketApi in your link library.
You will need to add -ObjC to your "other linker flags" build options.  If that does not work, try adding -all_load as well.

2. Build and add the libWebsocketApi.a and the header files directly to your iOS project.  
You will need to add -all_load to your "other linker flags" build options.

This project uses the SocketRocket api from https://github.com/square/SocketRocket

