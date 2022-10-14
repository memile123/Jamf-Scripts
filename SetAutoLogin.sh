#!/bin/bash

#############
# VARIABLES #
#############

# This configuration works best if FileVault is not enabled first. 

USERNAME="${1}"

#this can be blank if that is the password
PW="${2}"

#############
# FUNCTIONS #
#############

#given a string creates data for /etc/kcpassword
function kcpasswordEncode () (

	#ascii string
	thisString="${1}"

	#macOS cipher hex ascii representation array
	cipherHex_array=( 7D 89 52 23 D2 BC DD EA A3 B9 1F )

	#converted to hex representation with spaces
	thisStringHex_array=( $(/bin/echo -n "${thisString}" | xxd -p -u | sed 's/../& /g') )

	#get padding by subtraction if under 12 
	if [ "${#thisStringHex_array[@]}" -lt 12  ]; then
		padding=$(( 12 -  ${#thisStringHex_array[@]} ))
	#get padding by subtracting remainder of modulo 12 if over 12 
	elif [ "$(( ${#thisStringHex_array[@]} % 12 ))" -ne 0  ]; then
		padding=$(( (12 - ${#thisStringHex_array[@]} % 12) ))
	#otherwise even multiples of 12 still need 12 padding
	else
		padding=12
	fi	

	#cycle through each element of the array + padding
	for ((i=0; i < $(( ${#thisStringHex_array[@]} + ${padding})); i++)); do
		#use modulus to loop through the cipher array elements
		charHex_cipher=${cipherHex_array[$(( $i % 11 ))]}

		#get the current hex representation element
		charHex=${thisStringHex_array[$i]}
	
		#use $(( shell Aritmethic )) to ^ XOR the two 0x## values (extra padding is 0x00) 
		#take decimal value and printf convert to two char hex value
		#use xxd to convert hex to actual value and send to stdout (to avoid NULL issue in bash strings)
		printf "%02X" "$(( 0x${charHex_cipher} ^ 0x${charHex:-00} ))" | xxd -r -p > /dev/stdout
	done
)

########
# MAIN #
########

#quit if not root
if [ "${UID}" != 0 ]; then
	echo "Please run as root, exiting."
	exit 1
fi

#special case for Guest account (case SENSITIVE)
if [ "${USERNAME}" = "Guest" ]; then
	#turn on Guest account 
	sysadminctl -guestAccount on
	#set auto-login
	defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser Guest

	echo "Auto login enabled for Guest"
#if we have any other USERNAME
elif [ -n "${USERNAME}" ]; then 

	#check if user exists
	if ! id "${USERNAME}" &> /dev/null; then
		echo "User '${USERNAME}' not found, exiting."
		exit 1
	fi
	
	#check that the supplied password is valid
	if ! /usr/bin/dscl /Search -authonly "${USERNAME}" "${PW}" &> /dev/null; then
		echo "Invalid password for '${USERNAME}', exiting."
		exit 1
	fi

	#encode password and write file 
	kcpasswordEncode "${PW}" > /etc/kcpassword
	
	#ensure ownership and permissions are correct (600)
	chown root:wheel /etc/kcpassword
	chmod u=rw,go= /etc/kcpassword

	#turn on auto login for the user
	/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser -string "${USERNAME}"
	echo "Auto login enabled for '${USERNAME}'"

#if no USERNAME, turn auto-login OFF
else
	[ -f /etc/kcpassword ] && rm -f /etc/kcpassword
	/usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser &> /dev/null
	echo "Auto login disabled"
fi

exit 0
