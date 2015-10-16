#!/bin/bash
###################### Variables ######################
# Grab first aritcle number from CLI
articleToSearch=$1
# Destintion for Results
resultDest=$2
# Prefix the following URL to articles
appleSupportURL=https://support.apple.com/en-us/
#################### Do Not Modify ####################
# Display help if asked
if [[ $1 == *"-h"* ]] || [[ $1 == *"-help"* ]]; then
        echo "#########################"
        echo "Welcome to findAppleDocs"
        echo "#########################"
        #echo -e "\n"
        echo "Usage:
        findAppleDocs HT205001 /path/to/results.(csv)(md)"
        #echo -e "\n"
        echo "Info:
        The Article Number supplied will be pre-fixed with 'https://support.apple.com/en-us/'"
        echo "Format:
        Ending the destination with .csv or .md will adjust the output accordingly."
        #echo -e "\n"
        echo "Location:
        If you don't specify a full path, the file will be placed in the current working directory."
        exit 0
fi
# Exit if no starting article given
if [[ -z "$1" ]]; then
        echo "Missing parameter! Use -h or --help for more info"
        exit 3
fi
# Inform user of upcomming stdout
if [[ -z "$2" ]]; then
        echo "WARNING! The output will be displayed in the stdout, see -h or --help for options"
        sleep 5
else
# Will not write to existing file
if [[ -f $resultDest ]]; then
    read -p "Destination file already exsits! Would you like to overwrite it? (y/n): " yn
    case $yn in
        [Yy]* ) echo -n > $resultDest ;;
        [Nn]* ) exit 9;;
        * ) echo "Please specify y or n";;
    esac
else
        # Create file
        touch $resultDest
fi
# Check file is writable
if [[ ! -w $resultDest ]]; then
        echo "Path for results invalid - file not writable"
        exit 10
fi
fi
# If destination is Markdown, format as table
if [[ "$resultDest" == *".md" ]]; then
        echo "| URL | Title |" >> "$resultDest"
        echo "| --- | --- |" >> "$resultDest"
fi
# Start the count at 0
failedSearches=0
# Increment the Article Number when called
incrementArticle() {
        oldArticle=$articleToSearch
        number=$(echo "$oldArticle" | tr -d [:alpha:])
        string=$(echo "$oldArticle" | tr -d [:digit:])
        articleToSearch=$string$(($number+1))
}
# Grab page info when called
grabInfo() {
       pageTitle=`curl -s $appleSupportURL$articleToSearch | grep "<title>" | sed 's# - Apple Support</title>##' | sed 's#[[:blank:]][[:blank:]][[:blank:]]<title>##'`
        if [[ "$pageTitle" != *"404"* ]] && [ "$pageTitle" != "" ]; then
                failedSearches=0
                if [[ "$resultDest" == *".csv" ]]; then
                        echo "$appleSupportURL$articleToSearch,$pageTitle" >> "$resultDest"
                elif [[ "$resultDest" == *".md" ]]; then
                        echo "| $appleSupportURL$articleToSearch | $pageTitle |" >> "$resultDest"
                else
                        echo "$appleSupportURL$articleToSearch - $pageTitle"
                fi
        else
                failedSearches=$[$failedSearches +1]
        fi
}
# Searches each possible article URL, printing any return which is valid.  Will self-exit after 50 failed searches
while [ $failedSearches -lt 50 ];
do
        grabInfo
        incrementArticle
done
