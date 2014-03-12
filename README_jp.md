CrashMonkey
===========

[English](README.md)

概要
----

iOSのアプリケーションをモンキーテスト（ランダムな操作をひたすら行う）するためのツールです。
動作イメージはこの[デモ動画](http://youtu.be/y5PZGVbLHtI)を御覧ください。
iPhone Simulatorの操作にはUIAutomationを使っていて、ベースとして[ui-auto-monkey](https://github.com/jonathanpenn/ui-auto-monkey)を使わせて頂きました。


動作環境
-------

以下の環境でのみ確認してあります。

* Max OS X 10.8.4
* Xcode 4.6.3(Build version 4H1503)
* Ruby 1.8.7-p371

Rubyについては、1.9系, 2.0系でも動くと思います。


CrashMonkeyの特徴
---------------

### 良い点

* アプリのプロジェクト自体に変更を加えなくても実行することができます
* 実行時間や実行回数を指定できます
* 実行結果をScreenshotと操作履歴のHTMLとしてみることができます
* 実行時のConsoleLogや、Crash時のCrashレポートもみることができます
* JenkinsなどのCIツールとの連携も容易です

### 制限

* iPhone Simulator でしか実行できません
* 別のアプリ(Safariなど）に遷移してしまうと、テストが継続できません（検知してその回を終了します）
* 適切な文字入力(ID/PASS等)とか猿だとできないような難しい操作ができません


Install
--------

```
gem install crash_monkey --no-ri --no-rdoc
```

使いかた
------

```
crash_monkey -a <APP_NAME or APP_PATH>
```

`-a`でアプリの名前かPATHを指定します。

#### 例

```
crash_monkey -a MyAwesomeApp.app                               # (1)
crash_monkey -a build/Debug-iphonesimulator/MyAwesomeApp.app   # (2)
crash_monkey -a ~/Library/Developer/Xcode/DerivedData/MyAwesomeApp-ffumcy/Build/Products/Debug-iphonesimulator/MyAwesomeApp.app # (3)
```

* (1) の指定方法では、iPhone Simulatorにインストールされているアプリで名前が一致するものを実行します。同名のものが複数ある場合は更新時刻が一番新しいものを使います
* (2)(3) の指定方法では、PATHにあるアプリを実行します。ただし、iPhone Simulator用にビルドされたものじゃないと使えないので注意して下さい。
	* Dir名に **iphonesimulator** と入っているものが大抵そうです




### Options

```
% crash_monkey
Usage: crash_monkey [options]
    -a app_name                      Target Application(Required)
    -n run_count                     How many times monkeys run(default: 2)
    -d result_dir                    Where to output result(default: ./crash_monkey_result)
    -t time_limit_sec                Time limit of running(default: 100 sec)
    -c config_path                   Configuration JSON Path
        --show-config                Show Current Configuration JSON
        --list-app                   Show List of Installed Apps in iOS Simulator
```


#### -n
Monkey Testを実行する回数を指定します。

#### -d
結果を出力するDirを指定します。

#### -t
1回のテストのTimeoutを秒で指定します。

#### -c
UIAutomationの実行時に使うJSON形式のConfigファイルを指定します。雛形については `--show-config`オプションで取得してください。

#### --show-config
UIAutomationの実行時に使うConfigファイルをJSON形式で出力します。変更したい場合は、一度ファイルに保存してから変更し、 `-c` で指定してください。

#### --list-app

iPhone Simulatorにインストールされているアプリの名前の一覧を表示します。

Jenkinsとの連携
--------------

CrashMonkeyはコマンドラインから起動するので、JenkinsなどのCIツールと連携するのは難しくないですが、いくつか注意点を挙げておきます。

### UIAutomation の 確認ダイアログがでる

そのMacで初めてCrashMonkeyを実行する場合、Instruments(UIAutomation)が確認ダイアログを表示してパスワードの入力が求められることがあります。

この場合パスワードを入力しないと実行できませんが、少なくとも以下の対処をしておけば良いです。

* Jenkins実行ユーザがAdmin権限を持っている
* Jenkins Slaveを動かしている場合

	```
	javaws http://<SERVER>/computer/<NodeName>/slave-agent.jnlp
	```
  というようなXを使った起動方法にしておく
* Jenkinsからの実行時に、一度ダイアログが出るので、正しいパスワードを入力する


違う条件でも動くかもしれませんが、上記のようにしておけばダイアログが出なくなります。

ssh でログインしてこの状態になったときに、CUI上でユーザ名とパスワードを聞かれることがあります。
ここで正しく入力しても動かなかいことがありますので注意が必要です。


トラブルシューティング
-------------------

### xcode-select が設定されていないケース


#### 現象
```
% crash_monkey -a MyGoodApp.app
.....
Run: ["instruments", "-l", "100000", "-t", ........... ]
xcode-select: Error: No Xcode folder is set. Run xcode-select -switch <xcode_folder_path> to set the path to the Xcode folder.
.....
```

#### 対処

xcode-select で XcodeのInstall Pathを指定して下さい。

例）

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

