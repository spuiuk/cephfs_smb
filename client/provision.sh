dnf install -y centos-release-ceph-squid.noarch 'dnf-command(config-manager)'
#dnf update -y
dnf install -y glibc-langpack-en iputils iproute iptables vim autofs rsync psmisc wget cifs-utils nfs-utils glibc-all-langpacks
dnf install -y git gdb gcc perl automake autoconf libtool flex bison strace

# Enable EPEL
dnf config-manager --enable crb
dnf install -y epel-release epel-next-release

# Python 3 and dependencies
dnf install -y python3 python3-devel python3-tdb python3-tevent python3-pytest python3-pip python3-cephfs python3-cryptography python3-pyasn1
pip3 install tox pluggy

#Samba devel dependencies
dnf install -y openssl-devel libxml2-devel libaio-devel libibverbs-devel librdmacm-devel readline-devel glib2-devel libacl-devel sqlite-devel fuse3-devel cups-devel dbus-devel docbook-style-xsl libcap-devel libtalloc-devel libtdb-devel libtevent-devel libxslt openldap-devel pam-devel perl-ExtUtils-MakeMaker perl-Parse-Yapp perl-Test-Simple popt-devel gnutls-devel libtirpc libtirpc-devel jansson-devel lvm2-devel userspace-rcu-devel libcmocka-devel libarchive-devel quota-devel libnsl2-devel rpcgen libcephfs-devel

# libldb-devel
cd /etc/yum.repos.d/ && wget https://artifacts.ci.centos.org/samba/pkgs/master/centos/samba-nightly-master.repo
rpm -e --nodeps libldb
dnf install -y samba samba-client samba-client-libs samba-test samba-vfs-cephfs libcephfs-devel

useradd test1; (echo x; echo x)|smbpasswd -a test1
useradd test2; (echo x; echo x)|smbpasswd -a test2
groupadd sg; usermod -G sg test1

mkdir /local; chmod 777 /local

#Mount cephfs-fuse
dnf install -y ceph-fuse
mkdir /mnt-cephfs; chmod 777 /mnt-cephfs

echo -e "StrictHostKeyChecking no\nUpdateHostKeys yes" >> ~/.ssh/config && chmod 600 ~/.ssh/config
rsync -av mycephfs11:/etc/ceph/ /etc/ceph

dnf install -y ceph-common
ceph fs authorize mycephfs client.samba_dev / rw > /tmp/ceph.client.samba_dev.keyring
mv -f /tmp/ceph.client.samba_dev.keyring /etc/ceph/
VOLPATH=`ceph fs subvolume getpath mycephfs smbshares`
cat > /etc/ceph/cephfs-samba.conf <<EOF
[cephfs-vfs]
path = ${VOLPATH}
vfs objects = acl_xattr ceph_new
ceph_new: config_file = /etc/ceph/ceph.conf
ceph_new: user_id = samba_dev
ceph_new:filesystem = mycephfs
browseable = yes
read only = no
acl_xattr:ignore system acls = yes
acl_xattr:security_acl_name = user.NTACL
ceph_new:proxy = no
EOF


