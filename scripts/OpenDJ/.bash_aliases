alias a=alias
alias h=history
alias cl=clear
alias j=jobs
alias la='ls -lA'
alias df='df -h'
alias port='netstat -an|grep LISTEN|grep '
alias dsconfig='su - opendj -c "LANG=C ; dsconfig --bindPasswordFile $BIND_PASSWORD_FILE --trustAll --hostname localhost --displayCommand"'
alias tle='tail -f $LDAP_LOG_DIR/errors'
alias tla='tail -f $LDAP_LOG_DIR/access'
alias vle='vi $LDAP_LOG_DIR/errors'
alias vla='vi $LDAP_LOG_DIR/access'
