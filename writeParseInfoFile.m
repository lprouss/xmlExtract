function writeParseInfoFile( parseInfo, outfile )
% Write XML parsing information to a file.
%
% Inputs:
%   - parseInfo: structure containing parsing information for a XML file (see
%       documentation of function 'xmlExtract' for details)
%   - outfile: name of the file used to save the parsing information
%
% Outputs: none
%
% Required functions (not part of MATLAB): none
%
% Author: Louis-Philippe Rousseau (Université Laval)
% Created: January 2017 (original name was "convertParseInfo")
% Updated: August 2017, November 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO: add option to verify the parsing information before writing it to the
%   file (is it necessary?)
% TODO: improve documentation

% validate the number of inputs
narginchk( 2, 2 );

% if provided, set the flag to check the parsing information
%if nargin == 3
    %chkFlag = varargin{2};
%end

% make sure the tags-related fields exist and have the same length
if any( ~isfield( parseInfo, {'tag', 'type', 'level'} ) )
    error( ['The input parsing information structure must contain the ' ...
        'fields "tag", "type" and "level".'] );
else
    Ntag = length( parseInfo.tag );
    Ntype = length( parseInfo.type );
    Nlevel = length( parseInfo.level );
    if (Ntag ~= Ntype) || (Ntag ~= Nlevel)
        error( ['Fields "tag", "type" and "level" in the input parsing ' ...
        'information structure have different lengths.'] );
    end
end

% if requested, check parsing information structure for ambiguous tags
%if chkFlag
    %parseInfo = checkParseInfo( xroot, parseInfo );
%end

% open the output file for writing
fid = fopen( outfile, 'w' );

% if provided, write format information for the date vectors and strings
if isfield( parseInfo, 'dateVecFmt' )
    fprintf( fid, '#dateVecFmt    %s\n', parseInfo.dateVecFmt );
end
if isfield( parseInfo, 'dateStrFmt' )
    fprintf( fid, '#dateStrFmt    %s\n', parseInfo.dateStrFmt );
end

% write each tag in the output file
fprintf( fid, '\n' ); % write empty line to separate the date format info
for cnt = 1:Ntag
    % temporary string for the current tag
    str = sprintf( '%s        %s', parseInfo.tag{cnt}, parseInfo.type{cnt} );

    % depending on the tag's level, add spaces padding to the left
    if parseInfo.level(cnt) > 1
        str = sprintf( '%*s', length(str) + 2 * (parseInfo.level(cnt) - 1), str );
    end

    % write string into the output file
    if strcmpi( parseInfo.type(cnt), 'root' )
        fprintf( fid, '%s\n\n', str );
    else
        fprintf( fid, '%s\n', str );
    end

    % if necessary, add delimiter(s) the end of a node or list block(s)
    if cnt < Ntag
        diffLevel = parseInfo.level(cnt) - parseInfo.level(cnt+1) + 1;
    else
        diffLevel = parseInfo.level(cnt);
    end
    while diffLevel > 1
        typeIdx = find( parseInfo.level(1:cnt) == parseInfo.level(cnt)-1, 1, 'last' );
        if strcmpi( parseInfo.type(typeIdx), 'node' )
            str = '#endNode';
        elseif strcmpi( parseInfo.type(typeIdx), 'list' )
            str = '#endList';
        else
            error( 'Humm...' );
        end

        fprintf( fid, sprintf( '%*s\n', length(str) + 2 * ...
            (parseInfo.level(cnt) - diffLevel), str ) );
        diffLevel = diffLevel - 1;
    end
end

% close the output file
fclose( fid );

