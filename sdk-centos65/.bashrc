# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
echo '-------------------------------------'
echo '  Welcome to the Couchbase SDK VM!   '
echo '-------------------------------------'
cat /etc/redhat-release
echo Uptime: `uptime`
echo '-------------------- Versions of things --------------------'
echo '--------------------    libcouchbase    --------------------'
cbc version
echo '--------------------       python       --------------------'
python -V
echo '--------------------        php         --------------------'
php -v
echo '--------------------      pecl(php)     --------------------'
pecl list
echo '--------------------        rpm         --------------------'
rpm -qa | grep couch
echo '------------------------------------------------------------'
echo 'PHPInfo at:  http://localhost:8080/wwwroot/phpinfo.php '
echo '------------------------------------------------------------'

IPADDRESS=`ifconfig | grep "inet addr" | grep -v "127.0.0.1" | cut -f2 -d":" | cut -f1 -d" "`

# Original prompt PS1 was
# [\u@\h \W]\$
PS1="[\u@\h sdk $IPADDRESS]\$ "
