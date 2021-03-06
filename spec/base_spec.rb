require 'spec_helper'

module ActiveRecord
  class Base;end
end

class ModelMock < ActiveRecord::Base
  include NoDevent::Base

  attr_accessor :to_param

  def initialize(param)
    @to_param = param
  end
  def to_json(options)
    '{"id":"#{to_param}"}'
  end
end

describe NoDevent do
  describe "#publisher" do
    subject {NoDevent::Emitter.publisher }
    describe "with a redis publisher" do
      before do
        NoDevent::Emitter.config = {
            "host" => "http://thehost",
            "namespace" => "/nodevent",
            "secret" => "asdf",
            "redis" => {"host" => "localhost", "port" => 6379, "db" => 1}
        }
      end
      it { should be_an_instance_of(Redis)}
      it { should_not == $redis}
    end

    describe "without a publisher" do
      before do
        NoDevent::Emitter.config = {
            "host" => "http://thehost",
            "namespace" => "/nodevent",
            "secret" => "asdf"
        }
      end
      it { should be_an_instance_of($redis.class)}
      it { should == $redis}

    end
  end
  describe ".config=" do
    describe "the class" do
      before do
        NoDevent::Emitter.config = {
            "host" => "http://thehost",
            "namespace" => "/nodevent",
            "secret" => "asdf",
            "redis" => {:host => "localhost", :port => 6379, :db => 1}
        }
      end

      it { ModelMock.room.should == "ModelMock" }

      it "should emit to the right room" do
        NoDevent::Emitter.publisher.should_receive(:publish).with("/nodevent",
                                             {
                                               :room => "ModelMock",
                                               :event => 'theevent',
                                               :message => 'themessage'}.to_json)

        ModelMock.emit('theevent', 'themessage')
      end

      it "should create a key from the right room" do
        t = Time.now
        ts = (t.to_f*1000).to_i
        ModelMock.room_key(t).should ==
          (Digest::SHA2.new << "ModelMock" << ts.to_s << NoDevent::Emitter.config["secret"]).to_s + ":" + ts.to_s
      end

      describe "with a custom room name" do
        before  do
          ModelMock.stub(:room => "otherRoom")
        end

        it { ModelMock.room.should == "otherRoom" }

        it "should emit to the right room" do
          NoDevent::Emitter.publisher.should_receive(:publish).with("/nodevent",
                                               {
                                                 :room => "otherRoom",
                                                 :event => 'theevent',
                                                 :message => 'themessage'}.to_json)

          ModelMock.emit('theevent', 'themessage')
        end

        it "should create a key from the right room" do
          t = Time.now
          ts = (t.to_f*1000).to_i
          ModelMock.room_key(t).should ==
            (Digest::SHA2.new << ModelMock.room << ts.to_s << NoDevent::Emitter.config["secret"]).to_s + ":" + ts.to_s
        end
      end
    end

    describe "an instance of the class" do
      before do
        NoDevent::Emitter.config = {
            "host" => "http://thehost",
            "namespace" => "/nodevent",
            "secret" => "asdf",
            "redis" => {:host => "localhost", :port => 6379, :db => 1}
        }
      end
      let(:instance) {ModelMock.new( 'theparam') }

      describe "#room_json" do
        before { Time.stub(:now => Time.new(2011, 1, 10))}
        subject {instance.room_json(2 * NoDevent::HOUR)}
        it "should have both the room name and the key" do
          subject.keys.should =~ [:room, :key]
          subject[:key].should == instance.room_key(Time.now + 2*NoDevent::HOUR)
          subject[:room].should == instance.room
        end
      end

      it { instance.room.should == "ModelMock_theparam" }
      it "should emit to the right room" do
        NoDevent::Emitter.publisher.should_receive(:publish).with("/nodevent",
                                             {
                                               :room => "ModelMock_theparam",
                                               :event => 'theevent',
                                               :message => 'themessage'}.to_json)

        instance.emit('theevent', 'themessage')
      end

      describe "#nodevent_create" do
        it "should emit to the right room" do
        NoDevent::Emitter.publisher.should_receive(:publish).with("/nodevent",
                                             {
                                               :room => "ModelMock",
                                               :event => 'create',
                                               :message => instance}.to_json)
          instance.nodevent_create

        end
      end
      describe "#nodevent_update" do
        it "should emit to the right room" do
        NoDevent::Emitter.publisher.should_receive(:publish).with("/nodevent",
                                             {
                                               :room => "ModelMock_theparam",
                                               :event => 'update',
                                               :message => instance}.to_json)
          instance.nodevent_update

        end
      end

      it "should create a key from the right room" do
        t = Time.now
        ts = (t.to_f*1000).to_i
        instance.room_key(t).should ==
          (Digest::SHA2.new << instance.room << ts.to_s << NoDevent::Emitter.config["secret"]).to_s + ":" + ts.to_s
      end

      describe "with a custom room name" do
        before  do
          instance.stub(:room => "otherRoom")
        end

        it { instance.room.should == "otherRoom" }

        it "should emit to the right room" do
          NoDevent::Emitter.publisher.should_receive(:publish).with("/nodevent",
                                               {
                                                 :room => "otherRoom",
                                                 :event => 'theevent',
                                                 :message => 'themessage'}.to_json)

          instance.emit('theevent', 'themessage')
        end

        it "should create a key from the right room" do
          t = Time.now
          ts = (t.to_f*1000).to_i
          instance.room_key(t).should ==
            (Digest::SHA2.new << "otherRoom" << ts.to_s << NoDevent::Emitter.config["secret"]).to_s + ":" + ts.to_s
        end
        describe "#nodevent_create" do
          it "should emit to the right room" do
            NoDevent::Emitter.publisher.should_receive(:publish).with("/nodevent",
                                                 {
                                                   :room => instance.class.room,
                                                   :event => 'create',
                                                   :message => instance}.to_json)
            instance.nodevent_create

          end
        end
        describe "#nodevent_update" do
          it "should emit to the right room" do
            NoDevent::Emitter.publisher.should_receive(:publish).with("/nodevent",
                                                 {
                                                   :room => instance.room,
                                                   :event => 'update',
                                                   :message => instance}.to_json)
            instance.nodevent_update

          end
        end
      end
    end
  end
end