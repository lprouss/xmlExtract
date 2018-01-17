Organization of parsing formation file and structure
====================================================

This document describes the organization of a parsing information file/structure, required by `xmlExtract.m` to extract (parse) data from a XML file.

##Parsing information file

A parsing information file has two tab-separated columns: the first one contains the names (tags) of the nodes to extract from the XML file, while the second contains the data type for each node. Each node to extract should be located on a separate line. Note that it is only necessary to provide the minimum unambiguous path for each desired node (without child).

Comment lines should start with a `%`. Spaces/tabs at the beginning of the lines are ignored, as well as empty lines. Therefore, indentation and empty lines can be employed to better organize the file.

The top-level node in the XML file node should always be included in the parsing information, and assigned the type `root` (level 0).

The following node types (case-insensitive) are currently supported:

- `node`, a parent node, which contains one or several potentially ambiguous nodes to extract;
- `list`, a parent node which is repeated several times;
- `str`, a string;
- `dbl`, a float (64 bits);
- `dblArr`, an array of floats;
- `int`, a signed integer (64 bits);
- `intArr`, an array of signed integers;
- `uint`, an unsigned integer (64 bits);
- `uintArr`, an array of unsigned integers;
- `dateStr`, a date string;
- `dateVec`, a date vector.

The extracted information for a `list` node is placed in a structure vector. To help separating the parsing information into extraction levels, parent nodes (`node` and `list`) should be terminated by a special marker (one column, no data type):

+ `#endNode`: marks the end of a parent node.
+ `#endList`: marks the end of a parent list.

Both date types (`dateStr` and `dateVec`) require a special line which provides the format of the date string or vector. Special markers are used to identify these lines:

+ `dateStrFmt`: string that indicates the format of date strings used in the XML file, if any. Details are provided below.
+ `#dateVecFmt`: string that indicates the format of date vectors used in the XML file, if any. Details are provided below.

Format strings for date strings and vectors must start and end with a `"`. Date strings should use date identifiers listed in MATLAB's command `datestr`. The only exception is the sub-second part of the string, for which and arbitrary number of `F` are accepted (`datestr` only supports milliseconds: `FFF`). The format of a date vector is specified using comma-separated words that identify the components of the date:

- 'year', the year;
- 'mon', the month;
- 'day', the day;
- 'hour', the hour;
- 'min', the minutes;
- 'sec', the seconds;
- 'msec', the milliseconds;
- 'usec', the microseconds;
- 'nan', an invalid or useless field.

For a date vector, only milliseconds and microseconds are supported. Below are examples of format strings for a date string and a date vector.

`#dateStrFmt  "yyyy-mm-ddTHH:MM:SS.FFFFFF"`
`#dateVecFmt "year,mon,day,hour,min,sec,usec"`

The file named `parseInfoSentinel1Annotation.txt` provides a rather elaborate example of a parsing information file.


##Parsing information structure

A parsing information structure should have at least three fields:

+ `tag`: names of the nodes to extract from the XML file;
+ `type`: data type for each node;
+ `level`: level for each node.

The first two fields correspond to the two columns in a parsing information file. Format strings for data strings and vectors should be provided in fields called `dataStrFmt` and `dateVecFmt`, respectively. The `level` field is used to locate potentially ambiguous fields in the XML file. `#endNode` and `#endList` are not necessary in a parsing information structure, and should not be included. As stated before, a `root` node with level 0 should be present in the structure. All unambiguous nodes can be assigned a level 1. Nodes located within parent nodes (`node` and `list` types) of level `n` should have a level `n+1`.

