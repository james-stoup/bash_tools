#!/bin/bash



USER_LIST=()
VERBOSE=false


#####################################################
# Print usage
#####################################################
usage() {
    cat <<EOF
milk.sh

NAME
        milk.sh - checks to see if your password is expired

SYNOPSIS
        milk.sh <flag> <optional hosts>

DESCRIPTION
        This tool prints the days remaining till each user's password expires.

        -h
               prints this help screen

        -e
               prints the days till password expiration for the current user

        -a
               prints days til expiration for all users (must have sudo rights)

        -v
               check ALL users

AUTHOR
        Another handy tool by James Stoup

EXAMPLES
        # To see how many days til the password of the current account expires
        ./milk.sh -e

        # To see how many days till all the real users's passwords expire
        sudo ./milk.sh -a

        # To see all accounts
        sudo ./milk.sh -a -v

EOF
    
    exit 1
}

#####################################################
# Bail if we aren't root
#####################################################
rootCheck() {
    if [ ! "$EUID" -eq 0 ]; then
	echo "please run me with sudo or as root"
	exit 1
    fi
}


#####################################################
# Check just the current user
#####################################################
checkCurUser() {
    CUR_USER=`whoami`
    USER_LIST=($CUR_USER)
    printDaysLeft
}



#####################################################
# Check all users (requires root access)
#####################################################
checkAllUsers() {
    rootCheck

    if [[ "$VERBOSE" = "true" ]] ; then
        # ALL users
        USER_LIST_STR=`getent passwd | cut -d: -f1 | sort`
    
        # All "real" users 
        #USER_LIST_STR=`eval getent passwd {$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)} | cut -d: -f1 | sort`

    else
        echo "NORMAL"
        # All human users
        USER_LIST_STR=`getent passwd | grep home | cut -d: -f1 | sort`

    fi
    
    USER_LIST=($USER_LIST_STR)

    printDaysLeft
}




#####################################################
# Print the days left of the user(s) passed in
#####################################################
printDaysLeft() {
    printf "==========================================\n"
    printf "  %-25s %s\n" "USER" "DAYS LEFT"
    printf "==========================================\n"

    for CUR_USER in "${USER_LIST[@]}"
    do
        AGE=`chage -l $CUR_USER | grep "Password expires" | cut -d ":" -f2 |  sed 's/^ *//g'`

        if [[ $AGE == "never" ]] ; then
            printf "  %-25s %s\n" $CUR_USER "Never"
        else
            DEADLINE=`date -d "$AGE" +%s`
            DATE_NOW=`date +%s`
            DAYS_LEFT=$(( ($DEADLINE - $DATE_NOW)/(3600*24) ))

            # put in flag to only print positive values
            if (( $DAYS_LEFT >= 0 )) ; then
                printf "  %-25s %s\n" $CUR_USER $DAYS_LEFT
            fi
        fi
        
    done
}



#####################################################
# If they just ran it blind, print the help
#####################################################
if [[ -z "$1" ]]; then
    usage
fi


#####################################################
# Main()
#####################################################
while getopts ":heav" opt; do
    case $opt in
	h)
	    usage
	    ;;
    e)
        CUR_USER=true
        ;;
	a)
        ALL_USERS=true
	    ;;
    v)
        VERBOSE=true
        ;;
	*)
	    usage
	    ;;
    esac
done

if [[ "$CUR_USER" = true ]] && [[ "$ALL_USERS" = true ]] ; then
    echo ""
    echo "Please use either the -a or -e flag, but not both at the same time!"
    echo ""
    usage
    exit 1
fi


# run for one user
if [[ "$CUR_USER" = true ]] ; then
    checkCurUser
fi

# run for all users
if [[ "$ALL_USERS" = true ]] ; then
	checkAllUsers
fi


