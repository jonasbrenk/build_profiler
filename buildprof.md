# Build Profiler

## Motivation

    Minimizing the time it takes to recompile after a source-code change can significantly reduce the cost of development. &mdash; *John Lakos*

When languages like C or C++ are used where the source code is compiled, every re-compilation (or re-generation) of a translation unit during the build process costs time. If we had a tool which gives us all files that were changed during the build, including their timestamps, we could profile the build process. And that would allow us to optimize the build process in a systematic manner, i.e., by first tackling steps that take most time.

## Challenge

Write a Powershell or Bash script that:

* Takes a directory as input argument
* Scans that directory (be careful not to alter files!) and determines the creation time of all build artifacts, e.g., object files, intermediate configuration files, etc.
* Scans that directory again after the build and determines which artifacts we re-compiled or re-generated
* Outputs a CSV file with the names of the files that changed and their timestamps
