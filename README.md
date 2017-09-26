# Filebeat Cleaner
Move completely read files from Filebeat input directory.

# Usage
Simply run it using:
```
./filebeat_cleaner.rb
```

# Options
| Option | Description | Default |
| ---    | ---         | ---     |
| `-f REGISTRY` or `--file REGISTRY`  | Full path to the registry file.  | `/var/lib/filebeat/registry`   |
| `-d TARGET` or `--directory TARGET` | Directory where files are moved. | `/opt/data/filebeat/done`      |
| `-m` or `--move`                    | Does not move any file.          | Moves files on completion.     |
| `-v` or `--verbose`                 | Verbose output logging.          | Does not show verbose logging. |
| `-s` or `--summary`                 | Summary of I/O operations.       | Does not show summary.         |
| `-h` or `--help`                    | Shows help.                      | Does not show help.            |

