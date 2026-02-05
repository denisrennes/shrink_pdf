# shrink_pdf

**shrink_pdf** reduces the size of some unnecessarily large PDF files, without any noticeable loss of quality, and without using a website.  

You can use either:  

* The **"Shrink PDF" context menu** for PDF files in the file manager **Nemo**: "right-click" on selected PDF files.
* The command line: **shrink_pdf  [ files ] ...**  

If the PDF file size has actually been reduced, it will replace the original. The original file is renamed "... .ORIGINAL.pdf" (for English or French language).  
If the PDF file could not be reduced by at least 1%, it means that it is already as small as possible: shrink_pdf will display a message and leave the file unchanged.

Today shrink_pdf exists in English and French languages but it is easy to translate in another language, using the gen_mo.sh script provided in the package.


### Why?
Some PDF files are so large, that you you cannot send them as email attachments or upload them to a website.  

This happens typically with some scanned documents, although this depends on the scanning software: 

- Xsane often produces unnecessarily large PDF files.
- Simple Scan, the default GNOME document scanner, does not produce large PDF files but sometimes the result is not good, so some users install Xsane.


### Requirements
- **gs** command, from Ghostscript: present in most Linux distributions.
- **bc** command, from Basic Calulator: present in most Linux distributions.
- **Bash** : present in most Linux distributions
- Optional but recommended: **Nemo** file manager, to use the context menu entry ("right-click" menu) in the file manager.  
        It is the default file manager for some Linux distributions like Linux Mint, but can be installed on others like Ubuntu.

### Installation:
- Clone the GitHub repository or download the package from the GitHub project last release.
- Run `./install.sh` .

You can then delete the directory where you cloned or downloaded the GitHub repository.

### Uninstallation:
Delete these files:

- `'/usr/bin/shrink_pdf'`
- `'/usr/share/nemo/actions/shrink_pdf.nemo_action'`
- `'/usr/share/locale/fr/shrink_pdf.mo'`

### Under the hood
**shrink_pdf** is using a Ghostscript command.  See https://www.digitalocean.com/community/tutorials/reduce-pdf-file-size-in-linux



Coming "soon"...
- **gen_mo.sh** improvement for translation in other languages by the user.
- man pages (doc for the command)
- context menu (right-click) in *Nautilus*, the default file manager in Ubuntu.
- create a .deb package
