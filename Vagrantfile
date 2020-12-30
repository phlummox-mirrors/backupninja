# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"

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
    rsync__args: ["--delete"]
  config.vm.hostname = "bntest0"
end
