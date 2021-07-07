#!/bin/bash

# curl -sL https://gist.githubusercontent.com/RichardBronosky/31660eb4b0f0ba5e673b9bc3c9148a70/raw/touchid_sudo.sh | bash
# This script is ready to copy-paste in whole, or just the line above (without the leading #)

# Use TouchID for sudo on modern MacBook Pro machines
# This script adds a single line to the top of the PAM configuration for sudo
# See: https://apple.stackexchange.com/q/259093/41827 for more info.

touchid_sudo(){
  sudo bash -eu <<'EOF'
  file=/etc/pam.d/sudo
  # A backup file will be created with the pattern /etc/pam.d/.sudo.1
  # (where 1 is the number of backups, so that rerunning this doesn't make you lose your original)
  bak=$(dirname $file)/.$(basename $file).$(echo $(ls $(dirname $file)/{,.}$(basename $file)* | wc -l))
  cp $file $bak
  awk -v is_done='pam_tid' -v rule='auth       sufficient     pam_tid.so' '
  {
    # $1 is the first field
    # !~ means "does not match pattern"
    if($1 !~ /^#.*/){
      line_number_not_counting_comments++
    }
    # $0 is the whole line
    if(line_number_not_counting_comments==1 && $0 !~ is_done){
      print rule
    }
    print
  }' > $file < $bak
EOF
}

touchid_sudo
