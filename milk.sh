#!/bin/bash


# either do one user, or all of them
USER_LIST=()
if [ -z "$1" ] ; then
    # ALL users
    #USER_LIST_STR=`getent passwd | cut -d: -f1 | sort`
    
    # All "real" users 
    #USER_LIST_STR=`eval getent passwd {$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)} | cut -d: -f1 | sort`

    # All human users
    USER_LIST_STR=`getent passwd | grep home | cut -d: -f1 | sort`

    USER_LIST=($USER_LIST_STR)

else
    USER_LIST=($1)
fi


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
