#!/usr/bin/zsh
test1="one"
test2="two"
test3="three"
vars='$test1 $test2 $test3'

sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/test_recieve.sh)" $vars



