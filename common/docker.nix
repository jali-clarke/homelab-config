{...}: {
  virtualisation.docker.enable = true;
  environment.etc."docker/daemon.json".text = ''
    {
      "insecure-registries": ["docker.lan:5000"],
      "max-concurrent-uploads": 1
    }
  '';
}
