function coilPos = import_coil(filename, dataLines)
%IMPORTFILE Import data from a text file
%  SRUCCSSHCOILPOSALL = IMPORTFILE(FILENAME) reads data from text file
%  FILENAME for the default selection.  Returns the data as a table.
%
%  SRUCCSSHCOILPOSALL = IMPORTFILE(FILE, DATALINES) reads data for the
%  specified row interval(s) of text file FILENAME. Specify DATALINES as
%  a positive scalar integer or a N-by-2 array of positive scalar
%  integers for dis-contiguous row intervals.

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [8, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 13);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["Labels", "Var2", "Var3", "LocX", "LocY", "LocZ", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13"];
opts.SelectedVariableNames = ["Labels", "LocX", "LocY", "LocZ"];
opts.VariableTypes = ["categorical", "string", "string", "double", "double", "double", "string", "string", "string", "string", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Var2", "Var3", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Labels", "Var2", "Var3", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13"], "EmptyFieldRule", "auto");

% Import the data
coilPos = readtable(filename, opts);

end