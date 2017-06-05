C Tracker SCCS
==============

This repository contains the code for the SCCS C Tracker app.

Two configuration files are missing: `/Configuration_Debug.swift` and `/Configuration_Release.swift`.
These files are and will be ignored by git, but building the App will create them by copying `/Configuration.swift` to both these places.
Use them to configure your app without the risk of having configuration data exposed in the repository.

### Data Submission

The class `UserActivityTaskHandler` determines what is to be done when a user completes a task, such as completing a survey.
This class will:

- create a resource from the survey answers and submit to the data server
- create resources from the user's provided health data and submit to the data server
- create a resource from the activity data of the last period and submit to the data server


Compiling
---------

The app currently uses a mix of manually embedding frameworks and using [Carthage](https://github.com/Carthage/Carthage#installing-carthage) to do so.
This is because of issues with CryptoSwift when archiving the app for App Store publication, so for now we're using _Carthage_ to build **CryptoSwift** and **Smooch**.
You will need to install Carthage locally and run the following before running the app:

    carthage update --platform ios
