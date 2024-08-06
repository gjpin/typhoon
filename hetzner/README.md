diff:
- hetzner only supports ipv4 network: https://docs.hetzner.cloud/#networks-create-a-network
- firewall (network.tf) based on azure security.tf

order used to add hetzner support:
- network
- firewall
- zone
- controllers
- workers
- bootstrap