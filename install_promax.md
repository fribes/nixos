nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nixos-rebuild switch --upgrade
reboot


cat /etc/nixos/configuration.nix 
nix-shell -p git
git clone https://github.com/fribes/nixos
cd nixos/
git mv configuration.nix z400_configuration.nix
cp /etc/nixos/configuration.nix promax_configuration.nix
nix-shell -p meld

#fusion de config par defaut plutot que copie ( cas de grub vs systemboot)
meld z400_configuration.nix promax_configuration.nix 
cd dotfiles/
stow . -t ~

nixos-rebuild build -I nixos-config=promax_configuration.nix 
ln -sf /home/fribes/nixos/promax_configuration.nix /etc/nixos/configuration.nix 
nixos-rebuild switch
reboot


ux501> tar czf /removable media/secrets.tgz .ssh .gnupg

promax> tar xzf /removable media/secrets.tgz
promaw> shred -u /removable media/secrets.tgz
