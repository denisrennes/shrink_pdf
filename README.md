# shrink_pdf

**shrink_pdf** is a Linux tool that reduces the size of unnecessarily large PDF files without any noticeable loss of quality and without having to go through a website.  

Usage:

* The command line: **shrink_pdf  [OPTION] FILE   [FILE...]**  
(For help, type `shrink_pdf --help` or `man shrink_pdf`)  

* If the file manager ***Nemo*** is present: a new **"Shrink PDF" context menu** is added in *Nemo*. ("right-click" menu on selected PDF files.)

If the PDF file size has actually been reduced by **at least 10 %**, it will replace the original. The original file is renamed `... .ORIGINAL.pdf` (for English or French language).  
Otherwise, shrink_pdf will display a message and leave the file unchanged. The file is probably already as small as possible.  

Today, this tool works in **English** (default) or **French**.

### Why use shrink_pdf?
Some PDF documents are so large, that sometimes you cannot send them as email attachments or upload them to a website.  

This happens typically with some scanned documents, although this depends on the scanning software: 

- *Xsane* often produces unnecessarily large PDF files.
- *Simple Scan*, a.k.a. *Document Scanner,* does not produce large PDF files, but the results are sometimes unsatisfactory, leading some users to install *Xsane* .

### Requirements
- A Linux system.
- **gs** command, from Ghostscript: present in most Linux distributions.
- **bc** command, from Basic Calulator: present in most Linux distributions.
- **Bash** : present in most Linux distributions
- Optional: **Nemo** file manager, to use the context menu entry ("right-click" menu) in the file manager.  
        It is the default file manager for some Linux distributions like Linux Mint, but can be installed on others like Ubuntu.

### Installation:
- Download the package from the GitHub project last release or clone the GitHub repository: [https://github.com/denisrennes/shrink_pdf](https://github.com/denisrennes/shrink_pdf) 
- Run `./install.sh`   

You can then delete, now or later, the directory where you cloned or downloaded the GitHub repository.

### Uninstallation:
Run `./UN_install.sh`   

Or just delete these files:

- `'/usr/bin/shrink_pdf'`
- `'/usr/share/nemo/actions/shrink_pdf.nemo_action'`
- `'/usr/share/locale/fr/shrink_pdf.mo'`
- `'/usr/share/man/man1/shrink_pdf.1.gz'`
- `'/usr/share/man/fr/man1/shrink_pdf.1.gz'`

### Under the hood
**shrink_pdf** is using a Ghostscript command.  See https://aakashnand.com/til/compress-pdf-ghostscript/  
**shrink_pdf** makes this command easily accessible, displays the shrink rate, handles the shrinked or not shrinked result, as well as the original file renaming. 

### To do (maybe one day...)
- Create a .deb package
- Context menu (right-click) in *Nautilus*, the default file manager of *Gnome* or *Ubuntu* (I can't decide which *Nautilus* extension to use for *Nautilus* actions...)
- Improve `gen_mo.sh` for translation to other languages by the user?

