# xcopy

CLI to copy all the files matching a pattern to a destination directory.

```text
Usage:
  xcopy [--help]
  xcopy [--verbose] [--pattern|-p <pattern>] --source|-s <source> --dest|-d <destination>

Arguments:

-h, --help                              Print this usage information.
-v, --verbose                           Show file name along with path while being copied
-s, --source=<source> (mandatory)       Source path to copy from
-d, --dest=<destination> (mandatory)    Destination path to copy to
-p, --pattern=<pattern>                 Pattern to match files to copy
                                        (defaults to "*")
    --[no-]overwrite                    Overwrite files that already exist in the destination
    --dry-run                           Show what files will be copied without actually copying them
```
