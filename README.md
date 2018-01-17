xmlExtract
==========

Function that acts as a front-end to MATLAB's `xmlread`, for easier data extraction from XML files.


##Functions and files

+ `xmlExtract`: main function;
+ `PARSINGINFO.md`: description of the parsing information files and structures used by `xmlExtract`.
+ `getXMLnode`: get data from a XML node and convert it to the desired type (string, double, date string/vector, etc.);
+ `readParseInfoFile`: read a parsing information file and convert it to a structure.

__Functions being implemented:__

- `checkParseInfo`: validate and correct a parsing information structure;
- `writeParseInfoFile`: convert a parsing information structure to a file.

