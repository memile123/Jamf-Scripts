#!/usr/bin/env python

"""
Jamf Pro extension attribute to return a list of authorization rights
enabled on a Mac. The returned levels are...
    - allow - unlocks the associated preference pane without admin rights
    - authenticate-session-owner-or-admin - requires credentials, but
      allows standard users to authenticate.
    - None - default preference where admin credentials are required

Authorization rights reference: https://www.dssw.co.uk/reference/authorization-rights/index.html
Add more to RIGHTS list as needed. 

Partially cribbed from https://gist.github.com/haircut/20bc1b3f9ef0cec7d869a87b0db92fd3
https://github.com/nstrauss/jamf-extension-attributes
"""

import subprocess
import plistlib

# List of authorizations to be checked
RIGHTS = [
    "system.preferences",
    "system.preferences.datetime",
    "system.preferences.printing",
]


def get_auth_right(right, format="string"):
    """Gets the specified authorization right in plist format."""
    try:
        cmd = ["/usr/bin/security", "authorizationdb", "read", right]
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, _ = proc.communicate()
        if stdout:
            return plistlib.readPlistFromString(stdout)
    except (IOError, OSError):
        pass


def main():
    # Loop through rights and get associated rule. Append to list.
    results = []
    for right in RIGHTS:
        try:
            rule = get_auth_right(right)["rule"][0]
        except KeyError:
            rule = None
        a = "%s: %s" % (right, rule)
        results.append(a)

    # Format list and print to EA
    results = "\n".join(results)
    print("<result>%s</result>" % results)


if __name__ == "__main__":
    main()
