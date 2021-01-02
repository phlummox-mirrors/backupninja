# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"
  config.vm.provision "shell", inline: <<-SHELL
    locale-gen
    apt-get update
    apt-get install -y git automake make
    git clone https://0xacab.org/liberate/backupninja.git
    chown vagrant: backupninja -R
  SHELL
end
