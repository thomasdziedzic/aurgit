#!/bin/bash

# CONFIG
AURGITCLONE=/home/td123/tmp/aurgitclone
AURTEST=/home/td123/tmp/aursrcpkgs

# SANITY CHECKS
[ ! -d $AURGITCLONE ] && echo "run: git clone /srv/git/aur.git/ $AURGITCLONE"j&& exit 1
[ ! -d $AURTEST ] &&  echo "run: install -d $AURTEST" && exit 1

# Syncing *.src.tar.gz
cd $AURTEST
rm -f /tmp/rlog
rsync -avz --include '/*.tar.gz' --exclude '/*' --exclude '/.git/' --temp-dir '/tmp' --inplace --update --delete \
      'rsync://aur.archlinux.org/unsupported/*/*/*.tar.gz' . |& tee /tmp/rlog

# Process all the stuff
cd $AURGITCLONE
while read line; do
  match=$(echo $line | sed -n 's/^deleting \(.*\).tar.gz/\1/p')

  if [[ x$match != x ]]; then
    rm -rf ${match}
    #echo deleted
  else
    match=$(echo $line | sed -n 's/^\(.*\).tar.gz/\1/p')
    if [[ x$match != x ]]; then
      #echo updated
      rm -rf ${match}
      mkdir ${match}
      bsdtar -s ',.*/,,p' -C ${match} -xf $AURTEST/${match}.tar.gz
    fi
  fi
done < /tmp/rlog
rm -f /tmp/rlog

# GIT STUFF
git add -A 
git commit -am "updated on $(date)"
git gc --auto
git push origin master
