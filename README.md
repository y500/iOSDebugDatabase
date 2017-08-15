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

```
#import YYDebugDatabaseManager.h
```

making one line code at `application:didFinishLaunchingWithOptions`:

```ruby
[[DebugDatabaseManager shared] startServerOnPort:9002];
```
#### Not run in Release

```
#ifdef DEBUG
	[[DebugDatabaseManager shared] startServerOnPort:9002];
#end
```

That’s all, just start the application :

Now open the provided link in your browser, and you will see like this:

![](http://noti.qiniudn.com/693916a699a78a1c01da2d93126c0ed7.png)

query:
![](http://noti.qiniudn.com/21dd97948e85cf928751ef6d2b7d9266.png)

edit:
![](http://noti.qiniudn.com/b081fa0e1842a05c23321d08f7cec668.png)
delete:
![](http://noti.qiniudn.com/d0c7cb82ae6aadf790dc57da6c6e888f.png)


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
