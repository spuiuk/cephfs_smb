cat <<EOF
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

