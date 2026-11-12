Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  # Nginx is served at http://localhost:8081 on the Windows host.
  config.vm.network "forwarded_port", guest: 80, host: 8081, host_ip: "127.0.0.1"

  config.vm.provider "vmware_desktop" do |vmware|
    vmware.gui = false
    vmware.memory = 2048
    vmware.cpus = 2
  end
end
