$ cat exitstatus.sh
#! /bin/bash

echo -e "Successful execution"
echo -e "====================="
echo "hello world"
# Exit status returns 0, because the above command is a success.
echo "Exit status" $? 

echo -e "Incorrect usage"
echo -e "====================="
ls --option
# Incorrect usage, so exit status will be 2.
echo "Exit status" $? 

echo -e "Command Not found"
echo -e "====================="
bashscript
# Exit status returns 127, because bashscript command not found
echo "Exit status" $? 

echo -e "Command is not an executable"
echo -e "============================="
ls -l execution.sh
./execution.sh
# Exit status returns 126, because its not an executable.
echo "Exit status" $?
