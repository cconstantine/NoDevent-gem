[![Build Status](https://secure.travis-ci.org/cconstantine/NoDevent-gem.png?branch=master)](http://travis-ci.org/cconstantine/NoDevent-gem)

# Nodevent

Ruby support for sending NoDevent events.

## Installation

There is a rubygem named 'nodevent'.  To install simply `gem install nodevent` the in ruby:
```ruby
require 'nodevent'
```

or, add this to your Gemfile
```ruby
gem 'nodevent'
```

## Configuring NoDevent

The NoDevent module comes with a default config that will work if you're using the default appliance config.  NoDevent expects a global $redis redis connection to exist, and it will use that to post events.

You can override that config
```ruby
NoDevent::Emitter.config = {:host => "http://myawesomesite", :namespace => "/other_namespace", :secret => 'lajf0q983j4laidsnvqo84jfoqijflkjafds' }
```
The namespace must match exactly to your configured namespace in the appliance.  If there is a missmatch nothing will happen in the client and it can be VERY frustrating to debug.  The secret must match also, or you will get errors attempting to join a room.  You are also completely replacing the default config, so you must specify everything.


## View helper
To get the magic javascript include tag in your view there is a rails view helper.  
```ruby
javascript_include_nodevent
```
That will include the script tag with the configured path. 

## NoDevent::Emitter

This is where the magic happens.  

### Example usage:
In the controller
```ruby
@room = NoDevent::Emitter.room(current_user)
@roomkey = NoDevent::Emitter.room_key(current_user, Time.zone.now + 1.hour)
```

In the view
```erb
<%= content_for :javascript do %>
  current_user_room = NoDevent.room('<%=@room%>');
  current_user_room.setKey('<%=@roomkey%>');
  current_user_room.join();
<% end %>

### NoDevent::Emitter.room(obj)

Example usage:
```ruby
# Get the name of a room for a class/module
@roomname = NoDevent::Emitter.room(SomeModel)

# Get the name of a room for a model instance
@roomname = NoDevent::Emitter.room(SomeModel.first)

# Just returns "the_room"
@roomname = NoDevent::Emitter.room("the_room")
```
This is a helper method to get the name of a room.  You don't really need to use it, but it can convert objects that inherit from ActiveRecord::Base into their unique room name.

### NoDevent::Emitter.room_key(obj, expires)

This is a helper method to generate the key for a room with a given experation time.  

Example usage:
```ruby
@roomkey = NoDevent::Emitter.room_key(SomeModel, Time.zone.now + 1.hour)
@roomkey = NoDevent::Emitter.room_key(SomeModel.first, Time.zone.now + 1.hour)
@roomkey = NoDevent::Emitter.room_key(@roomname, Time.zone.now + 1.hour)
@roomkey = NoDevent::Emitter.room_key('the_room', Time.zone.now + 1.hour)
```
The above code will generate a key for the room that is valid for the next hour.

### NoDevent::Emitter.emit(room, event, message)

This method emits a named event with a message (any object that responds to .to_json) to the room.

```ruby
NoDevent::Emitter.emit(NoDevent::Emitter.room(SomeModel.first), 'the_event', 'some_message')
NoDevent::Emitter.emit('the_room', 'the_event', {:some => :data, :other => :thing})
```

The event will travel through redis to the NoDevent appliance server, and any browser client room object will emit an event named after the event name.
```javascript
var room = Nodevent.room('the_room')
room.join()
room.on('the_event', function(message) {});
```

This method can be called from anywhere, and it will send the event to any browser client listening appropriately.  This means it can be emitted on model creation, or even from a resque job.

## NoDevent mixin.
To help even further, I've provided the NoDevent::Base module as an include-able thing for models.

```ruby
class SomeModel < ActiveRecord::Base
  include NoDevent::Base

  after_create :nodevent_create
  after_update :nodevent_update

  def as_json(options={})
    super(options).merge(:nodevent => {:room => room, :key => room_key(Time.zone.now + 1.hour)})
  end

end
```

The above example includes NoDevent support directly into a model.

It also provides the following:
* The class's room will be notified of created instances
* Instances will include the room name and key for getting updates
* Updates to a model will notify listeners of the change


When using this you can ask SomeModel for its room name
```ruby
@roomname = SomeMode.first.room
```

or the room key
```ruby
@roomkey = SomeModel.first.room_key(Time.zone.now + 1.hour)
```

or even emit directly to it's room
```ruby
# Emit an arbitrary message to the model instance's room
SomeModel.first.emit('the_event', 'some_message')

# Emit a json-ed version of the model
SomeModel.first.emit('update')
```

## Versioning

I'm using the following versioning scheme:
```
x.y.z
```

A change in the 'x' indictes that there has been a backwards incompatible interface change.  A change in the 'y' indicates some new functionality or significant bug fix, and a change in the 'z' indictes a minor bug fix.  

Don't attempt to get a guage on how mature this system is by the version numbers.  I'm following this pattern so that automatic version matching systems like bundler and npm can update developers' packages and protect against backwards incompatible changes. The rubygem and npm package follow each other in version number on the 'x', and 'y', but not 'z'.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
