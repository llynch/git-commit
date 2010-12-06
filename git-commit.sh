#!/bin/bash
# This script is a commit helper. Usefull to commit using bazaard and vim it
# shows changes on the repo wille you write your commit message
# Nb.: I use ~ in files name because I usualy ignore them (see bzr help
# ignore)

# filling a file with repo status and change since last commit
scm=git
# generate the diff
tmpfile_diff=$(mktemp)
$scm diff > $tmpfile_diff

# edit the commit message
# better keep it localy to reuse it if commit fail
tmpfile_commit_message=.last-commit~

# generate the status
tmpfile_commit_status=$(mktemp)
$scm status >> $tmpfile_commit_status

parse_status() {
    status_file=$1


    # Explanations for the expressions above
    # line 1: cat the content of the status file
    # line 2: replace + with + newfile:
    # line 3: select modified:, new file:, deleted:, renamed:
    # line 4: then handle rename them
    # line 5: match any [#+].*:(.*) to select name of the file
    # line 6: escape spaces
    # line 7: inline everything
    cat $status_file | \
        sed 's#\+\s*\(.*\)$#+ new file:\1#g;' | \
        grep -E "+modified:|+new file:|+deleted:|+renamed:|\+:.*" | \
        sed 's#\(.*\)->\(.*\)#\# renamed:\1\n\# renamed:\2#g' | \
        sed 's#[\#\+][^:]*:\s*\(.*\)$#\1#g' | \
        sed 's# #\\ #g' | \
        sed -n '1,$H; $x; $s/\n/ /gp' 
}

main() {

# load diff, status and commit message in vim
vim -c "e $tmpfile_diff" -c vs -c "e $tmpfile_commit_status" -c 0 -c sp -c "e $tmpfile_commit_message"

# after edition we check if we have a commit message file
if [ -f $tmpfile_commit_message ] 
then
  debug=false
  # to debug turn scm to echo
  $debug && scm="echo"
  $debug && echo 

  # here we add all the files marqued as + instead of #
  cat $tmpfile_commit_status | \
      grep -E "\+\s*+.*" | \
      sed 's#\S\s*\(.*\)$#\1#g;' | \
      xargs -I'{}' $scm add '{}'

  $debug && parse_status $tmpfile_commit_status
  # now we launch the commit operation
  eval "$scm commit -F $tmpfile_commit_message $( parse_status $tmpfile_commit_status )" \
       && [ $debug != "true" ] && rm $tmpfile_commit_message
else
  # abord commit
  echo "Commit aborded - The commit message file has not been saved"
fi
}

main

