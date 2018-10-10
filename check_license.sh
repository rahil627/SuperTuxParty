trim() {
    # remove leading whitespace characters
    var="${1#"${1%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    
    echo -n "$var"
}

function ProgressBar {
    PROGRESSBAR_LENGTH=$(($(tput cols)-2))
    progress=$(($1*100/$2))
    echo -ne '\033[32m[\033[34m'
    for i in $(seq 1 $PROGRESSBAR_LENGTH)
    do
	if (( $i < $(($progress*$PROGRESSBAR_LENGTH/100)) )); then
	    echo -n '#'
	else
	    echo -n ' '
	fi
    done
    echo -ne '\033[32m]\033[0m\r'
}

readarray -t FILES <<< $(find -type f -regextype posix-extended -regex '^.+?(\.png|\.jpg|\.escn|\.dae|\.hdr|\.ttf|\.blend)$')

# Blacklist: every file that should not be checked (regex)
BLACKLIST="^$"

# The Prefix used by find
PREFIX="./"

DIR=""

DIR_MARKDOWN='## '
FILE_MARKDOWN='### '

FILECOUNT=${#FILES[@]}
echo "Checking $FILECOUNT files"

LINECOUNT=$(wc -l <<< $(cat LICENSE-ART.md))
LINE=1

function checkFiles() {
    # Resolve files that are seperated by |
    readarray -td '|' FILEMASK <<< $1
    
    for file in "${FILEMASK[@]}"
    do
	# Expand special characters, e.g. * to full path(s), escape spaces and remove double /
	FILEPATH=$(echo "$2/"$(trim "$file" | sed 's/ /\\ /g') | tr -s "//" "/")

	# convert multiple files to array, e.g. image* matches image.blend & image.png -> (image.blend image.png)
	readarray -t ARRAY <<< $(echo $FILEPATH" " | grep -o -E '([^ ]|\\ )*[^\\] ')
	# Iterate over all paths
	for f in "${ARRAY[@]}"
	do
	    # Remove all files that are equal to $f
	    for i in "${!FILES[@]}"
	    do
		if [[ "${FILES[$i]}" = $(echo $f | sed 's/\\ / /g') ]]; then
		    unset "FILES[i]"
		fi
	    done
	done
    done
}

while read -r line
do
    # Check markdown type
    if [[ ${line:0:3} == $DIR_MARKDOWN ]]; then
	DIR=$(echo ${line:3} | sed 's/ /\\ /g')

	checkFiles "${line:3}" "$PREFIX"
    elif [[ ${line:0:4} == $FILE_MARKDOWN ]]; then
	checkFiles "${line:4}" "$PREFIX$DIR"
    fi

    ((LINE++))
    ProgressBar $LINE $LINECOUNT
done <<< $(cat LICENSE-ART.md)
# Newline after progress bar
echo

# Show missing file menu (All files that are still in our array)
(
    echo -e "\033[32mLicense found: "$(($FILECOUNT-${#FILES[@]}))" files\033[31m"
    for file in "${FILES[@]}"
    do
	if ! [[ $file =~ $BLACKLIST ]]; then
	    echo "No License found for: $file"
	fi
    done
    echo -ne "\033[0m"
) | less -r

