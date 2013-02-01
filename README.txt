This script will look for user accounts with passwords that will expire in 
X days and passwords that have already expired.

Customize the searchroot, the max password age and the cutoff for reporting
when the passwords will expire.

In the original code, the max password age is 90 days and the script will report
on passwords that will expire in 3 days or less, or if they've already expired.

The report will contain the age of the password, how many days until it expires
along with the date the password was last set and when the account was created.

The account must be at least 3 weeks old to appear on the report as well.s