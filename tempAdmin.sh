#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Copyright (c) 2018 Jamf.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the Jamf nor the names of its contributors may be
#                 used to endorse or promote products derived from this software without
#                 specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# This script gives temporary admin privileges to users launching it (usually from Self Service)
# 
# You can set the amount of time for which they have this privilege in Minutes as Parameter 4
# If not amount of time is set, the default is 10 minutes.
# 
# A window will show them the amount of time left, if they close it the script will still execute
# 
# After the time is elapsed, their privileges are removed. Any other account that is admin is also
# demoted except the account mentioned in paramater 5 (that is, usually your local admin) or any
# hidden account (that is usually an account with UID < 501).
# 
# Written by: Laurent Pertois | Senior Professional Services Engineer | Jamf
#
# Created On: 2018-06-12
# Updated On: 2018-06-12
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #




# Get username of current logged in user
USERNAME=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')


# Checks if there is a value passed as $4 for the number of minutes, if not, defaults to 10
if [ -z "$4" ]; then
	TEMPMINUTES=10
else
	# Checks if the value passed as $4 for the number of minutes is a positive numeric number 
	# without any extra characters (i.e. 10, not +10 or -10), if not, defaults to 10
	if [[ "$4" =~ [^0-9]+ ]] ; then
		TEMPMINUTES=10
	else
		TEMPMINUTES="$4"
	fi
fi

# Calculates the number of seconds
TEMPSECONDS=$((TEMPMINUTES * 60))

# Writes in logs
logger "Checking privileges for $USERNAME."

# Checks if account is already an admin or not
MEMBERSHIP=$(dsmemberutil checkmembership -U "$USERNAME" -G admin)

if [ "$MEMBERSHIP" == "user is not a member of the group" ]; then
	
	# Checks if atrun is launched or not (to disable admin privileges after the defined amount of time)
	if ! launchctl list|grep -q com.apple.atrun; then launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist; fi

	# Makes the user an admin
	/usr/sbin/dseditgroup -o edit -a "$USERNAME" -t user admin
	logger "Elevating $USERNAME."

	# Uses at to execute the cleaning script after the defined amount of time
	# Be careful, at can take some time to execute and be delayed under heavy load
	echo "#!/bin/sh


	# For any user with UID >= 501 remove admin privileges
	# One user can be whitelisted using Jamf Pro parameters, it is \$5 in the Jamf Pro policy

	for user in \$(dscl . -list /Users uid | awk '{if ( \$2 >= 501 ) print \$1}');do

		# Checks if user is whitelisted or not
		if [ \"\$user\" != \"$5\" ]; then
		
			# If not whitelisted, then removes admin privileges
			/usr/sbin/dseditgroup -o edit -d \$user -t user admin

		fi	

	done

	exit $?" | at -t "$(date -v+"$TEMPSECONDS"S "+%Y%m%d%H%M.%S")"


	# Path to Jamf Helper
	JAMFHELPERPATH="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

	# Displays a window showing how much time is left as an admin using Jamf Helper	
	"$JAMFHELPERPATH" -windowType utility \
		-windowPosition ur \
		-title "Elevate User Account" \
		-heading "Temporary Admin Rights Granted" \
		-alignHeading middle \
		-description "Please perform required administrative tasks" \
		-alignDescription natural \
		-icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UnlockedIcon.icns" \
		-iconSize 36 \
		-button1 "Done" \
		-defaultButton 1 \
		-timeout "$TEMPSECONDS" \
		-countdown \
		-countdownPrompt "Admin Rights will be revoked in " \
		-alignCountdown center

	# Writes in logs when it's done
	logger "Elevation complete."
    exit 0
fi

# If user is already an admin, we write this in logs, tell the user and then quit
logger "User already has elevated privileges."
osascript -e "display dialog \"You already have elevated privileges \" buttons \"OK\" with icon caution"

exit 0
