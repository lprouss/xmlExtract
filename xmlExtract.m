function params = xmlExtract( xmlFile, parseInfo )

% xmlFile: XML file containing the desired information
% parseInfo: file or structure containing information to parse the XML file

% params: structure containing the information extracted from the XML file

% external functions: convertParseInfo

% TODO: write documentation

    %% read the input XML file
    try
        % success
        xdoc = xmlread( xmlFile );
    catch
        % fail, return error
        error( 'xmlExtract: failed to read the input XML file: %s', xmlFile );
    end
    xroot = xdoc.getDocumentElement; % root node of the XML file

    %% handle the parsing information variable
    if isstruct( parseInfo )
        % it is a structure, validate the fields names
        if any( ~isfield( parseInfo, {'tag', 'type', 'level'} ) )
            % incorrect structure, return error
            error( ['xmlExtract: the input parsing information structure ' ...
                'must contain the fields "tag", "type" and "level".'] )
        else
            % correct structure, copy into the 'pinfo' variable
            pinfo = parseInfo;
        end
    else
        % it is a file, read it and copy the information into a structure
        pinfo = convertParseInfo( parseInfo );
    end

    %% check if the input XML tree has the expected root node
    rootIdx = find( strcmpi( pinfo.type, 'root' ) );
    infoRoot = pinfo.tag{rootIdx}; % expected root name in the parsing info
    xmlRoot = char( xroot.getNodeName ); % root name in the XML tree

    % return error if root names in the parsing info and XML tree differ
    assert( strcmpi( xmlRoot, infoRoot ), ['xmlExtract: the name of the ' ...
        'root node in the input XML file "%s" differ from the expected ' ...
        'name in the parsing information "%s."'], xmlRoot, infoRoot );

    %% recursively parse the input XML tree
    params = xmlExtractNode( xroot, pinfo );
end

function data = xmlExtractNode( node, pinfo )

% node: XML parent node containing the information to extract
% pinfo: structure containing information to parse the XML node

% data: structure containing the information extracted from the node

% external functions: getXMLnode

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
            if isfield( pinfo, 'dateVectorFormat' )
                subInfo.dateVectorFormat = pinfo.dateVectorFormat;
            end
            if isfield( pinfo, 'dateStringFormat' )
                subInfo.dateStringFormat = pinfo.dateStringFormat;
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
                error( ['xmlExtract: type "%s" for node "%s" is invalid ' ...
                    'and should be either "node" or "list".'], cType, cName );
            end
            clear subInfo;
        else
            % the current L1 node has no child, extract its data
            if strcmpi( cType, 'dateVec' ) && isfield( pinfo, 'dateVectorFormat' )
                % the node is a date vector and its format is provided
                subData = getXMLnode( cName, node, cType, pinfo.dateVectorFormat );
            elseif strcmpi( cType, 'dateStr' ) && isfield( pinfo, 'dateStringFormat' )
                % the node is a date string and its format is provided
                subData = getXMLnode( cName, node, cType, pinfo.dateStringFormat );
            else
                subData = getXMLnode( cName, node, cType );
            end
        end
        clear childIdx cNode;

        % merge data extracted from the current L1 node with the main structure
        data.(cName) = subData;
        clear subData;
    end
end

