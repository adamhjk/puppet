require 'puppet/type/parsedtype'

module Puppet
    newtype(:mount) do
        # Use the normal parent class, because we actually want to
        # call code when sync() is called.
        newstate(:ensure) do
            desc "Control what to do with this mount. If the value is 
                  ``present``, the mount is entered into the mount table, 
                  but not mounted, if it is ``absent``, the entry is removed 
                  from the mount table and the filesystem is unmounted if 
                  currently mounted, if it is ``mounted``, the filesystem 
                  is entered into the mount table and mounted."

            newvalue(:present) do
                if provider.mounted?
                    provider.unmount
                    return :mount_unmounted
                else
                    provider.create
                    return :mount_created
                end
            end
            aliasvalue :unmounted, :present

            newvalue(:absent, :event => :mount_deleted) do
                if provider.mounted?
                    provider.unmount
                end

                provider.destroy
            end

            newvalue(:mounted, :event => :mount_mounted) do
                # Create the mount point if it does not already exist.
                if self.is == :absent or self.is.nil?
                    provider.create
                end
                # We have to flush any changes to disk.
                @parent.flush

                provider.mount
            end

            defaultto do
                if @parent.managed?
                    :mounted
                else
                    nil
                end
            end

            def retrieve
                if provider.mounted?
                    @is = :mounted
                else
                    @is = super()
                end

            end
        end

        newstate(:device) do
            desc "The device providing the mount.  This can be whatever
                device is supporting by the mount, including network
                devices or devices specified by UUID rather than device
                path, depending on the operating system."
        end

        # Solaris specifies two devices, not just one.
        newstate(:blockdevice) do
            desc "The the device to fsck.  This is state is only valid
                on Solaris, and in most cases will default to the correct
                value."

            # Default to the device but with "dsk" replaced with "rdsk".
            defaultto do
                if Facter["operatingsystem"].value == "Solaris"
                    device = @parent.value(:device)
                    if device =~ %r{/dsk/}
                        device.sub(%r{/dsk/}, "/rdsk/")
                    else
                        nil
                    end
                else
                    nil
                end
            end
        end

        newstate(:fstype) do
            desc "The mount type.  Valid values depend on the
                operating system."
        end

        newstate(:options) do
            desc "Mount options for the mounts, as they would
                appear in the fstab."
        end

        newstate(:pass) do
            desc "The pass in which the mount is checked."
        end

        newstate(:atboot) do
            desc "Whether to mount the mount at boot.  Not all platforms
                support this."
        end

        newstate(:dump) do
            desc "Whether to dump the mount.  Not all platforms
                support this."
        end

        newstate(:target) do
            desc "The file in which to store the mount table.  Only used by
                those providers that write to disk (i.e., not NetInfo)."

            defaultto { if @parent.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
                    @parent.class.defaultprovider.default_target
                else
                    nil
                end
            }
        end

        newparam(:name) do
            desc "The mount path for the mount."

            isnamevar
        end

        newparam(:path) do
            desc "The deprecated name for the mount point.  Please use ``name`` now."

            def should=(value)
                warning "'path' is deprecated for mounts.  Please use 'name'."
                @parent[:name] = value
                super
            end
        end

        @doc = "Manages mounted mounts, including putting mount
            information into the mount table. The actual behavior depends 
            on the value of the 'ensure' parameter."
    end
end

# $Id$