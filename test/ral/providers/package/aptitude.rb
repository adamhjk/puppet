#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../lib/puppettest'

require 'mocha'

class AptitudePackageProviderTest < PuppetTest::TestCase
    confine "Aptitude package provider missing" =>
        Puppet::Type.type(:package).provider(:aptitude).suitable?

	def setup
        super
		@type = Puppet::Type.type(:package)
	end
	
	def test_install
		pkg = @type.create :name => 'faff',
		                   :provider => :aptitude,
		                   :ensure => :present,
		                   :source => "/tmp/faff.deb"

 		pkg.provider.expects(
 		                 :dpkgquery
 					  ).with(
 							  '-W',
 							  '--showformat',
 							  '${Status} ${Package} ${Version}\n',
 							  'faff'
 					  ).returns(
 					        "deinstall ok config-files faff 1.2.3-1\n"
 					  ).times(1)

		pkg.provider.expects(
		                 :aptitude
		           ).with(
		                 '-y',
		                 '-o',
		                 'DPkg::Options::=--force-confold',
		                 :install,
		                 'faff'
					  ).returns(0)
		
		pkg.evaluate.each { |state| 
                    state.transaction = self 
                    state.forward 
          }
	end
	
	def test_purge
		pkg = @type.create :name => 'faff', :provider => :aptitude, :ensure => :purged

		pkg.provider.expects(
		                 :dpkgquery
					  ).with(
					        '-W',
					        '--showformat',
					        '${Status} ${Package} ${Version}\n',
					        'faff'
					  ).returns(
					        "install ok installed faff 1.2.3-1\n"
					  ).times(1)
		pkg.provider.expects(
		                 :aptitude
					  ).with(
					        '-y',
					        'purge',
					        'faff'
					  ).returns(0)
		
		pkg.evaluate.each { |state| state.transaction = self; state.forward }
	end
end
