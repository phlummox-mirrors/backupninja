# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"
empty_disk = '.vagrant/tmp/empty.vdi'
lvm_disk = '.vagrant/tmp/lvm.vdi'
luks_disk = '.vagrant/tmp/luks.vdi'

Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"
  config.vm.provision "shell", inline: <<-SHELL
    locale-gen
    apt-get update
    apt-get install -y automake make dialog
    cd /vagrant
    ./autogen.sh
    ./configure --prefix=/usr --mandir=/usr/share/man --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib --libexecdir=/usr/lib
    make
    make install
  SHELL
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: ".git/",
    rsync__args: ["--recursive", "--delete"]
  config.vm.hostname = "bntest0"

  config.vm.provider :virtualbox do |vb|
    unless File.exist?(empty_disk)
      vb.customize ['createhd', '--filename', empty_disk, '--size', 100 ]
    end
    unless File.exist?(empty_disk)
      vb.customize ['createhd', '--filename', lvm_disk, '--size', 100 ]
    end
    unless File.exist?(luks_disk)
      vb.customize ['createhd', '--filename', luks_disk, '--size', 100 ]
    end
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', empty_disk]
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', lvm_disk]
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 3, '--device', 0, '--type', 'hdd', '--medium', luks_disk]
  end

end
