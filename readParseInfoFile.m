function pinfo = readParseInfoFile( infile, varargin )
% Read XML parsing information from a file and convert it to a structure.
%
% Inputs:
%   - infile: file containing parsing information for a XML file (see
%       file named "PARSINGINFO.md" for details.
%   - chkFlag (optional): flag to check for ambiguous tags in the parsing
%       information (NOT IMPLEMENTED YET).
%
% Outputs:
%   - pinfo: structure containing the parsing information read from the file.
%
% Required functions (not part of MATLAB):
%   - checkParseInfo (if 'chkFlag' is set to 1)
%
% Author: Louis-Philippe Rousseau (Université Laval)
% Created: January 2017 (original name was "convertParseInfo")
% Updated: August 2017, November 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO: add details in documentation?

% validate the number of inputs
narginchk( 1, 2 );

% if provided, set the flag to check the parsing information
chkFlag = 0; % default value for 'chkFlag'
if nargin == 2
    chkFlag = varargin{1};
end

% open the file for reading
try
    % success
    fid = fopen( infile, 'r' );
catch
    % fail, return error
    error( ['Failed to read the parsing information file: %s'], infile );
end

% read the file
infoTxt = textscan( fid, '%s %q', 'CommentStyle', '%' );

% close the file
fclose( fid );

% indexes of lines with a tag and lines starting with '#'
tagIdx = find( ~strncmp( infoTxt{1}, '#', 1 ) );
Ntags = length( tagIdx );

% check if format information for date vectors and strings is provided
fmtIdx1 = strcmpi( infoTxt{1}, '#dateVecFmt' );
if any( fmtIdx1 )
    pinfo.dateVecFmt = infoTxt{2}{fmtIdx1};
end
fmtIdx2 = strcmpi( infoTxt{1}, '#dateStrFmt' );
if any( fmtIdx2 )
    pinfo.dateStrFmt = infoTxt{2}{fmtIdx2};
end

% initialize the parsing information structure
pinfo.tag = infoTxt{1}(tagIdx);
pinfo.type = infoTxt{2}(tagIdx);
pinfo.level(1:Ntags) = 1;

% find the XML root tag and set level to 0
rootIdx = find( strcmpi( pinfo.type, 'root' ) );
assert( length( rootIdx )>0, ['A tag of type "root" must be present in ' ...
    'the parsing information file.'] );
pinfo.level(rootIdx) = 0;

% find the tags with type 'node' or 'list'
nodeIdx = find( strcmpi( infoTxt{2}, 'node' ) );
listIdx = find( strcmpi( infoTxt{2}, 'list' ) );
blkIdx = sort( [nodeIdx(:); listIdx(:)] );
Nblk = length( blkIdx ); % number of node and list blocks

% find the #endNode and #endList tags
endIdx = find( strncmpi( infoTxt{1}, '#end', 4 ) );
clear infoTxt;

% make sure that the number of blocks and #end* tags match
assert( Nblk == length( endIdx ), ['The number of "#end" lines does ' ...
    'not match the number of tags with type "node" or "list" in the ' ...
    'parsing information file.'] );

% increase the level of tags located inside node and list blocks
for cnt = 1:Nblk
    % sort #end tags by proximity to the current node or list tag
    [dist, sortIdx] = sort( endIdx - blkIdx(cnt) );
    endSort = endIdx(sortIdx);
    endSort = endSort(dist > 0); % discard negative distances
    clear dist sortIdx;

    % find the number of nested list or node blocks inside the current one
    num = 1;
    while (cnt+num <= Nblk) & (blkIdx(cnt+num) < endSort(num))
        num = num + 1;
    end

    % first and last indexes of the node or list block in the file data
    rawIdx1 = blkIdx(cnt) + 1;
    rawIdx2 = endSort(num) - 1;
    if any( rawIdx2 == endIdx )
        rawIdx2 = rawIdx2 - 1;
    end

    % correct indexes of the node or list block in the clean data
    goodIdx1 = find( tagIdx == rawIdx1 );
    goodIdx2 = find( tagIdx == rawIdx2 );
    clear rawIdx1 rawIdx2;

    % increase the level of the tags in the node block by 1
    pinfo.level(goodIdx1:goodIdx2) = pinfo.level(goodIdx1:goodIdx2) + 1;
    clear goodIdx1 goodIdx2;
end
clear blkIdx endIdx;

% if requested, check parsing information structure for ambiguous tags
if chkFlag
    %pinfo = checkParseInfo( xroot, pinfo );
    warning( ['Validation of the parsing information structure has not ' ...
        'been implemented yet. Skipping.'] );
end

