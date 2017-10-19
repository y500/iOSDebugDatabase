# YYDebugDatabase

### YYDebugDatabase is a powerful library for debugging databases in iOS applications. Which like [Android Debug database](https://github.com/amitshekhariitbhu/Android-Debug-Database)

### YYDebugDatabase allows you to view and edit databases directly in your browser in a very simple way.

### What can YYDebugDatabase do?
- [x] See all the databases.
- [x] Run any sql query on the given database to update and delete your data.
- [x] Directly edit the database values.
- [x] Directly add a row in the database.
- [x] Delete database rows.
- [x] Search in your data.
- [x] Sort data.
- [x] Download database.


# Installation

#### Podfile

To integrate YYDebugDatabase into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'YYDebugDatabase'
```

If use Swift, remember to add `use_frameworks!`

```ruby
use_frameworks!
pod 'YYDebugDatabase'
```

#### Not build in Release

First, add configurations in Podfile.

```ruby
pod 'YYDebugDatabase', :configurations => ['Debug']
```


Then, run the following command:

```bash
$ pod install
```

# USage

import at AppDelegate.m:

```objc
#import YYDebugDatabaseManager.h
```

making one line code at `application:didFinishLaunchingWithOptions`:

```objc
[[DebugDatabaseManager shared] startServerOnPort:9002];
```
#### Not run in Release

```objc
#ifdef DEBUG
	[[DebugDatabaseManager shared] startServerOnPort:9002];
#end
```

If use Swift:

import at Appdelegate.swift:

```swift
import YYDebugDatabase
```
making one line code at `application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)`:

```Swift:
DebugDatabaseManager.shared().startServer(onPort: 9002);
```

# Advanced

It only shows the databasesin in Documents directory and Library/Cache directory by default, if you want show databases in other directories, you can use:

```objc
- (void)startServerOnPort:(NSInteger)port directories:(NSArray*)directories
```
for example:

```objc
    NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
    NSString *databaseDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/database"];
    NSString *documentDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documnets"];
    NSString *cacheDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Cache"];
    [[DebugDatabaseManager shared] startServerOnPort:9002 directories:@[resourceDirectory, databaseDirectory, documentDirectory, cacheDirectory]];
```
If use Swift:

```swift
    let directory:String = (Bundle.main.resourcePath)!;
    let documentsPath:String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let cachePath:String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    DebugDatabaseManager.shared().startServer(onPort: 9002, directories: [directory, documentsPath, cachePath]);
```

That’s all(you can look at the Demo for details), just start the application :

Now open the provided link in your browser, and you will see like this:

![](http://noti.qiniudn.com/693916a699a78a1c01da2d93126c0ed71.png)

query:

![](http://noti.qiniudn.com/21dd97948e85cf928751ef6d2b7d92662.png)

edit:

![](http://noti.qiniudn.com/b081fa0e1842a05c23321d08f7cec6683.png)

delete:

![](http://noti.qiniudn.com/d0c7cb82ae6aadf790dc57da6c6e888f4.png)


Important:
- Your iPhone and laptop should be connected to the same Network (Wifi or LAN).
- the host of you link address is the iPhone's net address.
- If you use Simulator you can use address: http://127.0.0.1:9002.
- the port must be same as you write in Appdelegate.m

### License
```
   Copyright (C) 2016 y500

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

