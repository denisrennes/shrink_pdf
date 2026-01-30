# shrink_pdf

This tool reduces the size of PDF files, sometimes considerably, without any noticeable loss of quality, at least for common documents, and without using a website (which can sometimes be dubious...).  

This is useful because PDF files are often unnecessarily large, typically when they are scanned (although this depends on the scanning software and its settings).  
Large PDF files can be problematic, for example when you cannot send them as email attachments or upload them to a website because they are too large.


##Usage:
- Command line: **shrink_pdf  [ files ] ...**
- ONLY if the file manager *Nemo* is present: use the "**shrink PDF"  context menu** entry of PDF files. ("right-click" on selected PDF files)

If the PDF file size has actually been reduced, it will replace the original. The original file is renamed "... .ORIGINAL.pdf".  
If the PDF file could not be reduced in size, it means it is already optimized. This tool will detect this and display a message, leaving the original PDF file unchanged.

## Requirements
- **gs** command (Ghostscript)
- **bc** command (Basic Calulator: present in most Linux distributions)
- **Bash**
- **Nemo** file manager, to use the context menu entry in the file manager.

## Installation:
- Clone the GitHub repository or download the package from the GitHub project.
- Run `./install.sh` .

You can then delete the directory where you cloned or downloaded the GitHub repository.

## Uninstallation:
Delete these files:

- `'/usr/bin/shrink_pdf.sh'`
- `'/usr/share/nemo/actions/shrink_pdf.nemo_action'`
- `'/usr/share/locale/fr/shrink_pdf.mo'`

## Under the hood
**shrink_pdf** is using a Ghostscript command.  See https://www.digitalocean.com/community/tutorials/reduce-pdf-file-size-in-linux

####To do
- Create man pages (doc for the command)
- make it work in *Nautilus*, the default file manager in Ubuntu.
- create a .deb package
