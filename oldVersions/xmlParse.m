function params = xmlParse( xmlFile, parseInfo )
% xmlParse
%
% 	Parse a XML file according to the provided parsing information.
%
% 	Inputs:
% 		- xmlFile: input XML file
% 		- parseInfo: parsing information (see Additional information)
%
% 	Outputs:
% 		- params: structure for extracted parameters
%
% 	External functions used:
% 	    - xmlParseNode (internal function)
% 		- getXMLitem
%
% 	Additional information:
% 		The parsing information can either be a text file or a structure, and
% 		contains three columns or fields. The last column in the file and the
% 		field 'tags' in the structure are the names of the nodes to extract
% 		(strings without spaces). The first column and the field 'levels' give
% 		the levels of the associated nodes inside the XML file. In the text
% 		file, it is formatted as 'Lx', where 'x' is the level number, while it
% 		is simply a number in the structure. The second column in the file and
% 		the field 'types' in the structure contain a string giving the numeric
% 		types of the associated nodes, as discussed below.
%
%       The first line/element in the parsing information should have the
%       level 0 ('L0' in the file), and the tag should be the type of XML file.
%       After the first line/element, the parsing information should consist of
%       one or several lists of nodes. It is only necessary to provide the
%       minimum unambiguous path for each desired node (without child). For
%       example, if a level 3 node is present only once in the XML tree, it is
%       not necessary to provide the information about it level 1 and 2 parents.
%       However, the level of this node should be changed accordingly (1 in this
%       case), so that each child is one level up its parent. Note that, in the
%       text file, blank lines are allowed to, e.g., separate the lists for the
%       desired nodes.
%
%       For a given list, all nodes having child nodes must be assigned the type
%       'node', and are simply used to navigate through the XML tree. For a node
%       that is repeated a several times, the type 'list' should be used, so
%       that its children parameters are extracted for each repetition.
%
%       The supported types of the parameters to extract (nodes without childs)
%       are the same as those listed in the function 'getXMLitem': 'int' (signed
%       integer), 'uint' (unsigned integer), 'dbl' (float), 'intArr', 'uintArr',
%       'dblArr' (list of values of the same type).
%
%       Example format for the parsing information file:
%           % comments can be included using the '%' symbol
%           L0  node    productType
%
%           % blank lines are allowed in the file
%           L1  node    firstCategory
%           L2  dbl     dblParamAmbiguous
%           L2  node    listNodeParent
%           L3  list    listNodeAmbiguous
%           L4  dblArr  dblArrListParam
%
%           L1  list    listNodeUnambiguous
%           L2  str     strListParam
%
%           L1  dbl     dblParamUnambiguous
%
% 	Author: Louis-Philippe Rousseau (ULaval)
% 	Created: May 2014; Last revision: September 2015
%
% TODO: add support for attributes (add 'attr' type)?

    %% read the input XML file
    try
        % success
        xdoc = xmlread( xmlFile );
    catch
        % fail, return error
        error( 'xmlParse: failed to read the input XML file: %s', xmlFile );
    end

    %% handle the parsing information variable
    % check if parseInfo is a file or a structure
    if isstruct( parseInfo )
        % if it is a structure

        % validate the fields names in the structure
        tmp = isfield( parseInfo, {'tags', 'levels', 'types'} );
        if sum(tmp) == 3
            % correct structure, copy into the 'info' variable
            info = parseInfo;
        else
            % incorrect structure, return error
            error( ['xmlParse: the supplied parsing information structure ' ...
                'seems invalid.'] );
        end
    else
        % if it is a file

        % open the file for reading
        try
            % success
            fid = fopen( parseInfo, 'r' );
        catch
            % fail, return error
            error( ['xmlParse: failed to read the parsing information ' ...
                'file: %s'], parseInfo );
        end

        % read the file content and put information in a structure
        tmp = textscan( fid, 'L%d %s %s', 'CommentStyle', '%' );
        info.tags = tmp{3}; % name tags of parameters to extract
        info.levels = tmp{1}; % levels of parameters
        info.types = tmp{2}; % types of parameters

        % close the file and clear the temporary variable
        fclose( fid );
        clear tmp;
    end

    %% check if the input file is of the expected type
    % check if the first element is level 0
    if length(info.levels) > 0 && info.levels(1) ~= 0
        % if not a level 0 element, return error
        error( ['xmlParse: the first element in the parsing information is ' ...
            'not level 0 (L0). The first element should indicate the type ' ...
            'of the input XML file.'] );
    end

    % type of XML file and document root node
    xmlType = info.tags{1};
    xroot = xdoc.getDocumentElement;

    % if root and XML type differ, return error
    if ~strcmp( xroot.getNodeName, xmlType )
        error( ['xmlParse: the input XML file is not of the expected ' ...
            'type: the top-level node name is "%s", but "%s" was ' ...
            'expected.'], xroot.getNodeName, xmlType );
    end

    %% recursively parse the input XML file
    params = xmlParseNode( xroot, info );
end


function params = xmlParseNode( parentNode, info )
% Parse the childs of a specified parent node ('parentNode') and according
% to the provided parsing information structure ('info').

    % find the indexes of child (level 1) nodes in the info structure
    childIdx = find( info.levels == 1 );
    if length(childIdx) == 0
        % nothing to do, return
        return;
    end

    % initialize the parameters structure for the parent node
    params = [];

    % loop over the child (level 1) nodes
    for cnt = 1:length(childIdx)
        % start index for current child
        currIdx = childIdx(cnt);

        % name of the current child node
        childName = info.tags{currIdx};

        % get current child node in XML tree
        childNode = parentNode.getElementsByTagName(childName);

        % parsing information structure indexes for the current child
        if cnt ~= length(childIdx)
            % indexes stop before the next child
            subIdx = (currIdx:childIdx(cnt+1)-1);
        else
            % if last child, indexes stop at the end of structure
            subIdx = (currIdx:length(info.levels));
        end

        % subset the parsing information structure for the current child
        subInfo.tags = info.tags(subIdx);
        subInfo.levels = info.levels(subIdx) - 1; % relative levels
        subInfo.types = info.types(subIdx);

        if strcmp( info.types{currIdx}, 'node' )
            % if the current child also has childs

            % recursively extract the child parameters
            subParams = xmlParseNode( childNode.item(0), subInfo );
        elseif strcmp( info.types{currIdx}, 'list' )
            % if the current child also has childs and is repeated

            % find the number of entries for the current child
            nel = childNode.getLength;

            % loop over the entries
            for cnt2 = 1:nel
                % recursively extract the child parameters
                subParams(cnt2) = xmlParseNode( childNode.item(cnt2-1), ...
                    subInfo );
            end
        elseif length(subIdx) == 1
            % if the current child has no childs

            % get the parameter data
            subParams = getXMLitem( childName, parentNode, ...
                info.types{currIdx} );
        else
            % problem with the type of the current node, return error
            error( ['xmlParse: the type of node %s should be "node" or ' ...
                '"list" but is instead %s. Please check the parsing ' ...
                'information.'], childName, info.types{currIdx} );
        end

        % merge the extracted parameters with the current level structure
        params.(childName) = subParams;

        % clear the child parameter variable
        clear subParams;
    end
end

