#/bin/sh

if [ -z $1 ] ;
then echo "No branch specified. Please, provide one as first argument."
     echo "Example: sh commit_cleaner.sh master ""commit message"""
else
   if [ -z $2 ] ;
   then echo "No commit message specified. Please provide one as second argument."
        echo "Example: sh commit_cleaner.sh $1 ""commit message"""
   else
    #from https://stackoverflow.com/questions/9683279/make-the-current-commit-the-only-initial-commit-in-a-git-repository
    #1 Checkout
    git checkout --orphan latest_branch
    #2 Add all the files
    git add -A
    #3 Commit the changes
    git commit -am $2
    #4 Delete the branch
    git branch -D $1
    #5 Rename the current branch to main
    git branch -m $1
    #6 Finally, force update your repository
    git push -f origin $1
   fi
fi