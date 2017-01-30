function data = getXMLnode( tag, pnode, varargin )

% tag: name of the XML tag to extract
% pnode: parent node of the tag in the XML tree
% cnt (optional): occurence number (index) of the tag, if it is repeated multiple times (default is 0)
% type (optional): data type of the tag (default is 'str', a string)
% dateFmt (optional): format string for date/time tags (default is '', no format)

% data: extracted data for the tag

% TODO: write documentation
% TODO: improve handling of 'dateVec' and 'dateStr' data types?
% TODO: remove support for useless(?) 'int' and 'uint' data types?

%% validate the number of input parameters
narginchk( 2, 5 );

%% set default values for optional inputs
cnt = 0; % extract first tag occurence
type = 'str'; % extract the tag data as a string
dateFmt = ''; % empty date format

%% check the optional inputs
if nargin == 5
    % all optional inputs provided, use the values
    cnt = varargin{1}; % occurence number for the tag
    type = varargin{2}; % data type for the tag
    dateFmt = varargin{3}; % format of the date tag
elseif nargin == 3 || nargin == 4
    % only some optional inputs are provided, check which ones

    % determine what the first optional input is
    if ischar( varargin{1} )
        % it is the data type for the tag
        type = varargin{1};
    else
        % it is the occurence number for the repeated tag
        cnt = varargin{1};
    end

    % determine what the second optional input is, if any
    if nargin == 4 && exist( 'type', 'var' )
        % it is the date format
        dateFmt = varargin{2};
    elseif nargin == 4 && ~exist( 'type', 'var' )
        % it is the data type for the tag
        type = varargin{2};
    end
else
    % no optional input provided, use defaults
end

%% try to extract the element
try
    % success
    ndata = pnode.getElementsByTagName(tag).item(cnt).getTextContent;
catch
    % fail, return error
    error( 'getXMLnode: non-existent node with name "%s"', tag );
end

%% convert data to the specified type
if strcmpi( type, 'str' )
    % string
    data = char( ndata );
elseif strncmpi( type, 'date', 4 )
    % date vector or string
    if strcmpi( type, 'dateStr' ) && ~isempty( dateFmt )
        % date string with provided format, process string
        strFmt = dateFmt(2:end-1); % format of date string
        subSecIdx = strfind( strFmt, 'F' ); % sub-second part of the string
        ndata = char( ndata );

        % convert string to date vector
        data = datevec( ndata(1:subSecIdx(1)-2), strFmt(1:subSecIdx(1)-2) );
        data(6) = data(6) + str2double( ndata(subSecIdx) ) / ...
            10^(length(subSecIdx));
    elseif strcmpi( type, 'dateStr' ) && isempty( dateFmt )
        % date string without provided format, return unprocessed string
        data = char( ndata );
    elseif strcmpi( type, 'dateVec' ) && ~isempty( dateFmt );
        % date vector with provided format, process data vector
        dFields = strsplit( dateFmt(2:end-1), ',' ); % split the format string
        yeIdx = strcmp( dFields, 'year' ); % search the year component
        monIdx = strcmp( dFields, 'mon' ); % search the month component
        dayIdx = strcmp( dFields, 'day' ); % search the day component
        hrIdx = strcmp( dFields, 'hour' ); % search the hour component
        minIdx = strcmp( dFields, 'min' ); % search the minute component
        secIdx = strcmp( dFields, 'sec' ); % search the second component
        msecIdx = strcmp( dFields, 'msec' ); % search the millisecond component
        usecIdx = strcmp( dFields, 'usec' ); % search the microsecond component
        ndata = str2num( ndata ); % convert data vector to doubles

        % construct the date vector
        data = zeros( 1, 6 ); % initialize the date vector
        data(1) = round( ndata(yeIdx) );
        data(2) = round( ndata(monIdx) );
        data(3) = round( ndata(dayIdx) );
        data(4) = round( ndata(hrIdx) );
        data(5) = round( ndata(minIdx) );
        if any( usecIdx )
            data(6) = round( ndata(secIdx) ) + ndata(usecIdx) / 1e6;
        elseif any( msecIdx )
            data(6) = round( ndata(secIdx) ) + ndata(msecIdx) / 1e3;
        else
            data(6) = round( ndata(secIdx) );
        end
    else
        % date vector without provided format, convert data vector to doubles
        data = str2num( ndata );
    end
else
    % numeric value or array

    % check if an array type is specified
    if ~strcmpi( type(end-2:end), 'Arr' )
        % single value, convert to double for now
        tmpDbl = str2double( ndata );
    else
        % array, convert to an array of doubles for now
        tmpDbl = str2num( ndata );
    end

    % convert double value(s) to another numeric type, if necessary
    if strncmpi( type, 'uint', 4 )
        % unsigned integer(s)
        data = uint64( tmpDbl );
    elseif strncmpi( type, 'int', 3 )
        % signed integer(s)
        data = int64( tmpDbl );
    else
        % double(s)
        data = tmpDbl;
    end
end

