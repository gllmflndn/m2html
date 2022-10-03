function mlx2html(mlxfilename, htmlfilename)
% Convert Live Script (*.mlx) file to HTML
% FORMAT mlx2html(mlxfilename, htmlfilename)

% Copyright (C) 2020 Guillaume Flandin

%-Input arguments
%--------------------------------------------------------------------------
if nargin < 2
    htmlfilename = [mlxfilename(1:end-3) 'html'];
end

%-Parse MLX file
%--------------------------------------------------------------------------
[mlx, rels] = mlxparse(mlxfilename);

%-Get title
%--------------------------------------------------------------------------
i = find(arrayfun(@(x)strcmp(x.properties.style,'title'),mlx));
if numel(i) > 0
    title = mlx(i(1)).content.string;
else
    title = mlxfilename;
end

%-Export MLX file as HTML
%--------------------------------------------------------------------------
fid = fopen(htmlfilename,'wt');
if fid == -1
    error('Cannot open HTML file for writing');
end
fprintf(fid,'<!DOCTYPE html>\n');
fprintf(fid,'<html>\n');
fprintf(fid,'<head>\n');
fprintf(fid,'  <title>%s</title>\n',title);
fprintf(fid,'  <meta charset="utf-8">\n');
fprintf(fid,'  <meta name="viewport" content="width=device-width, initial-scale=1">\n');
fprintf(fid,'  <meta name="description" content="%s">\n',title);
fprintf(fid,'  <meta name="generator" content="m2html &copy; 2003-2022 https://github.com/gllmflndn/m2html">\n');
fprintf(fid,'  <style>\n');
fprintf(fid,'    body {background-color: white;}\n');
fprintf(fid,'    h1,h2,p,ol,ul,pre {color: black;}\n');
fprintf(fid,'    pre {background-color: #EEE; padding: 1em;}\n');
fprintf(fid,'  </style>\n');
fprintf(fid,'  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.min.css" integrity="sha384-zB1R0rpPzHqg7Kpt0Aljp8JPLqbXI3bhnPWROx27a9N0Ll6ZP/+DiW/UqRcLbRjq" crossorigin="anonymous">\n');
fprintf(fid,'  <script defer src="https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.min.js" integrity="sha384-y23I5Q6l+B6vatafAwxRu/0oK/79VlbSz7Q9aiSZUvyWYIYsd+qj+o24G5ZU2zJz" crossorigin="anonymous"></script>\n');
fprintf(fid,'  <script defer src="https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/contrib/auto-render.min.js" integrity="sha384-kWPLUVMOks5AQFrykwIup5lo0m3iMkkHrD0uJ4H5cjeGihAutqP0yW0J6dpFiVkI" crossorigin="anonymous"\n');
fprintf(fid,'      onload="renderMathInElement(document.body);"></script>\n');
fprintf(fid,'</head>\n');
fprintf(fid,'<body>\n');
list = false;
for i=1:numel(mlx)
    switch mlx(i).properties.style
        case 'title'
            fmt = '<h1>%s</h1>\n';
        case 'heading'
            fmt = '<h2>%s</h2>\n';
        case 'heading2'
            fmt = '<h3>%s</h3>\n';
        case 'heading3'
            fmt = '<h4>%s</h4>\n';
        case 'section'
            fmt = '<hr>%s\n';
        case 'code'
            fmt = '<pre>%s</pre>\n'; % %TODO% syntax highlighting https://highlightjs.org/
        case 'text'
            fmt = '<p>%s</p>\n';
        case 'ListParagraph'
            if mlx(i).properties.list == 1
                pre = '<ul>'; post = '</ul>';
            else
                pre = '<ol>'; post = '</ol>';
            end
            if list, pre = ''; else, list = true; end
            if i < numel(mlx) && strcmp(mlx(i+1).properties.style,'ListParagraph')
                post = '';
            else
                list = false;
            end
            fmt = [pre '<li>%s</li>' post '\n'];
        case {'CodeExampleLine','codeexample_matlab','codeexample_plain'}
            fmt = '<pre>%s</pre>\n';
        case 'LiveAppLine'
            fmt = ''; % do not display
        case {'TOCHeading','TOC1'}
            fmt = ''; % do not display
        otherwise
            fmt = ''; % do not display
    end
    align = mlx(i).properties.align;
    if ~strcmp(align,'left') && ~isempty(align)
        fmt = ['<div style="text-align:' align ';">' fmt(1:end-2) '</div>\n'];
    end
    bookmark = mlx(i).properties.bookmark;
    if ~isempty(bookmark)
        fmt = ['<a name="' bookmark '">' fmt(1:end-2) '</a>\n'];
    end
    str = '';
    for j=1:numel(mlx(i).content)
        s = mlx(i).content(j).string; % %TODO% escape HTML characters
        if ~isempty(mlx(i).content(j).style.url)
            s = ['<a href="' mlx(i).content(j).style.url '">' s '</a>'];
        end
        if ~isempty(mlx(i).content(j).style.anchor)
            s = ['<a href="#' strrep(mlx(i).content(j).style.anchor,'internal:','') '">' s '</a>'];
        end
        if strcmp(mlx(i).content(j).style.type,'equation')
            if mlx(i).content(j).style.displayStyle  % https://katex.org/
                s = ['\[' s '\]'];
            else
                s = ['\(' s '\)'];
            end
        end
        if strcmp(mlx(i).content(j).style.type,'image')
            rId = mlx(i).content(j).style.relationshipId;
            try
                [~,~,ext] = fileparts(rels.(rId).target);
                s = sprintf('<img src="data:image/%s;base64,%s" width="%s" height="%s">',...
                    ext(2:end),base64encode(rels.(rId).raw),...
                    mlx(i).content(j).style.width,mlx(i).content(j).style.height);
            catch
                s = ['<!-- ' rId ' -->'];
            end
        end
        if mlx(i).content(j).style.bold
            s = ['<strong>' s '</strong>'];
        end
        if mlx(i).content(j).style.italic
            s = ['<em>' s '</em>'];
        end
        if mlx(i).content(j).style.underline
            s = ['<u>' s '</u>'];
        end
        if mlx(i).content(j).style.monospace
            s = ['<code>' s '</code>'];
        end
        str = [str ' ' s];
    end
    fprintf(fid,fmt,str(2:end));
end
fprintf(fid,'</body>\n');
fprintf(fid,'</html>\n');
fclose(fid);
