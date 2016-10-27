#!/bin/bash
#
#
#   converts videos (file or directory) to be playable in chormecast 1/2
#
#   Vesselin, 16.10.2016
#  
#
set -u
##########
# CONFIG #
##########
SUPPORTED_EXTENSIONS=('mkv' 'avi' 'mp4' '3gp' 'mov' 'mpg' 'mpeg' 'qt' 'wmv' 'm2ts' 'flv')

SUPPORTED_GFORMATS=('mov' 'Matroska')
SUPPORTED_VCODECS=('MPEG-4 AVC')
SUPPORTED_ACODECS=('AAC' 'MP3' 'Vorbis' 'Ogg')

# set the default vcoding and quality
DEFAULT_VCODEC="h264 -crf 18"

# default audio encoding and params
DEFAULT_ACODEC="libmp3lame -q:a 2"
DEFAULT_GFORMAT="matroska"
DEFAULT_EXTENSION="mkv"

#############
# FUNCTIONS #
#############
# @param $1 mixed  Needle  
# @param $2 array  Haystack
# @return  Success (0) if value exists, Failure (1) otherwise
# Usage: in_array "$needle" "${haystack[@]}"
# See: http://fvue.nl/wiki/Bash:_Check_if_array_element_exists
# additions
# check if string is substing (not equal) and  ignorring low/upper case and 
in_array() {
    local hay needle=$1
    shift
    for hay; do
      [[ "${needle,,}" == *"${hay,,}"* ]] && return 0
    done
    return 1
}

on_success() {
    echo ""
    FILENAME="$1"
    echo "- conversion succeeded"
    echo "- renaming original file as '$FILENAME.orginal"
    mv "$FILENAME" "$FILENAME.orginal"
}			


on_failure() {
    echo ""
    FILENAME="$1"
    echo "- failed to convert '$FILENAME' (or conversion has been interrupted)"
    echo "- deleting partially converted file..."
    rm "$FILENAME" &> /dev/null
}


process_file() {
	 FILENAME="$1" 
	echo "----------------------"
        echo "Processing: $FILENAME"
	playable="true" 

        # extension
        BASENAME=$(basename "$FILENAME")
        EXTENSION="${BASENAME##*.}"
        if ! in_array "$EXTENSION"  "${SUPPORTED_EXTENSIONS[@]}"; then
                echo "- not a video file, skipping"
                continue
        fi

	# general format
        INPUT_GFORMAT=`ffprobe -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 -hide_banner -v error "$FILENAME"`
	if in_array ${INPUT_GFORMAT%%,*} "${SUPPORTED_GFORMATS[@]}"; then 
                OUTPUT_GFORMAT=${INPUT_GFORMAT%%,*} 
		OUTPUT_EXTENSION=$EXTENSION
        else
                # if override format is specified, use it; otherwise fall back to default format
                OUTPUT_GFORMAT="$DEFAULT_GFORMAT"
		OUTPUT_EXTENSION=$DEFAULT_EXTENSION
		playable="false" 

        fi
        echo "- general: $INPUT_GFORMAT ----> $OUTPUT_GFORMAT"

        # video codec
	INPUT_VCODEC=`ffprobe -select_streams v:0 -show_entries stream=codec_long_name -of default=noprint_wrappers=1:nokey=1 -hide_banner -v error "$FILENAME" `
	if in_array "$INPUT_VCODEC" "${SUPPORTED_VCODECS[@]}"; then 
                OUTPUT_VCODEC="copy"
        else
                OUTPUT_VCODEC="$DEFAULT_VCODEC"
		playable="false"
        fi
        echo "- video: $INPUT_VCODEC ----> $OUTPUT_VCODEC"

        # audio codec
        INPUT_ACODEC=`ffprobe -select_streams a:0 -show_entries stream=codec_long_name -of default=noprint_wrappers=1:nokey=1 -hide_banner -v error "$FILENAME"`
        if in_array "$INPUT_ACODEC" "${SUPPORTED_ACODECS[@]}"; then 
                OUTPUT_ACODEC="copy"
        else
                OUTPUT_ACODEC="$DEFAULT_ACODEC"
		playable="false"
        fi
        echo "- audio: $INPUT_ACODEC ----> $OUTPUT_ACODEC"
	
	if [ $playable == "true" ]; then
                echo "- file should be playable by Chromecast!"
	else
		echo "- start convertion"
		$FFMPEG -loglevel error -stats -i "$FILENAME" -map 0 -scodec copy -vcodec $OUTPUT_VCODEC -acodec $OUTPUT_ACODEC -f $OUTPUT_GFORMAT "$FILENAME.chromecast.$OUTPUT_EXTENSION" && on_success "$FILENAME"  || on_failure "$FILENAME.chromecast.$OUTPUT_EXTENSION" 
		
        fi
}

################
# MAIN PROC    #
################

# test if `ffmpeg` is available
FFMPEG=`which ffmpeg`
if [ -z $FFMPEG ]; then
	echo 'Ffmpeg is not available, please install it'
	exit 1
fi

# if no argument then print help
if [ $# -lt 1 ]; then
	echo "provide file(s) or directory to ibe converted if needed, so they will be playable on chromecast 1/2"  	
	 echo "Usage: convert4chromecast.sh <videofile|directory> [ videofile|directory ... ]" 
	 exit 1
fi

for FILENAME in "$@"; do
	if ! [ -e "$FILENAME" ]; then
		echo "$FILENAME file not found, skipping..."
	elif [ -d "$FILENAME" ]; then
		echo "Found directory $FILENAME"
		for F in $(find "$FILENAME" -type f); do
			process_file "$F"
		done
	elif [ -f "$FILENAME" ]; then
		process_file "$FILENAME"
	fi
done
