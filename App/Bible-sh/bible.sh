#!/bin/sh

sysdir=/mnt/SDCARD/.tmp_update
view_book_option="1. View Book"
view_chapter_option="2. View Chapter"
view_verse_option="3. View Verse"
dedicatory_option="4. View Dedicatory"
welcome_option="5. Welcome Menu (15s)"
about_option="6. About Menu (15s)"
exit_option="7. Exit"

main() {
    appdir=$(dirname "$0")
    kjvdir="$appdir/kjv"
    bookdir="$kjvdir/books"
    scriptdir="$appdir/scripts"
    csvfile="$appdir/settings.csv"

    # Source the csv.sh script
    . "$scriptdir/csv.sh"

    welcome_screen 7

    local option
    while true; do
        option=$(view_menu)
        > "$csvfile"
        case $option in
            $view_book_option)
                book_text=$(select_book_text)
                view_text "$book_text"
                ;;
            $view_chapter_option)
                book_text=$(select_book_text)
                chapter_text=$(select_chapter_text "$book_text")
                view_text "$chapter_text"
                ;;
            $view_verse_option)
                book_text=$(select_book_text)
                chapter_text=$(select_chapter_text "$book_text")
                verse_text=$(select_verse_text "$chapter_text")
                view_text "$verse_text"
                ;;
            $dedicatory_option)
                view_dedicatory
                ;;
            $welcome_option)
                welcome_screen 15
                ;;
            $about_option)
                about_screen 15
                ;;
            *)
                echo "Exiting Bible.sh"
                exit 0
                ;;
        esac
    done
}

welcome_screen() {
    clear
    cat << "EOF"
#####  # #####  #      ######     ####  #    #
#    # # #    # #      #         #      #    #
#####  # #####  #      #####      ####  ######
#    # # #    # #      #              # #    #
#    # # #    # #      #      ## #    # #    #
#####  # #####  ###### ###### ##  ####  #    #



                        ,   ,
                       /////|
                      ///// |
                     /////  |
                    |~~~| | |
                    |===| |/|
                    | B |/| |
                    | I | | |
                    | B | | |
                    | L |  /
                    | E | /
                    |===|/
               jgs  '---'



"Thy word is a lamp unto my feet, and a light unto my path."
- Psalm 119:105
EOF
    sleep $1
    clear
}

about_screen() {
    clear
    cat << "EOF"
Bible.sh - A Simple Bible Reader


Credits

King James Bible Texts
Source: https://archive.org/details/kjv-text-files
License: Public Domain

ASCII Art
Source: https://www.asciiart.eu/religion/christianity

Bible Sticker Icon
Source: Icon by Icons8 (https://icons8.com)
License: Universal Multimedia License Agreement for Icons8

Bible.sh
Author: Kyle Eichlin
Source: https://github.com/likeich/bible-sh
License: MIT License
EOF
    sleep $1
    clear
}

make_selection() {
    local prompt="$1"
    local options="$2"
    local selection=""

    if [ -x "$sysdir/script/shellect.sh" ]; then
        selection=$(echo -e "$options" | $sysdir/script/shellect.sh -t "$prompt" -b "Press A to confirm.")
    else
        echo "$prompt" >&2
        echo "$options" >&2
        printf "" | cat  # Force a buffer flush
        echo "Enter your choice (type the exact name):" >&2
        read selection
    fi

    echo "$selection"
}

view_menu() {
    echo $(make_selection "The Holy Bible" "$view_book_option\n$view_chapter_option\n$view_verse_option\n$dedicatory_option\n$welcome_option\n$about_option\n$exit_option")
}

view_text() {
    local text="$1"

    if [ -z "$text" ]; then
        echo -e "${RED}Error: No text provided to display${NC}"
        sleep 4
        return
    fi

    echo "$text" | less
}

view_dedicatory() {
    local filepath="$bookdir/Dedicatory.txt"
    view_text "$(cat "$filepath")"
}

select_book_text() {
    book=$(make_selection "Select a book of the Bible:" "$(cat "$kjvdir/booklist.txt")")
    add_entry "$csvfile" "current_book" "$book"
    filepath="$bookdir/$book.txt"
    echo "$(cat "$filepath")"
}

select_chapter_text() {
    local book_text="$1"
    local chapter_text=""

    # Extract chapter headings from the book text
    local chapter_headings=$(echo "$book_text" | awk '/CHAPTER [0-9]+/ {print $0}')

    # Let user make a selection based on extracted headings
    current_book=$(get_value "$csvfile" "current_book")
    local chapter=$(make_selection "Select chapter from $current_book:" "$chapter_headings")
    add_entry "$csvfile" "current_chapter" "$chapter"

    # Extract the text for the selected chapter
    chapter_text=$(echo "$book_text" | awk -v chap="$chapter" '
        BEGIN { found = 0 }
        $0 ~ chap { found = 1; printit = 1 }
        found && /CHAPTER [0-9]+/ { if ($0 !~ chap) { printit = 0; found = 0 } }
        printit { print }
    ')

    # Output the extracted chapter text
    if [ -z "$chapter_text" ]; then
        echo "No text found for the chapter."
    else
        echo "$chapter_text"
    fi
}

select_verse_text() {
    local chapter_text="$1"
    local verse_text=""

    # Extract verses from the chapter text
    local verse_headings=$(echo "$chapter_text" | awk '/^[0-9]+ / {print $1}')

    current_book=$(get_value "$csvfile" "current_book")
    current_chapter=$(get_value "$csvfile" "current_chapter")
    # Let user make a selection based on extracted verses
    local verse=$(make_selection "Select verse from $current_book $current_chapter:" "$verse_headings")
    add_entry "$csvfile" "current_verse" "$verse"

    # Extract the text for the selected verse
    verse_text=$(echo "$chapter_text" | awk -v ver="$verse" '$0 ~ "^" ver "[^0-9]"')

    # Output the extracted verse text
    if [ -z "$verse_text" ]; then
        echo "No text found for the verse."
    else
        printf "%s\n\n- %s %s VERSE %s\n" "$verse_text" "$current_book" "$current_chapter" "$verse"
    fi
}

main "$@"
