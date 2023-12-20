function stitch_with_combineNSxNEV(FullDirPath, NsxList, NevLists, Timestamps, DestinationPath)
    % Find the length of the NSx and NEV structures we will be getting
    combineLength = length(NsxList) / 2;
    if combineLength ~= floor(combineLength); combineLength = ceil(combineLength); end
    NevList = NevLists.new;
    combineNevList = cell(1, combineLength);
    ExtTypes = fieldnames(NsxList(1));

    %% WORK PER EXTENSION TYPE ON THE NSXs
    for extIdx = 1:length(ExtTypes)
        % To avoid working on the NEVs Multiple times, we will only work on them when extIdx equals 1  

        % create a list that will contain the products of combineNSxNEV  
        combineNsxList = cell(1, combineLength);
        
        % For every2 files, use combineNSxNEV
        for nsxIdx = 1:2:length(NsxList)-1
            % Open 2 files for the function
            locateNsx1 = char(append( FullDirPath, '/', NsxList(nsxIdx).(ExtTypes{extIdx}) ));
            locateNsx2 = char(append( FullDirPath, '/', NsxList(nsxIdx+1).(ExtTypes{extIdx}) ));
            
            % Combine the 2 NSx and related NEVs with the combineNSxNEV function
            [combinedNsx, combinedNev] = combineNSxNEVStolen(locateNsx1, locateNsx2);
            combineNsxList{(nsxIdx+1)/2} = combinedNsx;
            
            % If we are on the first NSx instance, work on NEVs as well
            if extIdx == 1;  combineNevList{(nsxIdx+1)/2} = combinedNev; end
            
            % Clear to conserve space
            clear combinedNsx combinedNev;
        end 
        
        % If we have an odd number of files, combineNSxNEV will not reach the last file, so we need to open it manually
        if ((nsxIdx+1)/2) ~= combineLength
            locateLastNsx = char(append( FullDirPath, '/', NsxList(end).(ExtTypes{extIdx}) ));
            combineNsxList{end} = openNSx(locateLastNsx);

            if extIdx == 1
                locateLastNev = char(append( FullDirPath, '/', NevList(end)));
                combineNevList{end} = openNEV(locateLastNev, 'nosave');
            end
        end

        %% START TRULY MERGING
        % As the merge base, use the first combined NSx
        mergedNsx = combineNsxList{1};
        mergedNev = 0;

        % If we are on the first NSx instance, work on NEVs as well
        if extIdx == 1; mergedNev = combineNevList{1}; end

        % Stich the combined NSx Objects with one another
        for combineIdx = 2:length(combineNsxList)
            mergedNsx.Data = [mergedNsx.Data, combineNsxList{combineIdx}.Data];
            mergedNsx.MetaTags.DataPoints = mergedNsx.MetaTags.DataPoints + combineNsxList{combineIdx}.MetaTags.DataPoints;
            mergedNsx.MetaTags.DataDurationSec = mergedNsx.MetaTags.DataDurationSec + combineNsxList{combineIdx}.MetaTags.DataDurationSec;
            mergedNsx.MetaTags.DataPointsSec = mergedNsx.MetaTags.DataPointsSec + combineNsxList{combineIdx}.MetaTags.DataPointsSec;

            % If we are on the first nsx type found, work on NEVs as well
            if extIdx == 1 
                mergedNev.MetaTags.DataDuration         = mergedNev.MetaTags.DataDuration + combineNevList{combineIdx}.MetaTags.DataDuration;
                mergedNev.MetaTags.DataDurationSec      = mergedNev.MetaTags.DataDurationSec + combineNevList{combineIdx}.MetaTags.DataDurationSec;
                mergedNev.Data.Spikes.Electrode         = [mergedNev.Data.Spikes.Electrode, combineNevList{combineIdx}.Data.Spikes.Electrode];
                mergedNev.Data.Spikes.TimeStamp         = [mergedNev.Data.Spikes.TimeStamp, combineNevList{combineIdx}.Data.Spikes.TimeStamp];
                mergedNev.Data.Spikes.Unit              = [mergedNev.Data.Spikes.Unit, combineNevList{combineIdx}.Data.Spikes.Unit];
                mergedNev.Data.Spikes.Waveform          = [mergedNev.Data.Spikes.Waveform, combineNevList{combineIdx}.Data.Spikes.Waveform];
                mergedNev.Data.Comments.TimeStamp       = [mergedNev.Data.Comments.TimeStamp, combineNevList{combineIdx}.Data.Comments.TimeStamp];
                mergedNev.Data.Comments.TimeStampSec    = [mergedNev.Data.Comments.TimeStampSec, combineNevList{combineIdx}.Data.Comments.TimeStampSec];
                mergedNev.Data.Comments.CharSet         = [mergedNev.Data.Comments.CharSet, combineNevList{combineIdx}.Data.Comments.CharSet];
                mergedNev.Data.Comments.Text            = [mergedNev.Data.Comments.Text; combineNevList{combineIdx}.Data.Comments.Text];
            end
        end
    
        % Save the stiched NSx structure into a file
        nsxDestination = char(append(DestinationPath, '/', mergedNsx.MetaTags.Filename, '-merged', mergedNsx.MetaTags.FileExt));
        saveNSxStolen(mergedNsx, nsxDestination);
        clear mergedNsx nsxDestination combineNsxList;
        
         % If we are on the first nsx type found, save the stiched NEV as well
         % Do checks, and also save a .mat file
        if extIdx == 1
            stich_nev_chronologically(FullDirPath, NevLists.old, Timestamps, DestinationPath);
            clear mergedNev combineNevList;
        end
    end   
end



















            % nevDestination = char(append(DestinationPath, '/', mergedNev.MetaTags.Filename, '-merged'));
            % saveNEV(mergedNev, [nevDestination, '.nev'], 'noreport');
            % save([nevDestination, '.mat'], "mergedNev","-mat");