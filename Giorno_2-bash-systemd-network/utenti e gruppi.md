Managing users
Users must authenticate to any system they need to use. This authentication provides access to resources and a customized, user-specific environment. The user's identity is based on their user account. What skills do sysadmins need to manage user accounts?

1. Understand the /etc/passwd file
User account information is stored in the /etc/passwd file. This information includes the account name, home directory location, and default shell, among other values. Linux sysadmins should be able to recognize these fields.

Each field is separated by a : character, and not all fields must be populated, but you must delineate them.

Here's an example of the /etc/passwd fields:

username:password:UID:GID:comment:home:shell
In this example, the comment field is empty:

dgarn:x:1001:1001::/home/dgarn:/bin/bash
Observe how the two colons still exist to delineate the comment field.

Here is an example with the comment field populated:

dgarn:x:1001:1001:Damon Garn:/home/dgarn:/bin/bash
I'll discuss passwords more below, but expect to see an x in the password field of this file.

For more information, see:

Linux sysadmin basics: User account management
Linux sysadmin basics: User account management with UIDs and GIDs
2. Understand the /etc/shadow file
Skip to the bottom of list
Image
IT Automation ebook
Long ago, password hashes were stored in the /etc/passwd file. This file was world-readable, allowing inquisitive users to pull password hashes for other accounts from the file and run them through password-cracking utilities. Eventually, the password hashes were moved to a file readable only by root: /etc/shadow. Today, the password field in the /etc/passwd file is marked with an x.

Administrators should recognize each field in /etc/shadow. Several of the fields pertain to password requirements.

Here's an example of /etc/shadow fields:

username:password:last password change:min:max:warning:inactive:expired
The first two fields identify the user and a hashed version of the password, while the remaining six fields represent password change information. The password information is manipulated with the chage command.

Look at these articles for additional details:

The effects of adding users to a Linux system
Forcing Linux system password changes with the chage command
3. Create, modify, and delete user accounts
The process for managing user accounts is very straightforward. Sysadmins either add, modify, or delete users, and the related commands are quite intuitive.

The commands to manage user accounts on RHEL and RHEL-like distributions are:

useradd
usermod
userdel
Ken Hess documents these commands in Linux sysadmin basics: User account management. There are many options available to customize the user accounts and their related resources.

My companion article provides specifics about the useradd, usermod, and userdel commands.

[ You might also be interested in downloading the Bash shell scripting cheat sheet. ]

4. Manage password requirements
Many organizations rely on password policies to define appropriate password requirements. Sysadmins can enforce those requirements by using various mechanisms on Linux.

Two common ways of managing password settings are using the /etc/login.defs file or Pluggable Authentication Module (PAM) settings. Be sure to understand the options, fields, and settings for this important security configuration.

For more detail on password security settings, read:

Managing Linux users with the passwd command
Linux security: 8 more system lockdown controls
How to enhance Linux user security with Pluggable Authentication Module settings
An introduction to Pluggable Authentication Modules in Linux
Managing groups
It's more efficient to group user accounts with similar access requirements than to manage permissions on a user-by-user basis. Therefore, sysadmins need to be comfortable with the process of creating, modifying, and deleting groups.

[ Practice your Linux skills in the free online course RHEL technical overview. ]

1. Understand the /etc/group file
Similar to the /etc/passwd file above, the /etc/group file contains group account information. This information can be essential for troubleshooting, security audits, and ensuring users can access the resources they need.

Understand each field of the file to make life easier as a sysadmin.

The fields in the /etc/group file are:

groupname:password:GID:group members
Here is an example of the editors group with two members:

editors:x:2002:damon,tyler
Tyler Carrigan's article Managing local group accounts in Linux presents this information nicely.

Linux groups are significantly different from local groups in Windows, so be sure to understand the differences.

2. Create, modify, and delete groups
Like the user account commands described above, the group management commands are very intuitive and provide a lot of flexibility. There is an easy-to-remember command for each function you might need to carry out for a group:

groupadd
groupmod
groupdel
The following articles provide a good overview of working with groups:

Managing local groups account in Linux
3 basic Linux group management commands every sysadmin should know
3. Manage group membership
Skip to the bottom of list

Adding users to a group simplifies permissions management. Many people find the process a little unintuitive: Adding a user to a group modifies the user, not the group. Therefore, the necessary command is the usermod command.

Here are some commands to display group information:

usermod: Update group membership
id: Display a list of groups the user is a member of
cat /etc/group: Show a list of existing groups, with membership displayed in the last field
One resource for these commands is their related man pages.

The process for adding users to a group requires the -a and/or -G options. Tyler Carrigan's article Managing local group accounts in Linux covers using these options to manipulate group membership.
