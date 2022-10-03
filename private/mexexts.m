function ext = mexexts
% List of MEX files extensions
% FORMAT ext = mexexts
% MEXEXTS returns a struct array containing the MEX files platform
% dependent extensions ('ext' field) and the full names of the
% corresponding platforms ('arch' field).
%
% See also MEX, MEXEXT

% Copyright (C) 2003 Guillaume Flandin


ext = struct(...
    'ext', {'mexa64', 'mexmaci64',     'mexw64',     'mexw32'},...
    'arch',{ 'Linux',     'macOS', 'Windows 64', 'Windows 32'});
