xmlExtract
==========

Function that acts as a front-end to MATLAB's `xmlread`, for easier extraction of data from XML files.



###Desired functionalities

+ find ambiguous tags and allow the user to select the right one (using the displayed paths)
+ create/update a parsing information file for future uses with the same or similar XML files
+ convert the extracted data according to user specifications (return strings if not provided)
+ support the extraction of data arrays
+ create an output structure for the extracted data
+ support conversion of date/time strings to date/time MATLAB format
+ support attributes?


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
+ node
+ list (repeated node)

ambiguous tags: individual (different parents) vs list (same parent)

