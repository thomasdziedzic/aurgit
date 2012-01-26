#!/bin/bash

# Creator: Timothy Redaelli <tredaelli@archlinux.info>

# MAKE CRONTAB HAPPY
export PATH=/usr/local/bin:/usr/bin:/bin

# CONFIG
aurgitclone=/home/td123/tmp/aurgitclone
aurgittmp=/home/td123/tmp/aursrcpkgs

# PROCESSING
cd "$aurgitclone"

while read -r command tar; do
	package=$(basename "$tar" ".tar.gz")
	case "$command" in
		"*deleting")
			rm -rf "$package"/
			;;
		">f"*)
			rm -rf "$package"/
			mkdir "$package"/
			tar --transform "s,^$package/,," -C "$package"/ -xf "$aurgittmp/$tar"
			;;
	esac
done < <(rsync -a --delete --include '*/' --include '*.tar.gz' --exclude '*' --inplace --itemize-changes --update aur.archlinux.org::unsupported "$aurgittmp"/)

# DIRS CLEANUP
find . -type d -empty -print0 | xargs -0 rmdir
find . -maxdepth 1 -mindepth 1 -type d -not -name .git -print0 | \
	while IFS='' read -d $'\0' -r package; do
		[ -f "$package"/PKGBUILD ] || rm -rf "$package"/
	done

# GIT IS DONE
git add -A
git commit -am "updated on $(date)"
git gc --auto
git push origin master
