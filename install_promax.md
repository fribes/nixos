
## Switch to unstable channel to have a rolling release
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nixos-rebuild switch --upgrade
reboot

## Import personal configuration
nix-shell -p git meld
git clone https://github.com/fribes/nixos
cd nixos/

cp /etc/nixos/configuration.nix default_configuration.nix

#fusion de config par defaut plutot que copie ( cas de grub vs systemboot)
meld default_configuration.nix promax_configuration.nix

### test build
nixos-rebuild build -I nixos-config=promax_configuration.nix 

### Install
ln -sf /home/fribes/nixos/promax_configuration.nix /etc/nixos/configuration.nix 
nixos-rebuild switch
reboot

## Import dotfiles

cd dotfiles/
stow . -t ~

## Copy secrets
ux501> tar czf /removable media/secrets.tgz .ssh .gnupg

promax> tar xzf /removable media/secrets.tgz
promax> shred -u /removable media/secrets.tgz


promax> scp -r ux501.local:Documents/Keepass .

## Copy Sublime Text confdguration

fribes in 🌐 ux501 in ~ 
❯ tar czf subl.tgz .config/sublime-text/Packages/User

fribes in promax in ~
❯ scp 192.168.1.85:subl.tgz .
subl.tgz                                                                                                                                                                                                                                                                                    100%  450KB   7.8MB/s   00:00    

❯ tar xzf subl.tgz 

