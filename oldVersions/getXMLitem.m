function element = getXMLitem( tag, node, varargin )
% getXMLitem
%
% 	Extract the specified element from an XML tree.
%
% 	Inputs:
% 		- tag: name tag of the desired element
%       - node: XML node in which the element is located
%       - elType (optional): data type of the element (see Additional
%           information)
%       - cnt (optional): index of the element, if many (default: 0)
%
% 	Outputs:
% 		- element: extracted element or array
%
% 	External functions used: none
%
% 	Additional information:
% 		The possible values for elType are: 'str', a string (the default);
% 		'dbl', a float (64 bits); 'dblArr', an array of floats; 'int', a
% 		signed integer (64 bits); 'intArr', an array of signed integers;
% 		'uint', an unsigned integer (64 bits); 'uintArr', an array of
% 		unsigned integers.
%
% 	Author: Louis-Philippe Rousseau (ULaval)
% 	Created: April 2014; Last revision: September 2015
%
% TODO: get rid of the input parser (use a simpler method)?
% TODO: remove support for int and uint (useless)?


%% parse the inputs
p = inputParser;
% default values, lists of permitted values and check function
validType = {'str', 'dbl', 'int', 'uint', 'dblArr', 'intArr', 'uintArr'};
defType = 'str';
chkType = @(x) any( validatestring( x, validType ) );
defCnt = 0;
chkCnt = @(x) isnumeric(x) && isscalar(x) && (x >= 0);
% add inputs
addRequired( p, 'tag', @ischar );
addRequired( p, 'node' );
addOptional( p, 'elType', defType, chkType );
addOptional( p, 'cnt', defCnt, chkCnt );
%parse the input and create data structure
parse( p, tag, node, varargin{:} );
tag = p.Results.tag;
node = p.Results.node;
elType = p.Results.elType;
cnt = p.Results.cnt;

%% try to extract the element
try
    % success
    tmp = node.getElementsByTagName(tag).item(cnt).getTextContent;
catch
    % fail, return error
    error( 'getXMLitem: non-existent field: %s', tag );
end

%% convert the element to the desired type
if strcmp( elType, 'str' )
    % string
    element = char( tmp );
else
    % check for an array of values
    if ~any( strfind( elType, 'Arr' ) )
        % convert to single double
        dbl = str2double( tmp );
    else
        % convert to array of doubles
        dbl = str2num( tmp );
    end

    % check element type and convert
    if any( strfind( elType, 'uint' ) )
        % unsigned integer
        element = uint64( dbl );
    elseif any( strfind( elType, 'int' ) )
        % signed integer
        element = int64( dbl );
    else
        % double
        element = dbl;
    end
end

