#!/bin/sh

sysdir=/mnt/SDCARD/.tmp_update

main() {
    appdir=$(dirname "$0")
    kjvdir="$appdir/kjv"
    bookdir="$kjvdir/books"
    scriptdir="$appdir/scripts"
    csvfile="$appdir/settings.csv"

    # Source the csv.sh script
    . "$scriptdir/csv.sh"

    welcome_screen

    local option
    while true; do
        option=$(view_menu)
        > "$csvfile"
        case $option in
            "1. View Book")
                book_text=$(select_book_text)
                view_text "$book_text"
                ;;
            "2. View Chapter")
                book_text=$(select_book_text)
                chapter_text=$(select_chapter_text "$book_text")
                view_text "$chapter_text"
                ;;
            "3. View Verse")
                book_text=$(select_book_text)
                chapter_text=$(select_chapter_text "$book_text")
                verse_text=$(select_verse_text "$chapter_text")
                view_text "$verse_text"
                ;;
            *)
                echo "Exiting Bible.sh"
                exit 0
                ;;
        esac
    done
}

welcome_screen() {
    cat << "EOF"
 ____  _ _     _            _
|  _ \(_) |   | |          | |
| |_) |_| |__ | | ___   ___| |__
|  _ <| | '_ \| |/ _ \ / __| '_ \
| |_) | | |_) | |  __/_\__ \ | | |
|____/|_|_.__/|_|\___(_)___/_| |_|

==================================





             __
            /_/\/\
            \_\  /
            /_/  \
            \_\/\ \
               \_\/





"Thy word is a lamp unto my feet, and a light unto my path."
- Psalm 119:105
EOF
    sleep 7
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
    echo $(make_selection "The Holy Bible" "1. View Book\n2. View Chapter\n3. View Verse\n4. Exit")
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
