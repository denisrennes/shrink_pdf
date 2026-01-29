# shrink_pdf

This tool can reduce the size of PDF files, sometimes considerably, without any noticeable loss of quality, at least for standard scanned documents.  

It is useful because PDF files can be unnecessarily large, for example when they are the result of scanning. (Although this depends on the scanning software and their settings.)  
Large PDF files can be a problem, for example when you cannot send it as an attached document in an email, or upload it to a web site, because it is too big.

It is using a Ghostscript command.  See https://www.digitalocean.com/community/tutorials/reduce-pdf-file-size-in-linux

##Usage:
- Command line: **shrink_pdf  [ files ] ...**
- ONLY if the file manager *Nemo* is present: use the "**shrink PDF"  context menu** entry of PDF files. ("right-click" on selected PDF files)

If the PDF file size has actually been reduced, it will replace the original. The original file is renamed "... .ORIGINAL.pdf".  
If the PDF file could not be reduced in size, it means it is already optimized. This tool will detect this and display a message, leaving the original PDF file unchanged.

## Requirements
- **gs** command (Ghostscript)
- **bc** command (Basic Calulator: present in most Linux distributions)
- Bash
- Optional: **Nemo** file manager, to use the context menu entry in the file manager.

## Installation:
- Clone the GitHub repository or download the package from the GitHub project.
- Run `./install.sh` .

You can then delete the directory where you cloned the GitHub repository.

## Uninstallation:
Delete these files:

- `'/usr/bin/shrink_pdf.sh'`
- `'/usr/share/nemo/actions/shrink_pdf.nemo_action'`
- `'/usr/share/locale/fr/shrink_pdf.mo'`

####To do
- Create man pages (doc for the command)
- make it work in *Nautilus*, the default file manager in Ubuntu.
- create a .deb package
