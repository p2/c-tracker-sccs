C Tracker SCCS
==============

This repository contains the code for the SCCS C Tracker app.

Two configuration files are missing: `/Configuration_Debug.swift` and `/Configuration_Release.swift`.
These files are and will be ignored by git, but building the App will create them by copying `/Configuration.swift` to both these places.
Use them to configure your app without the risk of having configuration data exposed in the repository.

Similarly, you need to add `data-queue-certificate.crt` to the target if you wish to use encrypted data uploads.
Create debug and release versions of it that you do not add to the GitHub repo and name them `data-queue-certificate_Debug.crt` and `data-queue-certificate_Release.crt`, respectively.
The build process will move them into place during build time accordingly.
See [c3-pro-ios-framework/Encryption](https://github.com/C3-PRO/c3-pro-ios-framework/tree/master/Sources/Encryption#rsautility).

### Data Submission

The class `UserActivityTaskHandler` determines what is to be done when a user completes a task, such as completing a survey.
This class will:

- create a resource from the survey answers and submit to the data server
- create resources from the user's provided health data and submit to the data server
- create a resource from the activity data of the last period and submit to the data server


Compiling
---------

The app currently uses a mix of manually embedding frameworks and using [Carthage](https://github.com/Carthage/Carthage#installing-carthage) to do so.
For now we're using _Carthage_ to build **Smooch**, all the other dependencies are directly added as git submodules to the App target.
You will need to install Carthage locally and run the following before running the app:

    carthage update --platform ios
