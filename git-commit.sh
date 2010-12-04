#!/bin/bash
# This script is a commit helper. Usefull to commit using bazaard and vim it
# shows changes on the repo wille you write your commit message
# Nb.: I use ~ in files name because I usualy ignore them (see bzr help
# ignore)

# filling a file with repo status and change since last commit
scm=git
# generate the diff
tmpfile_diff=$(mktemp -u "/tmp/commit-diff.XXXXXXXXXXXXXXX")
$scm diff > $tmpfile_diff

# edit the commit message
# better keep it localy to reuse it if commit fail
#tmpfile_commit_message=$(mktemp -u "/tmp/commit-message.XXXXXXXXXXXXXXX")
tmpfile_commit_message=.last-commit~

# generate the status
tmpfile_commit_status=$(mktemp -u "/tmp/commit-status.XXXXXXXXXXXXXXX")
$scm status >> $tmpfile_commit_status

# load diff, status and commit message in vim
vim -c "e $tmpfile_diff" -c vs -c "e $tmpfile_commit_status" -c 0 -c sp -c "e $tmpfile_commit_message"

# after edition we check if we have a commit message file
if [ -f $tmpfile_commit_message ] 
then
  # to debug turn scm to echo
  #scm=echo

  # here we add all the files marqued as + instead of ?
  cat $tmpfile_commit_status | grep -E "\+\s*+.*" | sed 's#\S\s*\(.*\)$#\1#g;' | xargs -I'{}' $scm add '{}'

  # now we launch the commit operation for every file marqued with 
  # D, A, M or +, then if the commit is successful we delete the 
  # message file
  # TODO for the rename we have to delete the old one afater, the fix would be to test with an expression like this:
  # sed 's#\(.*)->\(.*\)#\# oldname:\1\n\#renamed:\2#g'
  # TODO this huge command would lay nicely on many lines
  $scm commit -F $tmpfile_commit_message $(cat $tmpfile_commit_status | sed 's/\+\s*\(.*\)\(->.*\)\{1\}$/\+:\1/g' | grep -E "+modified:|+new file:|+deleted:|+renamed:|\+:.*" | sed 's#.*->\(.*\)#\# renamed:\1#g' | sed 's/.*:\s*\(.*\)$/\1/g;' | sed -n '1,$H; $x; $s/\n/ /gp') && rm $tmpfile_commit_message
else
  # abord commit
  echo "Commit aborded - The commit message file has not been saved"
fi


