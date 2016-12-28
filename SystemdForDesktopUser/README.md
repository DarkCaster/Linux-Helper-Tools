# Helper tools for systemd services, that allow to start\stop\control regular userspace applications within X11 sessions.

Systemd can be used with regular user sessions, to control user services.
But it's environment is quite limited, and it cannot launch desktop applications.
This scripts perform setup of systemd env on user session startup,
and perform startup of user service files installed to "desktop" target (also defined by this tools)

