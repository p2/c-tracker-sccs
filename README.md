C Tracker SCCS
==============

This repository contains the code for the SCCS C Tracker app.

Two configuration files are missing: `/Configuration_Debug.swift` and `/Configuration_Release.swift`.
These files are and will be ignored by git, but building the App will create them by copying `/Configuration.swift` to both these places.
Use them to configure your app without the risk of having configuration data exposed in the repository.
