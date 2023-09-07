# M2HTML - Documentation System for MATLAB files in HTML

This toolbox is intended to provide automatic generation of M-files 
documentation in HTML. It reads each M-file in a set of directories
(eventually recursively) to produce a corresponding HTML file containing
synopsis, H1 line, help, function calls and called functions with 
hypertext links, syntax highlighted source code with hypertext, ...

> [!WARNING]
> This toolbox has been written between 2001 and 2005 (for MATLAB 5.3).
> It probably requires a complete rewrite and there are many great features
> that could be added, taking advantage of the very different web development
> landscape than two decades ago. This means that **contributions via pull
> requests or feature requests via opening issues are very much welcome**.

Here is a summary of the features of the toolbox:
* extraction of H1 lines and help of each function
* hypertext documentation with functions calls and called functions
* extraction of subfunctions (hypertext links)
* ability to work recursively over the subdirectories of a file tree
* ability to choose whether the source code must be included or not
* syntax highlighting of the source code (as in the MATLAB Editor)
* ability to choose HTML index file name and extension
* automatic creation of a TODO list (using `% TODO %` syntax)
* "skins": fully customizable output thanks to HTML templates (see below)

M2HTML may be particularly useful if you want to study code written by
someone else (a downloaded toolbox, ...) because you will obtain an
hypertext documentation in which you can easily walk through, thanks
to your web browser.

## INSTALLATION

0. Requirements:
  * MATLAB 5.3 or above, or GNU Octave
  * Operating system: any.

1. Download the most recent release from this website and extract files in your MATLAB Repository `/home/foo/matlab/` (or clone this repository) :
```
unzip m2html.zip
```
2. Add the `m2html` directory in your MATLAB path:
```matlab
addpath /home/foo/matlab/m2html/
```  
3. Ready to use !
```matlab
help m2html
```

If you want to generate dependency graphs, you need to install [GraphViz](https://www.graphviz.org/),
an open source graph visualization software.

## LICENSE

Please read the [`LICENSE`](LICENSE) file for license details.

## TUTORIAL
 
One *important* thing to take care of is the MATLAB current directory: `m2html` 
must be launched one directory above the directory your wanting to generate 
documentation for.

For example, imagine your MATLAB code is in the directory `/home/foo/matlab/`
(or `C:\foo\matlab\` on Windows), then you need to go in the `foo` directory:
 
```matlab
cd /home/foo  % (or cd C:\foo on Windows)
```
and launch m2html with the command:
```matlab 
m2html('mfiles','matlab', 'htmldir','doc');
```

It will populate all the m-files just within the `matlab` directory, will parse
them and then will write in the newly created `doc` directory (`/home/foo/doc/`,
resp., `C:\foot\doc\`) an HTML file for each M-file.
 
You can also specify several subdirectories using a cell array of directories:
```matlab
m2html('mfiles',{'matlab/signal' 'matlab/image'}, 'htmldir','doc');
``` 
If you want m2html to walk recursively within the `matlab` directory then you 
need to set up the recursive option:
```matlab
m2html('mfiles','matlab', 'htmldir','doc', 'recursive','on');
```
You can also specify whether you want the source code to be displayed in the 
HTML files (do you want the source code to be readable from everybody ?):
```matlab
m2html('mfiles','matlab', 'htmldir','doc', 'source','off');
``` 
You can also specify whether you want global hypertext links (links among 
separate MATLAB directories). By default, hypertext links are only among 
functions in the same directory (be aware that setting this option may 
significantly slow down the process).
```matlab
m2html('mfiles','matlab', 'htmldir','doc', 'global','on');
```

Other parameters can be tuned for your documentation, see the M2HTML help:
```matlab 
help m2html
```

## CUSTOMIZATION

This toolbox uses the HTML Template class so that you can fully customize the
output. You can modify `.tpl` files in `templates/blue/` or create new templates 
in a new directory (`templates/othertpl`).

You can then use the newly created template in specifying it:
```matlab
m2html( ... , 'template','othertpl');
```

M2HTML will use your `.tpl` files (`master`, `mdir`, `mfile`, `graph`, `search` and 
`todo.tpl`) and will copy all the other files (CSS, images, ....) in the root
directory of the HTML documentation.

