function params = xmlExtract( xmlFile, parseInfo )
% Parse a XML file according to the provided parsing information.
%
% Inputs:
%   - xmlFile: XML file to parse.
%   - parseInfo: file or structure containing information used to parse the
%       XML file, see file named "PARSINGINFO.md" for details.
%
% Outputs:
%   - params: structure containing data extracted from the XML file.
%
% Required functions (not part of MATLAB):
%   - readParseInfoFile
%   - xmlExtractNode (internal)
%   - getXMLnode (used by 'xmlExtractNode')
%
% Author: Louis-Philippe Rousseau (Université Laval)
% Created: May 2014 (original name was "xmlParse")
% Updated: September 2015, January 2016, August 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO: complete documentation (details about 'parseInfo').
% TODO: validate 'parseInfo' structure?
% TODO: try to improve/simplify 'xmlExtractNode'.

%% read the input XML file
try
    % success
    xdoc = xmlread( xmlFile );
catch
    % fail, return error
    error( 'Failed to read the input XML file: %s', xmlFile );
end
xroot = xdoc.getDocumentElement; % root node of the XML file

%% handle the parsing information variable
if isstruct( parseInfo )
    % it is a structure, validate the fields names
    if any( ~isfield( parseInfo, {'tag', 'type', 'level'} ) )
        % incorrect structure, return error
        error( ['The input parsing information structure must contain the ' ...
            'fields "tag", "type" and "level".'] );
    else
        % correct structure, copy into the 'pinfo' variable
        pinfo = parseInfo;
    end
else
    % it is a file, read it and copy the information into a structure
    pinfo = readParseInfoFile( parseInfo );
end

%% check if the input XML tree has the expected root node
rootIdx = find( strcmpi( pinfo.type, 'root' ) );
infoRoot = pinfo.tag{rootIdx}; % expected root name in the parsing info
xmlRoot = char( xroot.getNodeName ); % root name in the XML tree

% return error if root names in the parsing info and XML tree differ
assert( strcmpi( xmlRoot, infoRoot ), ['The name of the root node in the ' ...
    'input XML file "%s" differ from the expected name in the parsing ' ...
    'information "%s."'], xmlRoot, infoRoot );

%% recursively parse the input XML tree
params = xmlExtractNode( xroot, pinfo );

%% end of 'xmlExtract' (main function)
end


%%% ------------------------------------------------------------------------ %%%
function data = xmlExtractNode( node, pinfo )
% Recursively parse an XML node according to the provided parsing
% information.
%
% Inputs:
%   - node: XML node (parent) to parse.
%   - pinfo: structure containing information used to parse the XML node
%       (see main documentation above).
%
% Outputs:
%   - data: structure containing data extracted from the XML node.
%
% Required functions (not part of MATLAB):
%   - getXMLnode
%
% Author: Louis-Philippe Rousseau (Université Laval)
% Created: May 2014 (original name was "xmlParseNode")
% Updated: September 2015, January 2016, August 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% find the level 1 nodes in the parsing information structure
l1Idx = find( pinfo.level == 1 );
Nl1 = length( l1Idx ); % number of L1 nodes to process
Ntag = length( pinfo.tag ); % total number of tags

%% if there are no nodes to process, return to the caller
if Nl1 == 0
    return;
end

%% initialize a data structure
data = [];

%% process the L1 nodes
for cnt = 1:Nl1
    % index, name and type of the current level 1 node
    cIdx = l1Idx(cnt);
    cName = pinfo.tag{cIdx};
    cType = pinfo.type{cIdx};

    % extract the L1 node in the XML tree
    cNode = node.getElementsByTagName( cName );

    % check if the current L1 node has children
    if cnt < Nl1
        % indexes of children between the current L1 node and the next
        childIdx = (cIdx:l1Idx(cnt+1)-1);
    else
        % indexes of children between the current L1 node and the last one
        childIdx = (cIdx:Ntag);
    end
    Nchild = length( childIdx ) - 1; % number of children

    % process the current L1 node
    if Nchild > 0
        % subset the parsing information structure
        subInfo.tag = pinfo.tag(childIdx);
        subInfo.type = pinfo.type(childIdx);
        subInfo.level = pinfo.level(childIdx) - 1; % decrease levels by 1
        if isfield( pinfo, 'dateVecFmt' )
            subInfo.dateVecFmt = pinfo.dateVecFmt;
        end
        if isfield( pinfo, 'dateStrFmt' )
            subInfo.dateStrFmt = pinfo.dateStrFmt;
        end

        % the current L1 node has children, check its type
        if strcmpi( cType, 'node' )
            % the parent L1 node is repeated only once, recursively parse it
            subData = xmlExtractNode( cNode.item(0), subInfo );
        elseif strcmpi( cType, 'list' )
            % the parent L1 node is repeated multiple times

            % number of repetitions
            Nrep = cNode.getLength;

            % recursively parse each repetition
            for nr = 1:Nrep
                subData(nr) = xmlExtractNode( cNode.item(nr-1), subInfo );
            end
        else
            % invalid type for parent L1 node
            error( ['Type "%s" for node "%s" is invalid: it should be ' ...
                'either "node" or "list".'], cType, cName );
        end
        clear subInfo;
    else
        % the current L1 node has no child, extract its data
        if strcmpi( cType, 'dateVec' ) && isfield( pinfo, 'dateVecFmt' )
            % the node is a date vector and its format is provided
            subData = getXMLnode( cName, node, cType, pinfo.dateVecFmt );
        elseif strcmpi( cType, 'dateStr' ) && isfield( pinfo, 'dateStrFmt' )
            % the node is a date string and its format is provided
            subData = getXMLnode( cName, node, cType, pinfo.dateStrFmt );
        elseif length( cType ) > 3 && strcmpi( cType(end-3:end), 'List' )
            % the node is a repeated multiple times (list)

            % number of repetitions
            Nrep = cNode.getLength;

            % extract data for each repetition
            subData = cell( 1, Nrep );
            for nr = 1:Nrep
                subData{nr} = getXMLnode( cName, node, nr-1, cType(1:end-3) );
            end
        else
            subData = getXMLnode( cName, node, cType );
        end
    end
    clear childIdx cNode;

    % merge data extracted from the current L1 node with the main structure
    fieldName = matlab.lang.makeValidName( cName ); % make sure the field name is valid
    data.(fieldName) = subData;
    clear subData;
end

%% end of 'xmlExtractNode' (internal function)
end

