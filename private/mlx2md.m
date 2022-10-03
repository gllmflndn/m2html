function mlx2md(mlxfilename, mdfilename)
% Convert Live Script (*.mlx) file to Markdown
% FORMAT mlx2md(mlxfilename, mdfilename)

% Copyright (C) 2021 Guillaume Flandin

%-Input arguments
%--------------------------------------------------------------------------
if nargin < 2
    mdfilename = [mlxfilename(1:end-3) 'md'];
end

%-Parse MLX file
%--------------------------------------------------------------------------
[mlx, rels, out] = mlxparse(mlxfilename);

%-Export MLX file as Markdown
%--------------------------------------------------------------------------
fid = fopen(mdfilename,'wt');
if fid == -1
    error('Cannot open Markdown file for writing');
end
list = 0;
for i=1:numel(mlx)
    switch mlx(i).properties.style
        case 'title'
            fmt = '# %s\n\n';
        case 'heading'
            fmt = '# %s\n\n';
        case 'heading2'
            fmt = '## %s\n\n';
        case 'heading3'
            fmt = '### %s\n\n';
        case 'section'
            fmt = '<hr>%s\n\n';
        case 'code'
            fmt = '```matlab\n%s\n```\n\n';
        case 'text'
            fmt = '%s\n\n';
        case 'ListParagraph'
            list = list + 1;
            if mlx(i).properties.list == 1
                pre = '* ';
            else
                pre = [num2str(list) '.'];
            end
            if i < numel(mlx) && strcmp(mlx(i+1).properties.style,'ListParagraph')
                post = '';
            else
                list = 0;
                post = '\n';
            end
            fmt = [pre ' %s\n' post];
        case {'CodeExampleLine','codeexample_matlab','codeexample_plain'}
            fmt = '```matlab\n%s\n```\n\n';
        case 'LiveAppLine'
            fmt = ''; % do not display
        case {'TOCHeading','TOC1'}
            fmt = ''; % do not display
        otherwise
            fmt = ''; % do not display
    end
    align = mlx(i).properties.align;
    if ~strcmp(align,'left') && ~isempty(align)
        fmt = ['<div style="text-align:' align ';">' fmt(1:end-2) '</div>\n\n'];
    end
    bookmark = mlx(i).properties.bookmark;
    if ~isempty(bookmark)
        %fmt = ['[' deblank(fmt) '](#' bookmark ')\n'];
    end
    str = '';
    for j=1:numel(mlx(i).content)
        s = mlx(i).content(j).string; % %TODO% escape HTML characters
        if isempty(s) && ~strcmp(mlx(i).content(j).style.type,'image'), s = ' '; break; end
        if ~isempty(mlx(i).content(j).style.url)
            s = ['[' deblank(s) '](' mlx(i).content(j).style.url ')'];
        end
        if ~isempty(mlx(i).content(j).style.anchor)
            %s = ['<a href="#' strrep(mlx(i).content(j).style.anchor,'internal:','') '">' s '</a>'];
        end
        if strcmp(mlx(i).content(j).style.type,'equation')
            % prerender using https://latex.codecogs.com ?
            if mlx(i).content(j).style.displayStyle
                s = [sprintf('```math\n%s\n```',deblank(s))]; % Gitlab
            else
                s = ['$`' s '`$']; % Gitlab: $`inline`$
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
                %s = ['<!-- ' rId ' -->'];
            end
        end
        if mlx(i).content(j).style.monospace
            s = ['`' s '`'];
        end
        if mlx(i).content(j).style.bold
            s = ['**' s '**'];
        end
        if mlx(i).content(j).style.italic
            s = ['_' s '_'];
        end
        if mlx(i).content(j).style.underline
            s = ['<u>' s '</u>'];
        end
        str = [str ' ' s];
    end
    if ~isempty(str(2:end)), fprintf(fid,fmt,str(2:end)); end
end
fclose(fid);
