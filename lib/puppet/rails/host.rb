require 'puppet/rails/rails_object'

#RailsObject = Puppet::Rails::RailsObject
class Puppet::Rails::Host < ActiveRecord::Base
    serialize :facts, Hash
    serialize :classes, Array

    has_many :rails_objects, :dependent => :delete_all

    # If the host already exists, get rid of its objects
    def self.clean(host)
        if obj = self.find_by_name(host)
            obj.rails_objects.clear
            return obj
        else
            return nil
        end
    end

    # Store our host in the database.
    def self.store(hash)
        name = hash[:host] || "localhost"
        ip = hash[:ip] || "127.0.0.1"
        facts = hash[:facts] || {}
        objects = hash[:objects]

        unless objects
            raise ArgumentError, "You must pass objects"
        end

        hostargs = {
            :name => name,
            :ip => ip,
            :facts => facts,
            :classes => objects.classes
        }

        objects = objects.flatten

        host = nil
        if host = clean(name)
            [:name, :facts, :classes].each do |param|
                unless host[param] == hostargs[param]
                    host[param] = hostargs[param]
                end
            end
            host.addobjects(objects)
        else
            host = self.new(hostargs) do |hostobj|
                hostobj.addobjects(objects)
            end
        end


        host.save

        return host
    end

    # Add all of our RailsObjects
    def addobjects(objects)
        objects.each do |tobj|
            params = {}
            tobj.each do |p,v| params[p] = v end

            args = {:ptype => tobj.type, :name => tobj.name}
            [:tags, :file, :line].each do |param|
                if val = tobj.send(param)
                    args[param] = val
                end
            end

            robj = rails_objects.build(args)

            robj.addparams(params)
            if tobj.collectable
                robj.toggle(:collectable)
            end
        end
    end
end

# $Id$