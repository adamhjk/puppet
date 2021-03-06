#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../lib/puppettest'

require 'puppettest'
require 'mocha'

class TestTypeProviders < Test::Unit::TestCase
	include PuppetTest

    def setup
        super
        @type = Puppet::Type.newtype(:provider_test) do
            newparam(:name) {}
            ensurable
        end
        cleanup { Puppet::Type.rmtype(:provider_test) }
    end

    # Make sure default providers behave correctly
    def test_defaultproviders
        basic = @type.provide(:basic) do
            defaultfor :operatingsystem => :somethingelse,
                :operatingsystemrelease => :yayness
        end

        assert_equal(basic, @type.defaultprovider)
        @type.defaultprovider = nil

        greater = @type.provide(:greater) do
            defaultfor :operatingsystem => Facter.value("operatingsystem")
        end

        assert_equal(greater, @type.defaultprovider)
    end

    # Make sure the provider is always the first parameter created.
    def test_provider_sorting
        should = [:name, :ensure]
        assert_equal(should, @type.allattrs.reject { |p| ! should.include?(p) },
            "Got wrong order of parameters")

        @type.provide(:yay) { }
        should = [:name, :provider, :ensure]
        assert_equal(should, @type.allattrs.reject { |p| ! should.include?(p) },
            "Providify did not reorder parameters")
    end

    # Make sure that provider instances can be passed in directly.
    def test_name_or_provider
        provider = @type.provide(:testing) do
        end

        # first make sure we can pass the name in
        resource = nil
        assert_nothing_raised("Could not create provider instance by name") do
            resource = @type.create :name => "yay", :provider => :testing
        end

        assert_instance_of(provider, resource.provider, "Did not create provider instance")

        # Now make sure we can pass in an instance
        provinst = provider.new(:name => "foo")
        assert_nothing_raised("Could not pass in provider instance") do
            resource = @type.create :name => "foo", :provider => provinst
        end

        assert_equal(provinst, resource.provider, "Did not retain provider instance")
        assert_equal(provider.name, resource[:provider], "Provider value was set to the provider instead of its name")

        # Now make sure unsuitable provider instances still throw errors
        provider = @type.provide(:badprov) do
            confine :exists => "/no/such/file"
        end

        # And make sure the provider must be a valid provider type for this resource
        pkgprov = Puppet::Type.type(:package).create(:name => "yayness").provider
        assert(provider, "did not get package provider")

        assert_raise(Puppet::Error, "Did not fail on invalid provider instance") do
            resource = @type.create :name => "bar", :provider => pkgprov
        end

    end

    # #571 -- so we can cause a provider to become suitable within
    # a run.
    def test_unsuitable_providers_should_not_fail_at_initialization
        Puppet::Type.type(:user).provider(:useradd).stubs(:suitable?).returns false

        assert_nothing_raised("Unsuitable providers failed at initialization") do
            Puppet::Type.type(:user).create :name => "luke", :ensure => :present, :provider => :useradd
        end
    end

    # #571 -- so we can cause a provider to become suitable within
    # a run.
    def test_unsuitable_providers_should_fail_at_evaluation
        Puppet::Type.type(:user).provider(:useradd).stubs(:suitable?).returns false

        user = Puppet::Type.type(:user).create :name => "luke", :ensure => :present, :provider => :useradd
        assert_raise(Puppet::Error, "Unsuitable provider did not fail at evaluation") do
            user.evaluate
        end
    end
end

