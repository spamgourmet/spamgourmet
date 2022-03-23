# spamgourmet-clone
These are instructions and a helper script to clone the spamgourmet website

Everything below is built on the shoulders of:
1. **Josh Parris** [see here](https://bbs.spamgourmet.com/viewtopic.php?f=2&t=1703)
1. **cgz** [see here](https://bbs.spamgourmet.com/viewtopic.php?f=2&t=1356)
1. **cndpost** [see here](https://bbs.spamgourmet.com/viewtopic.php?f=2&t=1298)

I and you owe them many thanks.

NB. This is very brittle, the script does absolutely no error checking.

NB. Although Spamgourmet runs on **apache**, because I wanted my clone to use as few resources as possible, I replaced it with **lighttpd** in this install script.

**You WILL have problems running it :-)** if you do not follow the instructions to the letter (and probably even if you do).

## Prerequisites
Before you attempt to run this script **from a root shell on the target host** you should:
1. have a default Debian install on a machine you control
1. ensure you can ssh as root with no password to your host (i.e. with a ssh key)
1. ensure you can set up LetsEncrypt for your domain, and reach a state where the certificate renewal actually renews your certificates by simply running `cd /var/lib/dehydrated; dehydrated -c`.
1. have asked your hosting provider to set up reverse DNS (**rDNS**) to resolve to your *example.com* (replace this with your own domain), and ensured that they did it by running `host ip.addr.of.host`.
1. have configured your *example.com*  and a subdomain called *ob.example.com* with the following zone records:
    1. **A** record for *example.com* pointing to your host running the clone
    1. **A** record for *ob.example.com* pointing to your host running the clone
    1. **MX** record for *example.com* pointing to *example.com*
    1. **MX** record for *ob.example.com* pointing to *example.com*
    1. **DMARC** and **DKIM** for *example.com* set up as instructed [here](https://www.geekrant.org/2017/04/25/trustworthy-email-authentication-using-exim4-spf-dkim-and-dmarc/).
1. have recursively copied the `dehydrated` folder (including its subdirectories `accounts`, `certs` and `chains` in the same folder as the one where you copied `remote-install.sh` (normally in `/root`)
1. have copied the `dkim.private` and `dkim.public` keys generated for the **DKIM** DNS records next to the `remote-install.sh`
1. make sure you have a large enough scrollback buffer for your terminal to not lose any output
## HowTo
The LetsEncrypt configuration is quite OVH specific. If you are running in OVH you can run the install command as `SETUP_LETSENCRYPTOVH=true remote-install.sh` - otherwise you are on your own with the configuration.

Just ssh as root (passwordless please) to the target host and run the `remote-install.sh` script (with OVH setup as above if you want). Then closely scrutinize the output for any errors.

At the end you should hopefully have a working clone of spamgourmet.com

This is out of scope but do not forget to ensure that you have a proper firewall on the host, and that you set up regular backups.

FYI my private spamgourmet clone runs very well on a KVM VM with 1vCPU, 512MB RAM and 7GB disk (1.51GB used at the end of the script). The VM runs Debian 10.10 on **zfs** root.
