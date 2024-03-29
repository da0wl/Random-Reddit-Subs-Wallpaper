#!/bin/bash
#
# Compose and set a wallpaper from disc, URL or from top images on reddit.com.
# Edit the last line for a command that sets the wall in your window manager
#
# Usage:
# Use a local file.
# $ wallpaper /some/local/picture.jpg
#
# Fetch and use a file from an URL.
# $ wallpaper http://www.somesite.com/with/image.png
#
# Fetch a random current top image from reddit (not marked NSFW).
# Edit $REDDITSUBS below to set which subreddits to check for images.
# $ wallpaper
#
# Adapted from http://redd.it/kp7kr

################################################
###              Start Variables             ###
################################################
REDDITSUBS=(earthporn villageporn itookapicture specart ImaginaryLandscapes SpacePorn)
#REDDITSUBS=(ginger gonewild hotchickswithtattoos xsmall)
NSFW=0 				# NSFW Images 0=Never,1=Indifferent,2=Only
IMAGESIZE="(6/10)"		# How big should the foreground image be on the wallpaper?
ImageBorderSize=3		# How thick should the border be (0-100)
ImageBorderColor="#6b6a64"	# Color

################################################
###               End Variables              ###
################################################

function getSubFromArray {
	numSubs=${#REDDITSUBS[*]}        # Count how many elements in the array
	echo ${REDDITSUBS[$((RANDOM%numSubs))]}
}

function getRandomRedditImage {
	#This section needs to have logic added to respect the NSFW switch above
	cd "$TEMPDIR" || exit 1
	rndSub=`getSubFromArray`
	echo "Pulling recent random image from $rndSub"
	SOURCE=$(wget -q http://www.reddit.com/r/$rndSub/.rss -O- | \
             sed 's/<item>/\n&/g' | \
             grep -iv NSFW | \
             egrep -oi '[a-z]+://[^; ]*.(jpg|jpeg|png)' | \
             grep -v 'thumbs.reddit.com' | \
             shuf -n1)
	echo "Image URL: $SOURCE"
	IMAGE=$(basename "$SOURCE")
	wget -q "$SOURCE" -O "$IMAGE" || exit 1
	BG="${IMAGE//.*}_bg.${IMAGE##*.}"
	DEST="output.${IMAGE##*.}"
	echo "DEST: $DEST"
}

function transformImage {
	cd "$TEMPDIR" || exit 1
	RESOLUTION=$(xrandr 2>/dev/null | awk '/\*/ {print $1}')
	BGZOOM=$(echo "$RESOLUTION" | awk -Fx '{print $1*2 "x" $2*2}')
	BGOFFSET=$(echo "$RESOLUTION" | awk -Fx '{print "+" $1/3 "+" $2/3}')
	IMAGERES=$(echo "$RESOLUTION" | awk -Fx '{print $1*'$IMAGESIZE' "x" $2*'$IMAGESIZE'}')
	cp "$IMAGE" "$BG" || exit 1
	mogrify \( -modulate 25,0,100 \) \
		\( -resize $BGZOOM^ \) \
		\( -crop "$RESOLUTION""$BGOFFSET" \) \
		\( -blur 128 \) -quality 96 "$BG"

	mogrify \( -resize ${IMAGERES} \) \
		\( -bordercolor $ImageBorderColor -border $ImageBorderSize \) "$IMAGE"
	composite -gravity center "$IMAGE" "$BG" "$DEST"
	mv $DEST /home/`whoami`/Pictures/
}

function mkTempWorkingDir {
	TEMPDIR=$(mktemp -d)
	echo "TempDir: $TEMPDIR"
	cd "$TEMPDIR" || exit 1
	trap 'rm -rf $TEMPDIR' EXIT
}

function setwallpaper {
	#Need to add logic here for Ubuntu/other distro identification & processing
	gconftool-2 -t string -s /desktop/gnome/background/picture_filename /home/`whoami`/Pictures/$DEST
}

mkTempWorkingDir
getRandomRedditImage
transformImage
setwallpaper





