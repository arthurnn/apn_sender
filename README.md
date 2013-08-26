[![Code Climate](https://codeclimate.com/github/arthurnn/apn_sender.png)](https://codeclimate.com/github/arthurnn/apn_sender)
[![Build Status](https://travis-ci.org/arthurnn/apn_sender.png)](https://travis-ci.org/arthurnn/apn_sender)

## UPDATE May 3, 2013: current status

This project was not supported for a while, but we are going to support it again.

-----

## Synopsis

Need to send background notifications to an iPhone application over a <em>persistent</em> connection in Ruby? Keep reading...

## The Story

So you're building the server component of an iPhone application in Ruby and you want to send background notifications through the Apple Push Notification servers. This doesn't seem too bad at first, but then you read in the [Apple Documentation](https://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Introduction.html) that Apple's servers may treat non-persistent connections as a Denial of Service attack. Since Rails has no easy way to maintain a persistent connection internally, things start to look complicated.

This gem includes a background daemon which processes background messages from your application and sends them along to Apple <em>over a single, persistent socket</em>.  It also includes the ability to query the Feedback service, helper methods for enqueueing your jobs, and a sample monit config to make sure the background worker is around when you need it.

## Yet another ApplePushNotification interface?

Yup.  There's some great code out there already, but we didn't like the idea of getting banned from the APN gateway for establishing a new connection each time we needed to send a batch of messages, and none of the libraries I found handled maintaining a persistent connection.

## Current Status
This gem has been used in production, on 500px, sending hundreds of millions, if not, billions of notifications.

## Usage

### 1. Queueing Messages From Your Application

To queue a message for sending through Apple's Push Notification service from your Rails application:

```
APN.notify_async(token, opts_hash)
```

Where ```token``` is the unique identifier of the iPhone to receive the notification and ```opts_hash``` can have any of the following keys:

* :alert  ## The alert to send
* :badge  ## The badge number to send
* :sound  ## The sound file to play on receipt, or true to play the default sound installed with your app

If any other keys are present they'll be be passed along as custom data to your application.

### 2. Sending Queued Messages

Put your ```apn_development.pem``` and ```apn_production.pem``` certificates from Apple in your ```RAILS_ROOT/config/certs``` directory.

Once this is done, you can fire off a background worker with

```
$ rake apn:sender
```

For production, you're probably better off running a dedicated daemon and setting up monit to watch over it for you.  Luckily, that's pretty easy:

```
 # To generate daemon
./script/generate apn_sender

 # To run daemon. Pass --help to print all options
./script/apn_sender start
```

Also, there are two similar options: ```:cert_path``` and ```:full_cert_path```.  The former specifies the directory in which to find the .pem file (either apn_production.pem or apn_development.pem, depending on the environment). The latter specifies a .pem file explicitly, allowing customized certificate names if needed.

Check ```logs/apn_sender.log``` for debugging output.  In addition to logging any major errors there, apn_sender hooks into the Resque::Worker logging to display any verbose or very_verbose worker output in apn_sender.log file as well.


### 3. Checking Apple's Feedback Service

Since push notifications are a fire-and-forget sorta deal, where you get no indication if your message was received (or if the specified recipient even exists), Apple needed to come up with some other way to ensure their network isn't clogged with thousands of bogus messages (e.g. from developers sending messages to phones where their application <em>used</em> to be installed, but where the user has since removed it).  Hence, the Feedback Service.

It's actually really simple - you connect to them periodically and they give you a big dump of tokens you shouldn't send to anymore.  The gem wraps this up nicely -- just call:

```
 # APN::Feedback accepts the same optional :environment
 # and :cert_path / :full_cert_path options as APN::Sender
 feedback = APN::Feedback.new()

 tokens = feedback.tokens # Array of device tokens
 tokens.each do |token|
   # ... custom logic here to stop you app from
   # sending further notifications to this token
 end
```

If you're interested in knowing exactly <em>when</em> Apple determined each token was expired (which can be useful in determining if the application re-registered with your service since it first appeared in the expired queue):

```
 items = feedback.data # Array of APN::FeedbackItem elements
 items.each do |item|
   item.token
   item.timestamp
   # ... custom logic here
 end
```

The Feedback Service works as a big queue.  When you connect it pops off all its data and sends it over the wire at once, which means connecting a second time will return an empty array, so for ease of use a call to either +tokens+ or +data+ will connect once and cache the data.  If you call either one again it'll continue to use its cached version (rather than connecting to Apple a second time to retrieve an empty array, which is probably not what you want).

Forcing a reconnect is as easy as calling either method with the single parameter +true+, but be sure you've already used the existing data because you'll never get it back.


#### Warning: No really, check Apple's Feedback Service occasionally

If you're sending notifications, you should definitely call one of the ```receive``` methods periodically, as Apple's policies require it and they apparently monitor providers for compliance.  I'd definitely recommend throwing together a quick rake task to take care of this for you (the [whenever library](http://github.com/javan/whenever) provides a nice wrapper around scheduling tasks to run at certain times (for systems with cron enabled)).

Just for the record, this is essentially what you want to have whenever run periodically for you:
```
def self.clear_uninstalled_applications
  feedback_data = APN::Feedback.new(:environment #> :production).data

  feedback_data.each do |item|
    user = User.find_by_iphone_token( item.token )

    if user.iphone_token_updated_at && user.iphone_token_updated_at > item.timestamp
      return true # App has been reregistered since Apple determined it'd been uninstalled
    else
      user.update_attributes(iphone_token: nil, iphone_token_updated_at: Time.now)
    end
  end
end
```


### Keeping Your Workers Working

There's also an included sample ```apn_sender.monitrc``` file in the ```contrib/``` folder to help monit handle server restarts and unexpected disasters.


## Installation

APN is built on top of [Resque](http://github.com/defunkt/resque) (an awesome [Redis](http://code.google.com/p/redis/)-based background runner similar to [delayed_job](http://github.com/collectiveidea/delayed_job)). Read through the [Resque README](http://github.com/defunkt/resque#readme) to get a feel for what's going on, follow the installation instructions there, and then run:

```
  $ gem install apn_sender
```
In your Rails app, add (2.3.x):

```
  config.gem 'apn_sender', :lib => 'apn'
```
or (3.x) to your Gemfile:

```
  gem 'apn_sender', require: 'apn'
```
To add a few useful rake tasks for running workers, add the following line to your Rakefile:

```
  require 'apn/tasks'
```

## License

APN Sender is released under the [MIT License](http://www.opensource.org/licenses/MIT).
