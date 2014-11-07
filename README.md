This project holds various build scripts I use in my Xcode projects.

Easiest installation is through CocoaPods.
Until there is a release published just add

    pod 'TCBuildtools', :git => 'git@github.com:tcurdt/TCBuildtools.git'

to your `Podfile`.

The code is released under the Apache License 2.0.

# Git based Build Numbers

1. create an (or add to an existing) "Aggregate Target" called "Buildtools"
2. add a "run script" build phase to the new target calling

	    $PROJECT_DIR/Pods/TCBuildtools/Scripts/xcode-buildinfo-git

3. add the new build target to the project's main target as target dependency
4. change your Info.plist to

	    CFBundleGetInfoString BUILD_REVISION
	    CFBundleShortVersionString BUILD_VERSION
	    CFBundleVersion BUILD_NUMBER

5. In your main target set the build settings

    - "Info.plist preprocessor prefix file" to `$(PROJECT_TEMP_DIR)/Info.plist.prefix`
    - "Preprocess Info.plist File" to `YES`


# Localizable String verifications

1. create an (or add to an existing) "Aggregate Target" called "Buildtools"
2. add a "run script" build phase to the new target calling

	    $PROJECT_DIR/Pods/TCBuildtools/Scripts/xcode-verify-strings

4. Optional: Create a `.verifystringsignore` file excluding

	    Pods


# Turn FIXMEs into warnings

1. create an (or add to an existing) "Aggregate Target" called "Buildtools"
2. add a "run script" build phase to the new target calling

      $PROJECT_DIR/Pods/TCBuildtools/Scripts/xcode-todo-warnings
