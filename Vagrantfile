# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require './lib/gen_node_infos'
require './lib/predicates'

def is_plugin(name)
  if Vagrant.has_plugin?(name)
    puts "using #{name}"
  else
    puts "please run vagrant plugin install #{name}"
    exit(1)
  end
end
base_dir = File.expand_path(File.dirname(__FILE__))
conf = YAML.load_file(File.join(base_dir, "cluster.yml"))
ninfos = gen_node_infos(conf)
master_ip = "master_ip"

## vagrant plugins required:
# vagrant-aws, vagrant-berkshelf, vagrant-omnibus, vagrant-hosts, vagrant-cachier
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  master_ip = ninfos[:master][0][:ip]
  
  [ninfos[:master], ninfos[:slave]].flatten.each_with_index do |ninfo, i|
    config.vm.define ninfo[:hostname] do |cfg|

    cfg.vm.provider :virtualbox do |vb, override|
        override.vm.hostname = ninfo[:hostname]
        override.vm.network :private_network, :ip => ninfo[:ip]
        override.vm.provision :hosts

        vb.name = 'vagrant-mesos-' + ninfo[:hostname]
        vb.customize ["modifyvm", :id, "--memory", ninfo[:mem], "--cpus", ninfo[:cpus] ]

        if master?(ninfo[:hostname]) then
          override.vm.provision "shell", inline: <<-SHELL
            sudo rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm
            sudo yum -y install mesosphere-zookeeper
            sudo yum -y install mesos
            sudo yum -y install marathon
            sudo yum -y install chronos
            echo "1" > /var/lib/zookeeper/myid
            sudo bash
            master_ip = `ip address`
            echo 'MARATHON_MASTER="zk://${ninfo[:ip]}:2181/mesos"' >> /etc/default/marathon
            echo 'MARATHON_ZK="zk://${ninfo[:ip]}:2181/marathon"' >> /etc/default/marathon
            echo 'MARATHON_MESOS_USER="root"' >> /etc/default/marathon
            systemctl start zookeeper
            systemctl start mesos-master
            systemctl start marathon
            systemctl start chronos
            systemctl stop  mesos-slave
            systemctl disable  mesos-slave
            SHELL
        end

        if slave?(ninfo[:hostname]) then
          override.vm.provision "shell", inline: <<-SHELL
            sudo rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm
            sudo yum -y install mesos
            sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
			[dockerrepo]
			name=Docker Repository
			baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
			enabled=1
			gpgcheck=1
			gpgkey=https://yum.dockerproject.org/gpg
			EOF
            sudo yum -y install docker-engine
            echo 'docker,mesos' > /etc/mesos-slave/containerizers
            echo "zk://#{master_ip}:2181/mesos" > /etc/mesos/zk
            sudo bash
            systemctl stop  mesos-master
            systemctl disable  mesos-master
            systemctl start docker
            systemctl start mesos-slave
            SHELL
        end
      end
    end
  end
end
 
