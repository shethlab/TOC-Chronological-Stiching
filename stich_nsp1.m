% Main function for stiching NSx files with NEV files
% Code written by Georgios Kokalas (December 2023)
% Purpose:
%   -1) Locate files related to a TOC recording session
%   -2) Stich files together
%   -3) Trim out unneeded data, based on comments
%   -4) Stich files back together into proper file structure   
% Input arguments:
%   -1) StartComment:                   The comment inserted when starting the recording
%   -2) StopComment:                    The comment inserted when stopping the recording
%   -3) FullDirPath:        (optional)  The path to the directory containing the recordings      
%                                       If left blank, user will be prompted for the value.       
%   -4) DestinationPath:    (optional)  The path to the directory where the resulting files will be saved.         
%                                       If left blank, user will be prompted for the value.       
% Output arguments: None
% Generated files:
%   -1) .nev file
%   -2) .mat file containing data of .nev file (due to malfunction of saveNEV)         
%   -3) .nsX files (same number as different types of nsx files)
%   -4) Intermediate files: trimmed versions of the first and last NSx and NEV files related to the recording       
%       - Used by the combineNSxNEV method
 
function stich_nsp1(StartComment, StopComment, FullDirPath, DestinationPath)
    %% Accomodate for input arguments
    if nargin < 2; error("StartComment and StopComment are required"); end
    if nargin < 3; FullDirPath = uigetdir('.', 'Select the folder that contains the NSx and NEV files.'); end
    if nargin < 4; DestinationPath = uigetdir('.', 'Select where you want to save the stiched files.'); end

    % make sure FullDirPath and DestinationPath are correct
    here = pwd();
    cd(FullDirPath);
    FullDirPath = pwd();
    cd(here);
    cd(DestinationPath);
    DestinationPath = pwd();
    cd(here);

    %% Obtain all the files we need
    [NsxList, NevList, Timestamps] = get_nevFiles(FullDirPath, StartComment, StopComment);

    %% Stich the files

    % METHOD USING COMBINENSXNEV
    % Trim the first and last NSx and NEV files
    [NsxList, NevLists] = trim_nsx_nev(FullDirPath, NsxList, NevList, Timestamps);
    
    % Stich the files with combineNSxNEV
    stitch_with_combineNSxNEV(FullDirPath, NsxList, NevLists, Timestamps, DestinationPath);   
    
    
    % ORIGINAL/DIRECT METHOD (UNUSED)
    % Stich NSXs
    % nsxTypes = fieldnames(NsxList);
    % for nsxIdx = 1:length(nsxTypes)
    %     stich_nsx_chronologically(FullDirPath, NsxList, nsxTypes{nsxIdx}, Timestamps, DestinationPath);
    % end
    % 
    % % Stich NEVs
    % stich_nev_chronologically(FullDirPath, NevList, Timestamps, DestinationPath);
end

