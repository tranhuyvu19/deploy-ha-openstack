#!/bin/sh

yum -y install aide

##set password bootloader
##use command 
#echo "cat <<EOF" >> /etc/grub.d/10_linux
#echo 'set superusers="vuth6"' >> /etc/grub.d/10_linux
#echo "Password_pbkdf2 vuth6 grub.pbkdf2.sha512.10000.A07F553D0CF72B29F8E116947E465161291FBB99C6A5C835CCC39E319A34B4207EF862372089D5B11CD4D4A01479C67997DA54D6618D2FACA3DE689836922704.78CA7729BA10207FCBA82484B412404E1A02650F16AF4107FE587C8A4DB0341CFCC9EE969202EA997F579CF2D8FE89C832C9E69D01CDE04D4DE62145D8B0584D" >> /etc/grub.d/10_linux
#echo "EOF" >> /etc/grub.d/10_linux


#set gpg check each repository 
for i in `find  /etc/yum.repos.d/ -type f`
do
sed -i 's!^.gpgcheck=.*!gpgcheck=1!g' $i
done


#Remove write permission all lib file
DIRS="/lib /lib64 /usr/lib /usr/lib64"

for dirPath in $DIRS
do
find $dirPath -perm /022 -type f -exec chmod go-w '{}' \;
find $dirPath -perm /022 -type d -exec chmod go-w '{}' \;
done

#set minlen password
sed -i 's/\<nullok\>//g' /etc/pam.d/system-auth


var_accounts_password_minlen_login_defs="14"

grep -q ^PASS_MIN_LEN /etc/login.defs && sed -i "s/PASS_MIN_LEN.*/PASS_MIN_LEN $var_accounts_password_minlen_login_defs/g" /etc/login.defs

if ! [ $? -eq 0 ]; then

echo "PASS_MIN_LEN $var_accounts_password_minlen_login_defs" >> /etc/login.defs

fi

#set account minium age
var_accounts_minimum_age_login_defs="7"

grep -q ^PASS_MIN_DAYS /etc/login.defs && sed -i "s/PASS_MIN_DAYS.*/PASS_MIN_DAYS $var_accounts_minimum_age_login_defs/g" /etc/login.defs

if ! [ $? -eq 0 ]; then

echo "PASS_MIN_DAYS $var_accounts_minimum_age_login_defs" >> /etc/login.defs

fi

#set retry password
var_password_pam_retry="3"
if grep -q "retry=" /etc/pam.d/system-auth
then

sed -i --follow-symlink "s/\(retry *= *\).*/\1$var_password_pam_retry/" /etc/pam.d/system-auth

else

sed -i --follow-symlink "/pam_pwquality.so/ s/$/ retry=$var_password_pam_retry/" /etc/pam.d/system-auth

fi


var_password_pam_dcredit="-1"

if egrep -q ^dcredit[[:space:]]*=[[:space:]]*[-]?[[:digit:]]+ /etc/security/pwquality.conf
then

sed -i "s/^\(dcredit *= *\).*/\1$var_password_pam_dcredit/" /etc/security/pwquality.conf

else

sed -i "/\(dcredit *= *\).*/a dcredit = $var_password_pam_dcredit" /etc/security/pwquality.conf

fi


var_password_pam_ucredit="-2"

if egrep -q ^ucredit[[:space:]]*=[[:space:]]*[-]?[[:digit:]]+ /etc/security/pwquality.conf
then

sed -i "s/^\(ucredit *= *\).*/\1$var_password_pam_ucredit/" /etc/security/pwquality.conf

else

sed -i "/\(ucredit *= *\).*/a ucredit = $var_password_pam_ucredit" /etc/security/pwquality.conf

fi


var_password_pam_ocredit="-2"

if egrep -q ^ocredit[[:space:]]*=[[:space:]]*[-]?[[:digit:]]+ /etc/security/pwquality.conf
then

sed -i "s/^\(ocredit *= *\).*/\1$var_password_pam_ocredit/" /etc/security/pwquality.conf

else

sed -i "/\(ocredit *= *\).*/a ocredit = $var_password_pam_ocredit" /etc/security/pwquality.conf

fi

var_password_pam_lcredit="-2"

if egrep -q ^lcredit[[:space:]]*=[[:space:]]*[-]?[[:digit:]]+ /etc/security/pwquality.conf
then

sed -i "s/^\(lcredit *= *\).*/\1$var_password_pam_lcredit/" /etc/security/pwquality.conf

else

sed -i "/\(lcredit *= *\).*/a lcredit = $var_password_pam_lcredit" /etc/security/pwquality.conf

fi


var_password_pam_difok="4"

if egrep -q ^difok[[:space:]]*=[[:space:]]*[-]?[[:digit:]]+ /etc/security/pwquality.conf
then

sed -i "s/^\(difok *= *\).*/\1$var_password_pam_difok/" /etc/security/pwquality.conf

else

sed -i "/\(difok *= *\).*/a difok = $var_password_pam_difok" /etc/security/pwquality.conf

fi



var_accounts_passwords_pam_faillock_deny="5"

AUTH_FILES[0]="/etc/pam.d/system-auth"

AUTH_FILES[1]="/etc/pam.d/password-auth"

for pamFile in "${AUTH_FILES[@]}"

do

# pam_faillock.so already present?

    if grep -q "^auth.*pam_faillock.so.*" $pamFile; then

# pam_faillock.so present, deny directive present?

		if grep -q "^auth.*[default=die].*pam_faillock.so.*authfail.*deny=" $pamFile; then

# both pam_faillock.so & deny present, just correct deny directive value

			sed -i --follow-symlink "s/\(^auth.*required.*pam_faillock.so.*preauth.*silent.*\)\(deny *= *\).*/\1\2$var_accounts_passwords_pam_faillock_deny/" $pamFile
			sed -i --follow-symlink "s/\(^auth.*[default=die].*pam_faillock.so.*authfail.*\)\(deny *= *\).*/\1\2$var_accounts_passwords_pam_faillock_deny/" $pamFile
# pam_faillock.so present, but deny directive not yet

		else

# append correct deny value to appropriate places

			sed -i --follow-symlink "/^auth.*required.*pam_faillock.so.*preauth.*silent.*/ s/$/ deny=$var_accounts_passwords_pam_faillock_deny/" $pamFile
			sed -i --follow-symlink "/^auth.*[default=die].*pam_faillock.so.*authfail.*/ s/$/ deny=$var_accounts_passwords_pam_faillock_deny/" $pamFile
		fi

# pam_faillock.so not present yet

	else

# insert pam_faillock.so preauth & authfail rows with proper value of the 'deny' option

		sed -i --follow-symlink "/^auth.*sufficient.*pam_unix.so.*/i auth required pam_faillock.so preauth silent deny=$var_accounts_passwords_pam_faillock_deny" $pamFile
		sed -i --follow-symlink "/^auth.*sufficient.*pam_unix.so.*/a auth [default=die] pam_faillock.so authfail deny=$var_accounts_passwords_pam_faillock_deny" $pamFile
		sed -i --follow-symlink "/^account.*required.*pam_unix.so/i account required pam_faillock.so" $pamFile
	fi
done


var_password_pam_unix_remember="5"

if grep -q "remember=" /etc/pam.d/system-auth; then

sed -i --follow-symlink "s/\(remember *= *\).*/\1$var_password_pam_unix_remember/" /etc/pam.d/system-auth

else

sed -i --follow-symlink "/^password[[:space:]]\+sufficient[[:space:]]\+pam_unix.so/ s/$/ remember=$var_password_pam_unix_remember/" /etc/pam.d/system-auth

fi 

chmod 600 /boot/grub2/grub.cfg

echo "install dccp /bin/true" > /etc/modprobe.d/dccp.conf

echo "install sctp /bin/true" > /etc/modprobe.d/sctp.conf

grep -qi ^Protocol /etc/ssh/sshd_config && \

sed -i "s/Protocol.*/Protocol 2/gI" /etc/ssh/sshd_config

if ! [ $? -eq 0 ]; then

echo "Protocol 2" >> /etc/ssh/sshd_config

fi

sshd_idle_timeout_value="3600"

grep -qi ^ClientAliveInterval /etc/ssh/sshd_config && \

sed -i "s/ClientAliveInterval.*/ClientAliveInterval $sshd_idle_timeout_value/gI" /etc/ssh/sshd_config

if ! [ $? -eq 0 ]; then

echo "ClientAliveInterval $sshd_idle_timeout_value" >> /etc/ssh/sshd_config

fi



grep -qi ^ClientAliveCountMax /etc/ssh/sshd_config && \

sed -i "s/ClientAliveCountMax.*/ClientAliveCountMax 0/gI" /etc/ssh/sshd_config

if ! [ $? -eq 0 ]; then

echo "ClientAliveCountMax 0" >> /etc/ssh/sshd_config

fi

grep -qi ^PermitEmptyPasswords /etc/ssh/sshd_config && \

sed -i "s/PermitEmptyPasswords.*/PermitEmptyPasswords no/gI" /etc/ssh/sshd_config

if ! [ $? -eq 0 ]; then

echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config

fi


grep -qi ^Banner /etc/ssh/sshd_config && \

sed -i "s/Banner.*/Banner \/etc\/issue/gI" /etc/ssh/sshd_config

if ! [ $? -eq 0 ]; then

echo "Banner /etc/issue" >> /etc/ssh/sshd_config

fi


grep -qi ^PermitUserEnvironment /etc/ssh/sshd_config && \

sed -i "s/PermitUserEnvironment.*/PermitUserEnvironment no/gI" /etc/ssh/sshd_config

if ! [ $? -eq 0 ]; then

echo "PermitUserEnvironment no" >> /etc/ssh/sshd_config

fi


grep -qi ^Ciphers /etc/ssh/sshd_config && \

sed -i "s/Ciphers.*/Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc/gI" /etc/ssh/sshd_config

if ! [ $? -eq 0 ]; then

echo "Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc" >> /etc/ssh/sshd_config

fi



