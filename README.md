# Temp-Admin
Jamf script to give admin privileges for a few minutes, remove them to the user and other accounts

With this script executed from Self Service, users get temporary admin privileges for the amount of time you choose (default is 10 minutes).

After the time is expired, another script is run in order to remove admin privileges for the user but also for any user account with UID > 500. You can exclude a specific account if you wish. It allows to do some cleaning to avoid a user creating an admin during his admin time so it can be reused without the script.

This script requires 2 parameters:
- Number of minutes during which a user is an admin (default is 10 minutes)
- Admin account to exclude from remediation

The script is a simple Self Service policy that can be allowed any time or restricted using execution frequency and/or scoping.
