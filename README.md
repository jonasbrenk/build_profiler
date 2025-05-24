# Build Profiler

This project provides a robust Bash script (`build_profiler.sh`) designed to profile build processes by meticulously tracking file modification timestamps within a specified directory.

## How It Works

The `build_profiler.sh` script operates in three main steps:

1. **Initial Scan**: It performs a comprehensive scan of the target directory (or the current directory by default) and records the last modification timestamp of every file. This snapshot represents the state before your build.

2. **Build Execution (or Manual Prompt)**:
   - If a build command is provided via the `-b` option, the script will execute it in the target directory.
   - If no build command is specified, the script will pause and prompt you to manually run your build process.

3. **Final Scan & Comparison**: After the build, the script performs a second scan of the same directory. It then compares the timestamps from the initial and final scans to identify:
   - Files that were newly created during the build.
   - Existing files whose `last_modification_timestamp` has changed, indicating they were re-compiled or re-generated.

Finally, it generates a `build_profile.csv` file containing the paths and new timestamps of all detected changes, and also prints these results concisely to the console. Temporary files used during the process are automatically cleaned up.

## Purpose

By analyzing these before-and-after timestamps, the `build_profiler.sh` helps developers to:

- **Understand Build Flow**: Gain clear visibility into the sequence and dependencies of file generation during a build.
- **Identify Bottlenecks**: Pinpoint specific compilation, linking, or generation steps that consume the most time.
- **Optimize Build Times**: Systematically target and improve the slowest parts of your build pipeline, leading to faster iteration cycles and reduced development costs.


### Basic Usage (Manual Build)

Run the script, then manually execute your build command when prompted:

```bash
./build_profiler.sh [directory_to_profile]
```

`[directory_to_profile]` is optional. If omitted, the current working directory will be used.

**Example:**

```bash
# Profile the current directory, then manually run 'make'

./build_profiler.sh
# Script scans directory
# (Script pauses)

# Now, in a separate terminal:
make
# (Press Enter in the script's terminal to continue)
```

### Automated Usage (Execute Build Command)

Provide your build command directly to the script using the `-b` option. The build command should be quoted if it contains spaces.

```bash
./build_profiler.sh [directory_to_profile] -b "<build command>"
```

- `[directory_to_profile]` is optional.
- `<build command>` is required after `-b`.

**Examples:**

```bash
# Profile the current directory, automatically run 'make clean all'
./build_profiler.sh -b "make clean all"
```

### Getting Help

To display the script's help message:

```bash
./build_profiler.sh -h
# or
./build_profiler.sh --help
# or
./build_profiler.sh help
```

## Output

The results will be saved to `build_profile.csv` in the directory where the script is run, and also printed to your console in a formatted table (if the `column` command is available).

## Example Project

To demonstrate the build profiler, there is a simple C project with a Makefile that can be used to test functionality.

**Project Structure:**

```
test_project/
├── main.c
├── my_lib.c
├── my_lib.h
└── Makefile
```

### Running the Profiler with the Example

From the directory containing your `build_profiler.sh` script:

```bash
./build_profiler.sh ./test_project -b "make clean all"
```

Or from the `test_project/` directory:

```bash
../build_profiler.sh . -b "make clean all"
```

This command will:

- Scan the `test_project` directory.
- Execute `make clean all` inside `test_project`, which will clean previous builds, then compile `main.c` and `my_lib.c` and finally link `my_program`.
- Perform a final scan and report the timestamps of `main.o`, `my_lib.o`, and `my_program`, demonstrating the delay between different build actions in the Makefile.
