# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"

base_box = "debian/testing64"

empty_disk = '.vagrant/tmp/empty.vdi'
lvm_disk = '.vagrant/tmp/lvm.vdi'
lukspart_disk = '.vagrant/tmp/lukspart.vdi'
luksdev_disk = '.vagrant/tmp/luksdev.vdi'

Vagrant.configure("2") do |config|

  config.vm.define "remote" do |remote|
    remote.vm.box = base_box
    remote.vm.hostname = "bntest1"
    remote.vm.network "private_network", ip: "192.168.181.5"
    remote.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
      locale-gen
      apt-get update
      apt-get install -y borgbackup duplicity rdiff-backup restic rsync
      sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
      echo "Port 22" >> /etc/ssh/sshd_config
      echo "Port 7722" >> /etc/ssh/sshd_config
      systemctl reload sshd
      echo -e "vagrant\nvagrant" | passwd vagrant
      chown vagrant: /var/backups
      wget -q https://github.com/restic/rest-server/releases/download/v0.10.0/rest-server_0.10.0_linux_amd64.tar.gz -O - | tar -xz -C /usr/local/bin --strip-components=1
    SHELL
  end

  config.vm.define "local", primary: true do |local|
    local.vm.box = base_box
    local.vm.hostname = "bntest0"
    local.vm.network "private_network", ip: "192.168.181.4"
    local.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      echo "root: vagrant" >> /etc/aliases
      echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
      locale-gen
      apt-get update
      apt-get install -y automake make dialog sshpass
      BUILDSCRIPT="/usr/local/bin/build-backupninja.sh"
      echo "#!/bin/sh" >> $BUILDSCRIPT
      echo "cd /vagrant" >> $BUILDSCRIPT
      echo "make clean" >> $BUILDSCRIPT
      echo "./autogen.sh" >> $BUILDSCRIPT
      echo "./configure --prefix=/usr --mandir=/usr/share/man --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib --libexecdir=/usr/lib" >> $BUILDSCRIPT
      echo "make" >> $BUILDSCRIPT
      echo "sudo make install" >> $BUILDSCRIPT
      chmod +x $BUILDSCRIPT
      $BUILDSCRIPT
      mkdir -p /root/.ssh
      yes y | ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ''
      echo "StrictHostKeyChecking accept-new" >> /root/.ssh/config
      echo "192.168.181.5 bntest1" >> /etc/hosts
      sshpass -p vagrant scp /root/.ssh/id_ed25519.pub vagrant@bntest1:/tmp/bntest.pub
      sshpass -p vagrant ssh vagrant@bntest1 "cat /tmp/bntest.pub >> /home/vagrant/.ssh/authorized_keys"
      sshpass -p vagrant ssh vagrant@bntest1 "chmod 400 /home/vagrant/.ssh/authorized_keys"
      ssh vagrant@bntest1 "sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
      ssh vagrant@bntest1 "sudo systemctl reload sshd"
    SHELL

    local.vm.provider :virtualbox do |vb|
      unless File.exist?(empty_disk)
        vb.customize ['createhd', '--filename', empty_disk, '--size', 100 ]
      end
      unless File.exist?(empty_disk)
        vb.customize ['createhd', '--filename', lvm_disk, '--size', 100 ]
      end
      unless File.exist?(lukspart_disk)
        vb.customize ['createhd', '--filename', lukspart_disk, '--size', 100 ]
      end
      unless File.exist?(luksdev_disk)
        vb.customize ['createhd', '--filename', luksdev_disk, '--size', 100 ]
      end
      vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', empty_disk]
      vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', lvm_disk]
      vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 3, '--device', 0, '--type', 'hdd', '--medium', lukspart_disk]
      vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 4, '--device', 0, '--type', 'hdd', '--medium', luksdev_disk]
    end
  end

  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: ".git/",
    rsync__args: ["--recursive", "--delete"]

end
