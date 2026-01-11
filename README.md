# shrink_pdf

Adds a "PDF shrink" to the context menu (aka "right-click menu") of PDF files **in *Nemo*, the default File Manager of Linux Mint.**  

PDF files can be unnecessarily large, for example when they are the result of scanning. (Although this depends on the scanning software and its settings .)  
This can be a problem, for example when this prevents to send the PDF file as an attached document in an email.

This tool can reduce the size of PDF files, sometimes considerably, without any noticeable loss of quality, at least for standard scanned documents.

It is using a Ghostscript command.  See https://www.digitalocean.com/community/tutorials/reduce-pdf-file-size-in-linux

If the PDF file is already optimized, it cannot be reduced. This tool will detect this and display a message, leaving the original PDF file unchanged.

## Requirements
- Bash
- Nemo File Manager
- Ghostscript

## Installation:
Clone the GitHub repository and run `./install.sh` .

You can then delete the directory where you cloned the GitHub repository.

## Uninstallation:
Delete the files `'/usr/local/bin/shrink_pdf.sh'` and `'/usr/share/nemo/actions/shrink_pdf.nemo_action'`

####To do
 - multi-language feature (multi-language Bash script)
- make it work in *Nautilus*, the default file manager in Ubuntu.
- create a .deb package


