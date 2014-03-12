CrashMonkey
===========

About
----

This is a tool of monkey test(random operation test) for iOS applications.
Please watch the [demo movie](http://youtu.be/y5PZGVbLHtI).
CrashMonkey uses UIAutomation and modified [ui-auto-monkey](https://github.com/jonathanpenn/ui-auto-monkey) for iPhone Simulator manipulation.


Environment
-------

It is confirmed only in the following environment.

* Max OS X 10.8.4
* Xcode 4.6.3(Build version 4H1503)
* Ruby 1.8.7-p371

Ruby versions may be OK 1.9.x and 2.0.x.

Features
---------

### Good Points

* No need to modify the app's project.
* It can specify the running period and times.
* The results of Screenshots and Operations history can be shown as HTML.
* the console log and crash report can be shown.
* It is easy to be used from CI tools like Jenkins.

### Restrictions

* It can be run only in iPhone Simulator.
* The test can not continue when another application(like Safari) is the most front. (detect and finish the test).
* It can not input suitable characters like ID/Pass.


Install
--------

```
gem install crash_monkey --no-ri --no-rdoc
```

How to use
------

### Simple Usage

```
crash_monkey -a <APP_NAME or APP_PATH>
```

`-a` specify AppName or PATH.


#### 例

```
crash_monkey -a MyAwesomeApp.app                               # (1)
crash_monkey -a build/Debug-iphonesimulator/MyAwesomeApp.app   # (2)
crash_monkey -a ~/Library/Developer/Xcode/DerivedData/MyAwesomeApp-ffumcy/Build/Products/Debug-iphonesimulator/MyAwesomeApp.app # (3)
```

* in (1) case, an application is executed which matches the app's name installed in iPhone Simulator. If there are same name apps, the app of latest updated time is used.

* in (2)(3) cases, an app which in the PATH is excuted. It is required that the app is built for iPhone Simlator.
 


### Options

```
% crash_monkey
Usage: crash_monkey [options]
    -a app_name                      Target Application(Required)
    -n run_count                     How many times monkeys run(default: 2)
    -d result_dir                    Where to output result(default: ./crash_monkey_result)
    -t time_limit_sec                Time limit of running(default: 100 sec)
    -c config_path                   Configuration JSON Path
    -e extend_javascript_path        Extend Uiautomation Javascript for such Login scripts
        --show-config                Show Current Configuration JSON
        --list-app                   Show List of Installed Apps in iOS Simulator
        --reset-iPhone-Simulator     Reset iPhone Simulator
```


#### -n
The times for monkey test excution.

#### -d
The directory for output results.

#### -t
Timeout seconds for one monkey test.

#### -c
Specify configuration file(JSON format) for UIAutomation library.
The template is shown by `--show-config` option.

#### -e
Specify extend Javascript file for UIAutomation library.    
It could be used for login.([example](https://gist.github.com/jollychang/8972186))

#### --show-config
Output configuration for UIAutomation library by JSON format.

#### --list-app
List apps for iPhone Simulator.

#### --reset-iPhone-Simulator.
Reset iPhone Simulator.


For Jenkins
--------------

CrashMonkey has CUI interface, so easy to use from Jenkins.
There are a few notes.

### Confirmation dialog from UIAutomation is displayed and stop tests.

The first time in the Mac CrashMonkey run, Instruments(UIAutomation) may display a confirmation dialog and require to input password.

In this case, the test can not run if the password is not entered. The following management may be valid.


* The Jenkins running User has Administration privilege.
* In case Jenkins is running as slave, launch with X like following.

	```
	javaws http://<SERVER>/computer/<NodeName>/slave-agent.jnlp
	```

* The first time a Jenkins Job runs in the Mac, if the dialog is displyed then input correct password.

Other conditions may be OK, but this is also work.


Troubleshooting
-------------------

### CASE: xcode-select is not set.


#### symptoms

```
% crash_monkey -a MyGoodApp.app
.....
Run: ["instruments", "-l", "100000", "-t", ........... ]
xcode-select: Error: No Xcode folder is set. Run xcode-select -switch <xcode_folder_path> to set the path to the Xcode folder.
.....
```

#### measures

Please specify the install path of Xcode by **xcode-select**.

ex）

```
sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
```



Contributing to CrashMonkey
---------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
----------

Copyright (c) 2013 Ken Morishita. See LICENSE.txt for
further details.

