xmlExtract
==========

MATLAB functions to extract data for user-provided tags from XML files.

###Desired functionalities

+ find ambiguous tags and allow the user to select the right one (using the displayed paths)
+ create/update a parsing information file for future uses with the same or similar XML files
+ convert the extracted data according to user specifications (return strings if not provided or try to guess the data type?)
+ support the extraction of data arrays
+ create an output structure for the extracted data
+ support attributes?
+ support conversion of date/time strings to date/time MATLAB format


###Design

#####Inputs

+ XML file to parse
+ file or structure containing the parsing information (tag, data type)
+ (optional) date/time string format


#####Outputs

+ structure containing the extracted data
+ (optional) MAT-file containing the extracted data
+ (optional) parsing information file (new or updated)


#####Data types

+ signed integer: int (single value and array)
+ unsigned integer: uint (single value and array)
+ float/double: dbl (single value and array)
+ string: str (single value and array?)
+ date/time: date (single value and array?)
+ node: ->
+ list (repeated node): ->>


#####Processing flow

1) read the XML file using the MATLAB function `xmlread`
2) if necessary, create a structure using the contents of the parsing information file
3) validate the provided parsing information
4) verify if each tag is unambiguous

ambiguous tags: individual (different parents) vs list (same parent)

