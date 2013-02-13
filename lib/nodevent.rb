require 'digest/sha2'
require 'json'
require 'redis'

module NoDevent
  HOUR = 60 * 60

  def self.included(base)
    raise "No longer supported, Please include NoDevent::Base instead"
  end
  module Base
    def self.included(base)
      base.extend(NoDevent::Base)
    end
    
    class << self
      def emit(name, message)
        NoDevent::Emitter.emit(self.room, name, message)
      end
      def room(obj)
        NoDevent::Emitter.room(self)
      end
      def room_key(expires)
        Emitter.room_key(self.room, expires)
      end
    end

    def emit(name, message=nil)
      Emitter.emit(self.room, name, message || self)
    end
    
    def room
      Emitter.room(self)
    end
    
    def room_key(expires)
      Emitter.room_key(self.room, expires)
    end

    def room_json(expires_after=HOUR)
      {room: room, key: room_key(Time.now + expires_after)}
    end

    def nodevent_create
      NoDevent::Emitter.emit(self.class.name, 'create', self)
    end
    
    def nodevent_update
      self.emit('update')
    end
  
  end
    

  module Helper
    def nodevent_url
      host = NoDevent::Emitter.config['host']
      namespace = NoDevent::Emitter.config['namespace']
      namespace = '/' + namespace unless namespace[0] == '/'
      "#{host}/api#{namespace}"
    end
    def javascript_include_nodevent
      "<script src='#{nodevent_url}' type='text/javascript'></script>".html_safe
    end
  end
  ActionView::Base.send :include, Helper if defined?(ActionView::Base)

  module Emitter
    class << self
      def config= obj
        @@config = nil
        @@publisher = nil
        @@config = config.merge(obj)
        if @@config.keys.include?("redis")
          r_config = @@config["redis"]

          @@publisher = Redis.new(:host => r_config["host"], :port => r_config["port"], :db => r_config["db"])
        end
      end

      def config
        @@config ||= Hash.new({
                                "host" => "http://localhost:8080",
                                "namespace" => "/nodevent"
                              })
        @@config
      end

      def publisher
        @@publisher || $redis
      end

      def emit(room, name, message)
        room = NoDevent::Emitter.room(room)
        publisher.publish(config["namespace"],
                       { :room => room,
                         :event => name, 
                         :message => message}.to_json)
      end
      
      def room(obj)
        obj = "#{obj.class}_#{obj.to_param}" if (defined?(ActiveRecord::Base) && 
                                           obj.is_a?(ActiveRecord::Base))
        obj = "#{obj.name}" if (obj.class == Class || obj.class == Module)
        obj
      end

      def room_key(obj, expires)
        r = room(obj)
        ts = (expires.to_f*1000).to_i
        hash = (Digest::SHA2.new << r << ts.to_s<< config["secret"]).to_s
        "#{hash}:#{ts}"
      end
    end
  end
end
