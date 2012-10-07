
module NoDevent
  class NetPublisher
    include HTTParty

    # HTTParty settings
    headers  'ContentType' => 'application/json' ,'Accept' => 'application/json'

    format :json
    default_timeout 5

    HOSTNAME="spigot.io"

    attr_accessor :namespace
    attr_accessor :secret
    attr_accessor :api_key

    def initialize(opts)
      self.api_key = opts["spigot.io"]["api_key"]
      self.namespace = opts["namespace"]
      self.secret = opts["secret"]

      unless self.namespace
        body = generate_namespace.body
        resp = JSON.parse body
        self.namespace = "/" + resp["id"]
        self.secret = resp["secret"]
      end
    end

    def publish(where, message)
      message = JSON.parse(message)
      req = {
          :body => {
              :api_key => api_key,
              :event   => message["event"],
              :room    => message["room"],
              :message => message["message"]
          }
      }
      self.class.post("http://#{HOSTNAME}/namespaces#{where}/emit",req)

    end

    def generate_namespace
      require "socket"
      hostname = Socket.gethostname
      suffix = " (#{Rails.env})" if defined?(Rails)
      req = {
              :body => {
                  :api_key   => api_key,
                  :namespace => {"name" => "#{hostname}#{suffix}"}
              }
            }
      self.class.post("http://#{HOSTNAME}/namespaces",req)
    end
  end
end