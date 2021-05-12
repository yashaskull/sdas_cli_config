#!/bin/bash

for branch in $(git branch -a | grep remotes | grep -v HEAD | grep -v main); 
do
	git branch --track ${branch#remotes/origin/} $branch
done
