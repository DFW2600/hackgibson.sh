cd /tmp

apt install -y tor haproxy unrar-free unzip zip

fu=$(mktemp -d)
curl http://www.mysticbbs.com/downloads/mys112a46_l64.rar -sSlk -o ${fu}/mystic.rar
unrar mystic.rar
sudo ./install auto /mystic
sudo mkdir /mystic/tempmis/
rm -rf ${fu}

cat ->> /etc/haproxy/haproxy.conf << EOL

frontend sh.hackgibson.hidden-web
        bind 0.0.0.0:80
        mode http
        monitor-uri /
        errorfile 200 /etc/haproxy/errors/400.http

frontend sh.hackgibson.hidden-binkd
        bind 0.0.0.0:24554
        mode tcp
        use_backend binkd

frontend sh.hackgibson.hidden-console
        bind 0.0.0.0:23
        mode tcp
        use_backend console

backend console
        balance static-rr
        server z1-r124-n5017-p0 127.0.0.1:23

backend binkd
        balance static-rr
        server z1-r124-n5017-p0 127.0.0.1:24554
EOL

cat -> /etc/tor/torrc|tee << EOL
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServiceVersion 3
HiddenServicePort 23 127.0.0.1:23
HiddenServicePort 80 127.0.0.1:80
HiddenServicePort 24554 127.0.0.1:24554
EOL

systemctl enable --now tor haproxy

echo "127.0.0.10  $(cat /var/lib/tor/hidden_service/hostname)" | tee -a /etc/hosts

function mbbs_systemd() {
  daemon=$1
  endpoint=$2
  
  fu=$(mktemp -d)
  zipfile=${fu}/$(basename "${endpoint}")
  basedir=$(echo ${zipfile} | sed 's/.zip//')
  baseurl=https://vswitchzero.files.wordpress.com

  curl -sSlk /$endpoint -o ${zipfile}
  unzip ${zipfile} -d "${fu}"
  
  install -m 0755 ${basedir}/${daemon}-{start,stop}.sh /mystic
  install ${basedir}/${daemon}.service /lib/systemd/system/${fu}.service
  systemd enable ${daemon}

  rm -rf $fu
}

mbbs_systemd "mis" "2019/09/mystic-systemd.zip"
#mbbs_systemd "mrc" "2020/11/mrc-systemd.zip"
