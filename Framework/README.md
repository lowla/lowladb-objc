# LowlaDB-objc/Framework

This project packages the LowlaDB Objective C bindings as a framework for use in environments where CocoaPods aren't convenient (e.g., Cordova). It uses the standard Framework template in XCode 6 and thus requires iOS 8 at runtime.

XCode 6 does not provide any support for building iOS frameworks that support both iOS devices and the simulator, so for now this is a manual process. Specifically, to build the framework:

- Build for the simulator
- Build for device
- Locate the device framework and use the commands
 
 ```
    lipo -create <location of simulator binary> <location of device binary> -output <temp location>
	rm <location of device binary>
	cp <temp location> <location of device binary>
```
	
The device framework can then be copied into the target project as required.	