#!/bin/bash


# ==== Setup ====
CURRENT_DIR="$PWD"
HISTORY_FILE="mysh_history.log"
NOTEPAD_DIR="./notepad_gui_files"
mkdir -p "$NOTEPAD_DIR"
> "$HISTORY_FILE"

COMMANDS=("myls" "mycd" "mypwd" "mymkdir" "myrmdir" "myhistory" "notepad" "exit")

myls() {
    local show_hidden=false
    local long_format=false
    local dir="."

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a) show_hidden=true ;;
            -l) long_format=true ;;
            *) dir="$1" ;;
        esac
        shift
    done

    [[ ! -d "$dir" ]] && echo "myls: $dir: No such directory" && return 1

    for file in "$dir"/* "$dir"/.*; do
        [[ -e "$file" ]] || continue
        basename="$(basename "$file")"
        if [[ "$show_hidden" == false && "$basename" == .* ]]; then
            continue
        fi

        if [[ "$long_format" == true ]]; then
            perms=$(stat -c "%A" "$file")
            size=$(stat -c "%s" "$file")
            mtime=$(stat -c "%y" "$file" | cut -d'.' -f1)
            echo "$perms $size $mtime $basename"
        else
            echo "$basename"
        fi
    done
}

mycd() {
    if [[ -z "$1" ]]; then
        CURRENT_DIR="$HOME"
    elif [[ -d "$1" ]]; then
        CURRENT_DIR="$(realpath "$1")"
    else
        echo "mycd: $1: No such directory"
        return
    fi
    cd "$CURRENT_DIR" || return
}

mypwd() {
    echo "$CURRENT_DIR"
}

mymkdir() {
    if [[ -z "$1" ]]; then
        echo "mymkdir: missing operand"
    else
        mkdir -p "$1" 2>/dev/null || echo "mymkdir: cannot create directory '$1'"
    fi
}

myrmdir() {
    if [[ -z "$1" ]]; then
        echo "myrmdir: missing operand"
    elif [[ ! -d "$1" ]]; then
        echo "myrmdir: $1: No such directory"
    else
        rmdir "$1" 2>/dev/null || echo "myrmdir: $1: Directory not empty"
    fi
}

myhistory() {
    echo "Command History (saved in $HISTORY_FILE):"
    cat "$HISTORY_FILE"
}

# ==== GUI Notepad using Zenity ====
notepad_gui() {
    while true; do
        choice=$(zenity --list --title="CLI Notepad" \
            --column="Action" \
            "Create New Note" \
            "Open Note" \
            "Delete Note" \
            "List Notes" \
            "Encrypt Note" \
            "Decrypt and Open Encrypted Note" \
            "Back to mysh")

        case "$choice" in
            "Create New Note")
                filename=$(zenity --entry --title="New Note" --text="Enter note name:")
                if [ -n "$filename" ]; then
                    content=$(zenity --text-info --editable --title="Editing: $filename" --width=600 --height=400)
                    if [ $? -eq 0 ]; then
                        echo "$content" > "$NOTEPAD_DIR/$filename.txt"
                        zenity --info --text="Note saved as $filename.txt"
                    fi
                fi
                ;;

            "Open Note")
                file=$(zenity --file-selection --title="Select a note to open" --filename="$NOTEPAD_DIR/" --file-filter="*.txt")
                if [ -f "$file" ]; then
                    updated_content=$(zenity --text-info --editable --title="Editing: $(basename "$file")" --width=600 --height=400 --filename="$file")
                    if [ $? -eq 0 ]; then
                        echo "$updated_content" > "$file"
                        zenity --info --text="Note updated."
                    fi
                fi
                ;;

            "Delete Note")
                file=$(zenity --file-selection --title="Select a note to delete" --filename="$NOTEPAD_DIR/" --file-filter="*.txt *.gpg")
                if [ -f "$file" ]; then
                    rm "$file"
                    zenity --info --text="Note deleted."
                fi
                ;;

            "List Notes")
                files=$(ls "$NOTEPAD_DIR")
                zenity --info --title="All Notes" --text="Notes:\n$files"
                ;;

            "Encrypt Note")
                file=$(zenity --file-selection --title="Select a note to encrypt" --filename="$NOTEPAD_DIR/" --file-filter="*.txt")
                if [ -f "$file" ]; then
                    pass=$(zenity --password --title="Enter Password for Encryption")
                    if [ -n "$pass" ]; then
                        gpg --batch --yes --passphrase "$pass" -c "$file" && rm "$file"
                        zenity --info --text="File encrypted and original deleted.\nSaved as: $(basename "$file").gpg"
                    fi
                fi
                ;;

            "Decrypt and Open Encrypted Note")
                file=$(zenity --file-selection --title="Select an encrypted note" --filename="$NOTEPAD_DIR/" --file-filter="*.gpg")
                if [ -f "$file" ]; then
                    pass=$(zenity --password --title="Enter Password to Decrypt")
                    temp_file=$(mktemp)
                    gpg --batch --yes --passphrase "$pass" -o "$temp_file" -d "$file" 2>/dev/null

                    if [ $? -eq 0 ]; then
                        updated_content=$(zenity --text-info --editable --title="Editing: $(basename "$file")" --width=600 --height=400 --filename="$temp_file")
                        if [ $? -eq 0 ]; then
                            echo "$updated_content" > "$temp_file"
                            gpg --batch --yes --passphrase "$pass" -c "$temp_file" && mv "$temp_file.gpg" "$file"
                            rm "$temp_file"
                            zenity --info --text="Encrypted note updated successfully."
                        else
                            rm "$temp_file"
                        fi
                    else
                        rm "$temp_file"
                        zenity --error --text="Decryption failed. Wrong password?"
                    fi
                fi
                ;;

            "Back to mysh")
                break
                ;;
        esac
    done
}

# ==== Autocomplete Setup ====
_mysh_autocomplete() {
    COMPREPLY=()
    local curr_word="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(compgen -W "${COMMANDS[*]}" -- "$curr_word"))
}
complete -F _mysh_autocomplete mysh_run


# ==== Shell Wrapper Function ====
mysh_run() {
    while true; do
        read -e -p "mysh> " input
        [[ -z "$input" ]] && continue
        echo "$input" >> "$HISTORY_FILE"

        IFS=' ' read -r -a tokens <<< "$input"
        cmd="${tokens[0]}"
        args=("${tokens[@]:1}")

        case "$cmd" in
            myls) myls "${args[@]}" ;;
            mycd) mycd "${args[@]}" ;;
            mypwd) mypwd ;;
            mymkdir) mymkdir "${args[@]}" ;;
            myrmdir) myrmdir "${args[@]}" ;;
            myhistory) myhistory ;;
            notepad) notepad_gui ;;
            exit) echo "Exiting mysh..."; break ;;
            *) echo "Unknown command: $cmd" ;;
        esac
    done
}
mysh_run
