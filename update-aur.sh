#!/bin/bash

# CONFIG
AURGITCLONE=/home/td123/tmp/aurgitclone
AURTEST=/home/td123/tmp/aursrcpkgs

RSYNC_HOST='aur.archlinux.org'

# SANITY CHECKS
[ ! -d $AURGITCLONE ] && echo "run: git clone /srv/git/aur-mirror.git/ $AURGITCLONE" && exit 1
[ ! -d $AURTEST ] &&  echo "run: install -d $AURTEST" && exit 1

# Syncing *.src.tar.gz
cd $AURTEST
rm -f /tmp/rlog
rsync -avz --include '/*.tar.gz' --exclude '/*' --exclude '/.git/' --temp-dir '/tmp' --inplace --update --delete \
      "rsync://${RSYNC_HOST}/unsupported/*/*/*.tar.gz" . |& tee /tmp/rlog || (echo 'rsync failed' && exit 1)

echo 'extracting package files'

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
      bsdtar -s ',.*/,,' -C ${match} -xf $AURTEST/${match}.tar.gz
    fi
  fi
done < /tmp/rlog
rm -f /tmp/rlog

echo 'adding files to git'

# GIT STUFF
git add -A 
git commit -am "updated on $(date)"
git gc --auto
git push origin master
