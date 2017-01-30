function params = xmlExtract( xmlFile, parseInfo )

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
            % correct structure, copy into the 'info' variable
            info = parseInfo;
        end
    else
        % it is a file, read it and copy the information into a structure
        info = convertParseInfo( parseInfo );
    end

    %% check if the input XML file has the expected root node
    rootIdx = find( strcmp( info.type, 'root' ) );
    infoRoot = info.tag{rootIdx}; % expected root name in the parsing info
    xmlRoot = char( xroot.getNodeName ); % root name in the XML file

    % return error if root names in the parsing info and XML file differ
    assert( strcmp( xmlRoot, infoRoot ), ['xmlExtract: the name of the ' ...
        'root node in the input XML file "%s" differ from the expected ' ...
        'name in the parsing information "%s."'], xmlRoot, infoRoot );

    %% recursively parse the input XML file
    params = xmlExtractNode( xroot, info );
end

function data = xmlExtractNode( node, info )

end

