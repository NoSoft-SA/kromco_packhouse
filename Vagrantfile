Vagrant.configure("2") do |config|
  # Base box provisioning:
  # config.vm.box = "hashicorp/precise64"
  # config.vm.network :forwarded_port, guest: 3000, host: 3030
  # config.vm.provision :shell, path: "vagrant_bootstrap12.sh"

  # Ruby 1.8.7 & Rails 1.2.3 with applicable gems:
  config.vm.box = "nosoft_ruby18.box"
  config.vm.network :forwarded_port, guest: 3000, host: 3030
end
