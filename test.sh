#!/usr/bin/env -S zsh -s
test1="it"
test2="is"
test3="working"


sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/test_recieve.sh)" $test1 $test2 $test3