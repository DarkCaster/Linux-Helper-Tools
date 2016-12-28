# Helper tool for user-mode systemd.

Provide facility needed to perform auto start for regular userspace graphical\console applications as service files.

Systemd can be used with regular user sessions, to control user services.
But it's environment is quite limited, and it cannot launch desktop applications.
This tool perform setup of systemd env on user graphical session startup,
and perform launch of user service files installed to "desktop" target (also defined by this tool).

