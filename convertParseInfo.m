function varargout = convertParseInfo( input, varargin )

% input: file or structure containing information to parse a XML file
% outfile: name of the file used to save the parsing information, required if 'input' is a structure
% chkFlag (optional): flag to check the parsing information for ambiguous tags

% pinfo: parsing information read from the input file

% external functions: checkParseInfo (only if 'chkFlag' is set to 1)

% TODO: write documentation
% TODO: separate code into two functions 'writeParseInfo' and 'readParseInfo'

% initialize the flag to check the parsing information structure
chkFlag = 0;

if isstruct( input )
    % input parameter is a structure containing XML parsing information

    % check the number of inputs
    narginchk( 2, 3 );

    % the second input is the output filename
    outfile = varargin{1};

    % if provided, set the flag to check the parsing information
    if nargin == 3
        chkFlag = varargin{2};
    end

    % make sure the tags-related fields exist and have the same length
    if any( ~isfield( input, {'tag', 'type', 'level'} ) )
        error( ['The input parsing information structure must contain the ' ...
            'fields "tag", "type" and "level".'] );
    else
        Ntag = length( input.tag );
        Ntype = length( input.type );
        Nlevel = length( input.level );
        if (Ntag ~= Ntype) || (Ntag ~= Nlevel)
            error( ['Fields "tag", "type" and "level" in the input parsing ' ...
            'information structure have different lengths.'] );
        end
    end

    % if requested, check parsing information structure for ambiguous tags
    if chkFlag
        %input = checkParseInfo( xroot, input );
    end

    % open the output file for writing
    fid = fopen( outfile, 'w' );

    % if provided, write format information for the date vectors and strings
    if isfield( input, 'dateVectorFormat' )
        fprintf( fid, '#dateVecFmt    %s\n', input.dateVectorFormat );
    end
    if isfield( input, 'dateStringFormat' )
        fprintf( fid, '#dateStrFmt    %s\n', input.dateStringFormat );
    end

    % write each tag in the output file
    fprintf( fid, '\n' ); % write empty line to separate the date format info
    for cnt = 1:Ntag
        % temporary string for the current tag
        str = sprintf( '%s        %s', input.tag{cnt}, input.type{cnt} );

        % depending on the tag's level, add spaces padding to the left
        if input.level(cnt) > 1
            str = sprintf( '%*s', length(str) + 2 * (input.level(cnt) - 1), str );
        end

        % write string into the output file
        if strcmpi( input.type(cnt), 'root' )
            fprintf( fid, '%s\n\n', str );
        else
            fprintf( fid, '%s\n', str );
        end

        % if necessary, add delimiter(s) the end of a node or list block(s)
        if cnt < Ntag
            diffLevel = input.level(cnt) - input.level(cnt+1) + 1;
        else
            diffLevel = input.level(cnt);
        end
        while diffLevel > 1
            typeIdx = find( input.level(1:cnt) == input.level(cnt)-1, 1, 'last' );
            if strcmpi( input.type(typeIdx), 'node' )
                str = '#endNode';
            elseif strcmpi( input.type(typeIdx), 'list' )
                str = '#endList';
            else
                error( 'Humm...' );
            end

            fprintf( fid, sprintf( '%*s\n', length(str) + 2 * ...
                (input.level(cnt) - diffLevel), str ) );
            diffLevel = diffLevel - 1;
        end
    end

    % close the output file
    fclose( fid );
else
    % input parameter is a filename containing XML parsing information

    % check the number of inputs
    narginchk( 1, 2 );

    % if provided, set the flag to check the parsing information
    if nargin == 2
        chkFlag = varargin{1};
    end

    % open the file for reading
    try
        % success
        fid = fopen( input, 'r' );
    catch
        % fail, return error
        error( ['Failed to read the parsing information file: %s'], input );
    end

    % read the file
    infoTxt = textscan( fid, '%s %s', 'CommentStyle', '%' );

    % close the file
    fclose( fid );

    % indexes of lines with a tag and lines starting with '#'
    tagIdx = find( ~strncmp( infoTxt{1}, '#', 1 ) );
    Ntags = length( tagIdx );

    % check if format information for date vectors and strings is provided
    fmtIdx1 = strcmpi( infoTxt{1}, '#dateVecFmt' );
    if any( fmtIdx1 )
        pinfo.dateVectorFormat = infoTxt{2}{fmtIdx1};
    end
    fmtIdx2 = strcmpi( infoTxt{1}, '#dateStrFmt' );
    if any( fmtIdx2 )
        pinfo.dateStringFormat = infoTxt{2}{fmtIdx2};
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
    %endNodeIdx = find( strcmpi( infoTxt{1}, '#endNode' ) );
    %endListIdx = find( strcmpi( infoTxt{1}, '#endList' ) );
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
        %oblkIdx = find( blkIdx(cnt+1:end) < endSort(1) );
        %Noblk = length( oblkIdx );
        %clear oblkIdx;

        % first and last indexes of the node or list block in the file data
        rawIdx1 = blkIdx(cnt) + 1;
        rawIdx2 = endSort(num) - 1;
        %rawIdx2 = endSort(Noblk+1) - 1;

        % correct indexes of the node or list block in the clean data
        goodIdx1 = find( tagIdx == rawIdx1 );
        goodIdx2 = find( tagIdx == rawIdx2 );
        clear rawIdx1 rawIdx2;

        % increase the level of the tags in the node block by 1
        pinfo.level(goodIdx1:goodIdx2) = pinfo.level(goodIdx1:goodIdx2) + 1;
        clear goodIdx1 goodIdx2;
    end
    clear blkIdx endIdx;

    % increase the level of tags located inside node blocks
    %Nnode = length( nodeIdx );
    %for cnt = 1:Nnode
        % sort #endNode tags by proximity to the current node tag
        %[dist, sortIdx] = sort( endNodeIdx - nodeIdx(cnt) );
        %endSort = endNodeIdx(sortIdx);
        %[dist, sortIdx] = sort( endIdx - nodeIdx(cnt) );
        %endSort = endIdx(sortIdx);
        %endSort = endSort(dist > 0); % discard negative distances
        %clear dist sortIdx;

        % find if there are other node tags before the closest #endNode
        %oblkIdx = find( nodeIdx(cnt+1:end) < endSort(1) );
        %Nblk = length( oblkIdx );
        %clear oblkIdx;

        % set the first and last indexes of the node block in the file data
        %rawIdx1 = nodeIdx(cnt) + 1;
        %rawIdx2 = endSort(Nblk+1) - 1;

        % find the correct indexes of the node block in the clean data
        %goodIdx1 = find( tagIdx == rawIdx1 );
        %goodIdx2 = find( tagIdx == rawIdx2 );
        %clear rawIdx1 rawIdx2;

        % increase the level of the tags in the node block by 1
        %pinfo.level(goodIdx1:goodIdx2) = pinfo.level(goodIdx1:goodIdx2) + 1;
        %clear goodIdx1 goodIdx2;
    %end
    %clear nodeIdx endNodeIdx;

    % increase the level of tags located inside list blocks
    %Nlist = length( listIdx );
    %for cnt = 1:Nlist
        % sort #endList tags by proximity to the current list tag
        %[dist, sortIdx] = sort( endListIdx - listIdx(cnt) );
        %endSort = endListIdx(sortIdx);
        %endSort = endSort(dist > 0); % discard negative distances

        % find if there are other list tags before the closest #endList
        %blkIdx = find( listIdx(cnt+1:end) < endSort(1) );
        %Nblk = length( blkIdx );
        %clear blkIdx;

        % set the first and last indexes of the list block in the file data
        %rawIdx1 = listIdx(cnt) + 1;
        %rawIdx2 = endSort(Nblk+1) - 1;

        % find the correct indexes of the list block in the clean data
        %goodIdx1 = find( tagIdx == rawIdx1 );
        %goodIdx2 = find( tagIdx == rawIdx2 );
        %clear rawIdx1 rawIdx2;

        % increase the level of the tags in the list block by 1
        %pinfo.level(goodIdx1:goodIdx2) = pinfo.level(goodIdx1:goodIdx2) + 1;
        %clear goodIdx1 goodIdx2;
    %end
    %clear listIdx endListIdx tagIdx;

    % if requested, check parsing information structure for ambiguous tags
    if chkFlag
        %pinfo = checkParseInfo( xroot, pinfo );
    end

    % return the parsing information structure as output
    varargout{1} = pinfo;
    clear pinfo;
end

