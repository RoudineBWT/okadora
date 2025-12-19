[Unit]
Description=Okadora First Boot User Setup
Documentation=https://github.com/RoudineBWT/okadora
ConditionPathExists=!/var/lib/okadora/%u-firstboot-done
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/libexec/okadora-firstboot-setup
ExecStartPost=/usr/bin/mkdir -p /var/lib/okadora
ExecStartPost=/usr/bin/touch /var/lib/okadora/%u-firstboot-done
RemainAfterExit=yes

[Install]
WantedBy=default.target