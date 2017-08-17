function data = getXMLnode( tag, pnode, varargin )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getXMLnode
%
% 	Extract the specified tag from a node in an XML tree.
%
% 	Inputs:
% 		- tag: name of the XML tag to extract
%       - pnode: parent node of the tag in the XML tree
%       - cnt (optional): occurence number (index) of the tag, if it is
%           repeated multiple times (default is 0)
%       - type (optional): data type of the tag (see Additional information,
%           default is 'str')
%       - dateFmt (optional): format string for date tags (see Additional
%           information, default is '')
%
% 	Outputs:
% 		- data: extracted data for the tag
%
% 	Internal and/or external functions used: none
%
% 	Additional information:
%       The following values for the optional input parameter "type" are
%       currently supported (case-insensitive):
%           - 'str', a string (the default);
%           - 'dbl', a float (64 bits);
%           - 'dblArr', an array of floats;
%           - 'int', a signed integer (64 bits);
%           - 'intArr', an array of signed integers;
%           - 'uint', an unsigned integer (64 bits);
%           - 'uintArr', an array of unsigned integers;
%           - 'dateStr', a date string;
%           - 'dateVec', a date vector.
%
%       The optional input parameter "dateFmt" is only used with data types
%       'dateStr' and 'dateVec'. For a date string, "dateFmt" should be
%       formatted using MATLAB's date string identifiers, which are listed
%       in the help of the command "datestr". Contrary to MATLAB, which only
%       supports milliseconds ('FFF'), this function can handle any number of
%       digits for sub-second data, e.g. 'FFFFFF' for the microseconds. For a
%       date vector, "dateFmt" should be a comma-separated string containing
%       several of the following fields:
%           - 'year', the year;
%           - 'mon', the month;
%           - 'day', the day;
%           - 'hour', the hour;
%           - 'min', the minutes;
%           - 'sec', the seconds;
%           - 'msec', the milliseconds;
%           - 'usec', the microseconds.
%       For both data types 'dateStr' and 'dateVec', this function returns a
%       six-elements date vector:
%           [year, month, day, hour, minutes, seconds (with sub-seconds)]
%
% 	Author: Louis-Philippe Rousseau (Université Laval)
% 	Created: April 2014 (original name was "getXMLitem")
%   Updated: September 2015, January 2016, August 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO: remove support for 'int(Arr)' and 'uint(Arr)' data types?

%% validate the number of input parameters
narginchk( 2, 5 );

%% set default values for optional inputs
cnt = 0; % extract first tag occurence
type = 'str'; % extract the tag data as a string
dateFmt = ''; % empty date format string

%% list of supported data types
dtypeList = {'str', 'dbl', 'dblArr', 'int', 'intArr', 'uint', 'uintArr',
    'dateStr', 'dateVec'};

%% lsit of supported fields in the format string for a date string
%dateStrList = {'yyyy', 'mm', 'dd', 'HH', 'MM', 'SS', 'FFF', 'FFFFFF'};

%% list of supported fields in the format string for a date vector
dateVecList = {'year', 'mon', 'day', 'hour', 'min', 'sec', 'msec', 'usec'};

%% check the optional inputs
if nargin > 2
    % optional inputs provided, assign each value to the correct variable
    for idx = 1:nargin-2
        if isnumeric( varargin{idx} )
            % current input is the occurence number for the tag
            cnt = varargin{idx};
        elseif any( strcmpi( varargin{idx}, dtypeList ) )
            % current input is the data type for the tag
                type = varargin{idx};
        else
            % current input is the date format string, or is invalid
            dateFmt = varargin{idx};
        end
    end
    %cnt = varargin{1}; % occurence number for the tag
    %type = varargin{2}; % data type for the tag
    %dateFmt = varargin{3}; % format of the date tag
end
%elseif nargin == 3 || nargin == 4
    % only some optional inputs are provided, find which ones

    % determine what the first optional input is
    %if ischar( varargin{1} )
        % it is the data type for the tag
        %type = varargin{1};
    %else
        % it is the occurence number for the repeated tag
        %cnt = varargin{1};
    %end

    % determine what the second optional input is, if any
    %if nargin == 4 && exist( 'type', 'var' )
        % it is the date format
        %dateFmt = varargin{2};
    %elseif nargin == 4 && ~exist( 'type', 'var' )
        % it is the data type for the tag
        %type = varargin{2};
    %end
%else
    % no optional input provided, use defaults
%end

%% try to extract the element
try
    % success
    ndata = pnode.getElementsByTagName(tag).item(cnt).getTextContent;
catch
    % fail, return error
    error( 'Non-existent node with name "%s"', tag );
end

%% convert data to the specified type
if strcmpi( type, 'str' )
    % string
    data = char( ndata );
elseif strncmpi( type, 'date', 4 )
    % date vector or string

    % convert tag data according to the provided type
    if strcmpi( type, 'dateStr' )
        % date string type, convert to string
        ndata = char( ndata );
    else
        % date vector type, convert data vector to doubles
        ndata = str2num( ndata );
    end

    if isempty( dateFmt )
        % date format string not provided, return converted data directly
        data = ndata;
    else
        % date format string provided, use it to correctly convert data
        if strcmpi( type, 'dateStr' )
            % date string type, process string

            %strFmt = dateFmt(2:end-1); % format of date string

            % find sub-second portion of the date string, if any
            subSecIdx = strfind( strFmt, 'F' ); % sub-second part of the string

            % convert string to date vector
            if isempty( subSecIdx )
                % no sub-second part in date string, use it directly
                data = datevec( ndata, strFmt );
            else
                % sub-second part present in date string, handle it separately
                data = datevec( ndata(1:subSecIdx(1)-1),
                    strFmt(1:subSecIdx(1)-1) );
                data(6) = data(6) + str2double( ndata(subSecIdx) ) / ...
                    10^(length(subSecIdx));
            end
        else
            % date vector type, process data vector

            % split the format string at the commas
            %dFields = strsplit( dateFmt(2:end-1), ',' );
            dFields = strsplit( dateFmt, ',' );

            % construct the date vector by looping over the elements
            data = zeros( 1, 6 ); % initialize the date vector
            for nel = 1:6
                % search the current element in the format string
                elIdx = strcmp( dFields, dateVecList{nel} );

                % if it exists, copy the current element in the date vector
                if ~isempty( elIdx )
                    if nel < 6
                        % for the first five elements, round the data
                        data(nel) = round( ndata(elIdx) );
                    else
                        % for the last element, also check for sub-seconds data
                        msecIdx = strcmp( dFields, 'msec' ); % milliseconds
                        usecIdx = strcmp( dFields, 'usec' ); % microseconds
                        if ~isempty( usecIdx )
                            % microsecond element present in date vector
                            data(6) = round( ndata(elIdx) ) + ...
                                ndata(usecIdx) / 1e6;
                        elseif ~isempty( msecIdx )
                            % millisecond element present in date vector
                            data(6) = round( ndata(elIdx) ) + ...
                                ndata(msecIdx) / 1e3;
                        else
                            % no sub-second component in date vector
                            data(6) = ndata(elIdx);
                        end
                        clear msecIdx usecIdx;
                    end
                end
                clear elIdx;
            end
        end
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
    clear tmpDbl;
end
clear ndata;

