function [mlx, rels, out] = mlxparse(filename)
% Parse Live Script (*.mlx) files
% FORMAT [mlx, rels, out] = mlxparse(filename)
%
% https://www.mathworks.com/help/matlab/matlab_prog/live-script-file-format.html

% Copyright (C) 2020 Guillaume Flandin

mlx = struct('properties',{},'content',{});

%-Extract files from archive
%==========================================================================
tmpdir = tempname;
[sts,msg] = mkdir(tmpdir);
if ~sts, error('Cannot create temporary directory.'); end
try
    unzip(filename,tmpdir);
catch
    error('Cannot open MLX file "%s".',filename);
end
ocn = onCleanup(@()rmdir(tmpdir,'s'));

%-Parse document
%==========================================================================
try
    % Require https://github.com/gllmflndn/gifti/tree/master/%40gifti/private/xml_parser.mex*
    xml = xml_parser(fullfile(tmpdir,'matlab','document.xml'));
catch
    error('Cannot parse the MATLAB document.');
end

%-Get all Paragraphs w:document>w:body>w:p
%--------------------------------------------------------------------------
p = find(arrayfun(@(x)strcmp(x.value,'w:p'),xml));

%-Extract text and style for each paragraph
%--------------------------------------------------------------------------
for i=1:numel(p)
    c = xml(p(i)).children;
    props = struct('style','','align','','list',0,'bookmark','');
    content = struct('string',{},'style',{});
    for j=1:numel(c)
        if strcmp(xml(c(j)).value,'mc:AlternateContent')
            % mc:AlternateContent>mc:Choice/mc:Fallback>* - take first...
            cr = xml(c(j)).children;
            c(j) = xml(cr(1)).children;
        end
        switch xml(c(j)).value
            case 'w:pPr' % ParagraphProperties
                cr = xml(c(j)).children;
                for k=1:numel(cr)
                    switch xml(cr(k)).value
                        case 'w:pStyle' % Referenced Paragraph Style 
                        	props.style = attr(xml(cr(k)),'w:val');
                        case 'w:jc'     % Paragraph Alignment
                            props.align = attr(xml(cr(k)),'w:val');
                        case 'w:numPr'  % Numbering Definition Instance Reference
                            % ListParagraph: 1 -> unordered, 2 -> ordered
                            props.list = str2num(attr(xml(xml(cr(k)).children),'w:val'));
                        case 'w:sectPr' % Document Final Section Properties
                            props.style = 'section';
                        otherwise
                            fprintf('Ignored "%s" property\n',xml(cr(k)).value');
                    end
                end
            case 'w:r' % Run
                [str, style] = runcontent(xml,c(j));
                content = [content, struct('string',{str},'style',{style})];
            case 'w:customXml'
                type = attr(xml(c(j)),'w:element'); % image, equation, livecontrol
                % -> w:r>w:t
                k = xml(c(j)).children;
                k = k(arrayfun(@(x)strcmp(x.value,'w:r'),xml(k)));
                [str, style] = runcontent(xml,k);
                style.type = type;
                % -> w:customXmlPr>w:attr : displayStyle = false
                % -> w:customXmlPr>w:attr : height, width, relationshipId
                k = xml(c(j)).children;
                k = k(arrayfun(@(x)strcmp(x.value,'w:customXmlPr'),xml(k)));
                if ~isempty(k)
                    k = xml(k).children;
                    for l=1:numel(k)
                        n = attr(xml(k(l)),'w:name');
                        v = attr(xml(k(l)),'w:val');
                        if strcmpi(v,'true'), v = true; end
                        if strcmpi(v,'false'), v = false; end
                        style.(n) = v;
                    end
                end
                content = [content, struct('string',{str},'style',{style})];
            case 'w:hyperlink'
                [str, style] = runcontent(xml,xml(c(j)).children);
                style.url = attr(xml(c(j)),'w:docLocation');
                style.anchor = attr(xml(c(j)),'w:anchor');
                content = [content, struct('string',{str},'style',{style})];
            case 'w:bookmarkStart'
                name = attr(xml(c(j)),'w:name');
                id = attr(xml(c(j)),'w:id');
                props.bookmark = id;
            case 'w:bookmarkEnd'
                id = attr(xml(c(j)),'w:id');
                props.bookmark = id;
            otherwise
               fprintf('Ignored "%s" element\n',xml(c(j)).value);
       end
    end
    mlx(i) = struct('properties',props,'content',content);
end

%-Parse relations
%==========================================================================
rels = struct;
if nargout > 1
    try
        rel = xml_parser(fullfile(tmpdir,'matlab','_rels','document.xml.rels'));
        r = find(arrayfun(@(x)strcmp(x.value,'Relationship'),rel));
        for i=1:numel(r)
            rels.(attr(rel(r(i)),'Id')).target = attr(rel(r(i)),'Target');
            rels.(attr(rel(r(i)),'Id')).type = attr(rel(r(i)),'Type');
            fid = fopen(fullfile(tmpdir,'matlab',attr(rel(r(i)),'Target')),'rb');
            rels.(attr(rel(r(i)),'Id')).raw = fread(fid,Inf,'*uchar');
            fclose(fid);
        end
    end
end

%-Parse outputs
%==========================================================================
out = struct;
if nargout > 2
    try
        out = xml_parser(fullfile(tmpdir,'matlab','output.xml'));
        % list of outputs: embeddedOutputs/outputArray/element*
        % location of outputs: embeddedOutputs/regionArray/element*
    end
end

%==========================================================================
%-Get XML element attributes
%==========================================================================
function value = attr(element,key)
% Return value of a given attribute key
value = '';
for i=1:numel(element.attributes)
    if strcmp(element.attributes(i).key,key)
        value = element.attributes(i).value;
        return;
    end
end

%==========================================================================
%-Get Run content
%==========================================================================
function [str,style] = runcontent(xml,uid)
% Return content of w:r>w:t and w:r>w:rPr
str = '';
style = struct('type','text','bold',false, 'italic',false, 'underline',false,...
    'monospace',false, 'url','','anchor','');
if nargin < 2 || isempty(uid), return; end
cr = [xml(xml(uid).children).children];
for k=1:numel(cr)
    switch xml(cr(k)).type
        case 'chardata' % Text
            str = xml(cr(k)).value;
        case 'element' % RunProperties
            switch xml(cr(k)).value
                case 'w:rFonts'
                    font = attr(xml(cr(k)),'w:cs');
                    if strcmp(font,'monospace')
                        style.monospace = true;
                    else
                        fprintf('Ignored "%s" font\n',font);
                    end
                case 'w:b'
                    style.bold = true;
                case 'w:i'
                    style.italic = true;
                case 'w:u'
                    style.underline = true;
                otherwise
                    fprintf('Ignored "%s" style\n',xml(cr(k)).value);
            end
    end
end
            
