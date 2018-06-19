# Temp-Admin
Script to give admin privileges for a few minutes, remove them from the user and other accounts

With this script executed from Jamf Self Service (or probably any other management tool that can let users execute scripts), users get temporary admin privileges for the amount of time you choose (default is 10 minutes).

After the time is expired, another script is run in order to remove admin privileges for the user but also for any user account created as an admin after the launch of the first script. The new admin accounts created are discovered comparing the list of admins before and after, even if they have a low UID (<501).


This script requires 1 parameter:
- Number of minutes during which a user is an admin (default is 10 minutes)

The script is a simple Self Service policy that can be allowed any time or restricted using execution frequency and/or scoping.

A simple icon is provided for use in Self Service if you want.

# Changes

This is a new version of the script previously published. It does not require to exclude manually an admin in the parameters and will also find admins that would be hidden.

# Things to know...

This script uses the "at" command in order to execute the second part of the action (removal of admin privileges and remediation of admins created after the launch). Which means it could potentially be blocked by stopping the "at" Launchd element.
