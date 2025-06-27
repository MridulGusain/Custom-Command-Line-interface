**# 🐚 mysh - Custom Shell with GUI Notepad (Zenity-based)

A lightweight custom shell written in Bash that supports basic Unix-like commands, command history, and an integrated graphical notepad built using Zenity. This shell replicates familiar commands like `ls`, `cd`, and `mkdir` with custom implementations and provides a secure, user-friendly note editor with encryption options.

## 🚀 Features

### 🔧 Shell Commands
- `myls [-a] [-l] [dir]` — List files (with support for hidden and long format).
- `mycd [dir]` — Change the working directory.
- `mypwd` — Print the current working directory.
- `mymkdir [dir]` — Create a directory.
- `myrmdir [dir]` — Remove an empty directory.
- `myhistory` — View command history.
- `exit` — Exit the shell.

### 📝 Notepad GUI (Zenity)
- **Create New Note** — Create and save a `.txt` note.
- **Open Note** — Edit and update an existing note.
- **Delete Note** — Remove `.txt` or encrypted `.gpg` notes.
- **List Notes** — View all notes in the GUI.
- **Encrypt Note** — Secure any note with a password using GPG.
- **Decrypt & Open Encrypted Note** — Unlock and edit encrypted notes.

## 🛠️ Setup & Run

### 🐧 Requirements
- Bash
- Zenity
- GPG (for encryption)

### 📂 Getting Started

```bash
 Notes
All notes are stored in the notepad_gui_files/ directory.

Encrypted notes use GPG symmetric encryption (.gpg files).

Shell history is logged in mysh_history.log.

👨‍💻 Authors
Mridul Gusain
