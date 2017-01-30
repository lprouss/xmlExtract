function pinfo = checkParseInfo( xroot, pinfo )

% TODO: implement interactive choice of the right path(s) for a tag
% TODO: write documentation

% indexes of tags with type other than 'root'
tagIdx = find( ~strcmpi( pinfo.type, 'root' ) );

% extract data from parsing information structure
tagList = pinfo.tag(tagIdx);
levList = pinfo.level(tagIdx);
typeList = pinfo.type(tagIdx);
Ntag = length( tagList ); % number of tags

% loop over the tags
for cnt = 1:Ntag
    % if necessary, subset the XML file
    xsub = xroot;
    if levList(cnt) > 1
        parentIdx = find( levList(1:cnt-1) < levList(cnt), 1, 'last' );
        xsub = xroot.getElementsByTagName( tagList{parentIdx} ).item(0);
        %keyboard;
    end

    % name of the root node in the XML subset
    rootName = char( xsub.getNodeName );

    % find the tag occurences
    tagOccur = xsub.getElementsByTagName( tagList{cnt} );
    Noccur = tagOccur.getLength; % number of occurences

    % if the tag occurs more than once in the subset
    if Noccur > 1
        % find the parent node(s) of each occurence of the tag
        pathOccur = cell( Noccur, 1 );
        for no = 0:Noccur-1
            % immediate parent of the current occurence
            parentNode = tagOccur.item(no).getParentNode;
            parentName = char( parentNode.getNodeName );
            pathOccur{no+1} = parentName;
            while ~strcmpi( parentName, rootName );
                parentNode = parentNode.getParentNode;
                parentName = char( parentNode.getNodeName );
                pathOccur{no+1} = strjoin( {parentName, pathOccur{no+1}}, '->' );
                %pathOccur{no+1} = [char(parentNode.getNodeName), '->', pathOccur{no+1}];
            end
        end

        % discard redundant paths for the occurence
        uniquePaths = unique( pathOccur );

        if length( uniquePaths ) > 1
            % the current tag is ambiguous: user must choose the right occurence
            fprintf( 'xmlExtract: tag "%s" is ambiguous.\n', tagList{cnt} );
            for nu = 1:length( uniquePaths )
                fprintf( '  %d: %s\n', nu, uniquePaths{nu} );
            end
            %fprintf( '  0: all\n' );
            %sel = input( fprintf( 'Please provide a comma-separated list of the desired path(s) for tag "%s" [0]: ', tagList{cnt} ), 's' );
            fprintf( 'Please correct the parsing information file or structure according to the desired path(s) for tag "%s".\nEnter "return" when you are done.\n', tagList{cnt} );
            keyboard;

            % modify the parsing information structure according to the selected path(s)
            %if isempty( sel )
                % all paths selected
            %else
                % one or more path(s) selected
            %end
        else
            % the current tag is not ambiguous: make sure it is a list or an array type
            if strcmpi( typeList{cnt}, 'node' )
                % the tag should be a list, display a warning and correct it
                warning( 'xmlExtract: correcting the type of tag "%s" from "%s" to "list".', tagList{cnt}, typeList{cnt} );
                typeList{cnt} = 'list';
            elseif ~strcmpi( typeList{cnt}, 'list' ) && ~strcmpi( typeList{cnt}(end-2:end), 'Arr' )
                % the tag has a wrong type, display a warning and correct it
                warning( 'xmlExtract: correcting the type of tag "%s" from "%s" to "%sArr".', tagList{cnt}, typeList{cnt}, typeList{cnt} );
                typeList{cnt} = [typeList{cnt}, 'Arr'];
            end
        end
    end
end

