# SSH ideal setup for WSL and Ubuntu OS

Once this is done, you should be able to use SSH profiles and keys to connect
to SSH servers with much more ease and even better security. No passwords,
no typing IP addresses or ports. It is as simple as typing a name:

`ssh devserver`

The Ubuntu OS setup also works headlessly. There are additional Windows 10/11
SSH instructions at the bottom, but they are old and probably unfinished.

## Directory Structure (WSL/Ubuntu OS)

Directory structure:

```text
~/.ssh/
├── config                 # The master connection profile configuration
├── authorized_keys        # Keys allowed to connect to this machine
└── keys/                  # Subdirectory to keep your root ~/.ssh clean
    ├── id_ed25519_personal
    ├── id_ed25519_work
    └── id_ed25519_wsl
```

Secure these directories like this:

```bash
chmod 700 ~/.ssh && chmod 700 ~/.ssh/keys && chmod 600 ~/.ssh/authorized_keys
```

If you see `known_hosts` or `known_hosts.old`, don't delete these. These
store known SSH clients.

## Client (WSL/Ubuntu OS)

First, you will generate a named key for the specific server(s) you want to
connect to:

```bash
ssh-keygen -t ed25519 -f "$HOME/.ssh/keys/custom_key_name
```

And then type your passphrase. The passphrase exists to prevent someone
with access to your local machine from getting free access to your SSH servers.
You will occasionally have to type this, so remember it.

If you will be generating lots of keys, you can add this to your ~/.bash_aliases:

```bash
# Use like this `key-gen devserver`
keygen () {
    ssh-keygen -t ed25519 -f "$HOME/.ssh/keys/$1"
}
```

If you need to set up the SSH server you want to connect to, now is the
time to do it (jump to server instructions below).

From here, you will need to copy the public key (with the .pub) to the server
somehow. Try using ssh-copy-id for this. If the server uses something
other than port 22, such as our WSL setup, specify with -p port after the
key file.

```bash
ssh-copy-id -i ~/.ssh/keys/custom_key_name username@ip_address
```

By default, ssh-agent forgets your keys when you close your terminal or
log out, **forcing you to re-type passphrases constantly**. Keychain (developed
by Funtoo) acts as a manager that hooks into your shell configuration. It
ensures only one agent runs globally per system boot, persisting across
all terminal tabs and multiplexers (like tmux).

Install keychain:

```bash
sudo apt install keychain -y
```

Add this to your ~/.bashrc:

```bash
eval $(keychain --eval --agents ssh)
```

Setup your config file (see example config). This file should be named `config`
and sit directly in your ~/.ssh directory. With the right config, keychain
should know exactly what profiles and keys to use.

### Git SSH signing

You can use SSH to sign your commits, this will add the "Verified" sticker.
Go to `https://github.com/settings/keys`. Select "Signing key". Paste your
public key. Add it. In your bash terminal, enter this.

`git config --global user.signingkey /path/to/public_key`

Now we need to ensure Git knows to use SSH formatting.

`git config --global gpg.format ssh`

Optional: Enable auto-signing for all commits. (Otherwise you will have
to pass the -S flag every time)

`git config --global commit.gpgsign true`

Now we need to add the allowed_signers file (assuming your user.email is already set).

`echo "$(git config user.email) $(cat /path/to/public_key)" >> ~/.ssh/allowed_signers`

And point Git to the file.

`git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers`

To test if it works, make a test commit, and then run this:

`git log --show-signature -n 1`

You should see an output containing `Good "ssh" signature`.

## Server (WSL/Ubuntu)

Install OpenSSH server

```bash
sudo apt update
sudo apt install openssh-server -y
```

Edit the sshd_config

```bash
sudo vim /etc/ssh/sshd_config
```

Find, uncomment (remove the existing #), and update the following lines

```ini
Port 22                     # For WSL, change this to 2222
ListenAddress 0.0.0.0       # Allows connections from any network interface
PasswordAuthentication yes  # Set to no if you prefer to rely solely on SSH keys
PubkeyAuthentication yes    # Allows SSH key access
PermitRootLogin no          # For security, disallow direct root access
```

All WSL instructions will use port 2222. This prevents any conflict with
an SSH server on the Windows host machine.

### For Ubuntu (or similar) OS

Start and enable the SSH service so it runs automatically:

```bash
sudo systemctl enable ssh --now
```

Check if it is running:

```bash
sudo systemctl status ssh
```

Test the connection from another device and type the user password:

`ssh username@your_ip_address`

Boom, you're done!

### For WSL

Edit wsl.conf:

```bash
sudo vim /etc/wsl.conf
```

Add the following; this will ensure systemd manages your SSH agent:

```ini
[boot]
systemd=true
```

Save and close, restart wsl from powershell: `wsl --shutdown`, `wsl`

Start and enable the SSH service so it runs automatically:

```bash
sudo systemctl enable ssh --now
```

Check if it is running:

```bash
sudo systemctl status ssh
```

Test the connection to localhost from a separate powershell terminal:

```powershell
ssh username@localhost -p 2222
```

From an external machine on the same network: If you want to connect from
a separate computer, the easiest method on modern WSL2 is to enable Mirrored
Networking Mode, which shares the Windows host IP directly with WSL.

1. In Windows, open your user profile folder (e.g., C:\Users\\\<YourUsername>\).
2. Create or edit a file named .wslconfig and add the following lines

```ini
[wsl2]
networkingMode=mirrored
```

From here you will need to allow port 2222 through the Windows firewall
and setup a port proxy, but first you will need the WSL's IP address. You can
find this easily with `ipconfig`. Look for something like "Ethernet adapter
vEthernet (WSL (Hyper-V firewall)):" and you should find the IPv4 there.
Boot up Powershell as an admin and run these (replace your_wsl_ipv4):

```powsershell
netsh int portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=2222 connectaddress=your_wsl_ipv4
nstsh int show all
```

Create the inbound firewall rule:

```powershell
New-NetFirewallRule -Name "SSH-WSL" -DisplayName "SSH WSL" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2222
```

Restart WSL with `wsl --shutdown`, `wsl`, and test the external connection:

```powershell
ssh username@your_wsl_ipv4 -p 2222
```

Congrats! You can now connect to your WSL terminal on the same network.
Jump to the client setup for profiles/keys

## Client (Windows 10/11)

Go to: Settings > System > Optional Features > View Features

- Enable Open SSH Client
- Make sure ssh-agent is running and auto, see services.msc
- Generate keys ($HOME surprisingly works on Powershell)
- `ssh-keygen -t ed25519 -f "$HOME\.ssh\keys\id_ed25519_hostname"`
- Add passphrase
- the `config` file will add the key to the agent after the passphrase, preventing
future prompting, see `config` example file (same as Ubuntu setup)
- Add key to local config file
- Copy pubkey to server (many ways of doing this, make sure it's secure)
- Run `ssh <profile>` to automatically add the key to the agent and connect

## Server (Windows 10/11)

Add pubkeys to `%USERPROFILE%\.ssh\authorized_keys`

Go to `C:\ProgramData\ssh\sshd_config` and comment out the last two lines.
This prevents admins from needing an entirely separate file for keys.

Make sure sshd is running and auto on the server

```powershell
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd
gsv sshd | Format-List
```
