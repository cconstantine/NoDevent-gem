require 'spec_helper'

describe ::NoDevent::NetPublisher do
  let(:net_publisher) {NoDevent::NetPublisher.new(params)}
  subject { net_publisher }

  pending "a running service" do
    context "without a namespace" do
      let(:params) do
        {
            "spigot.io" => {"api_key" => "f2343b5d54557ee368a37a5d77ccd0c6"}
        }
      end
      it "does something" do
        subject.namespace.should be_present
      end
      context "#publish" do
        subject {net_publisher.publish(net_publisher.namespace, {:room => "the_room", :event => "the_event", :message => "the_message"}.to_json)}
        it {should be_success}
      end
    end
  end
end