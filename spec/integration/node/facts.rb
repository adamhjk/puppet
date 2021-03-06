#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2008-4-8.
#  Copyright (c) 2008. All rights reserved.

require File.dirname(__FILE__) + '/../../spec_helper'

describe Puppet::Node::Facts do
    describe "when using the indirector" do
        after { Puppet::Node::Facts.indirection.clear_cache }

        it "should expire any cached node instances when it is saved" do
            Puppet::Node::Facts.indirection.stubs(:terminus_class).returns :yaml
            terminus = Puppet::Node::Facts.indirection.terminus(:yaml)

            terminus.expects(:save)
            Puppet::Node.expects(:expire).with("me")

            facts = Puppet::Node::Facts.new("me")
            facts.save
        end

        it "should be able to delegate to the :yaml terminus" do
            Puppet::Node::Facts.indirection.stubs(:terminus_class).returns :yaml

            # Load now, before we stub the exists? method.
            Puppet::Node::Facts.indirection.terminus(:yaml)

            file = File.join(Puppet[:yamldir], "facts", "me.yaml")
            FileTest.expects(:exist?).with(file).returns false

            Puppet::Node::Facts.find("me").should be_nil
        end

        it "should be able to delegate to the :facter terminus" do
            Puppet::Node::Facts.indirection.stubs(:terminus_class).returns :facter

            Facter.expects(:to_hash).returns "facter_hash"
            facts = Puppet::Node::Facts.new("me")
            Puppet::Node::Facts.expects(:new).with("me", "facter_hash").returns facts

            Puppet::Node::Facts.find("me").should equal(facts)
        end
    end
end
