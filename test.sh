#!/usr/bin/env -S zsh -s
test1="one"
test2="two"
test3="three"


sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/test_recieve.sh)" $test1 $test2 $test3


