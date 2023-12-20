function stich_nsx_chronologically(FullFilePath, NsxList, ExtType, Timestamps, DestinationPath)
    % Use the information of the first relevant file as an append point
    firstFile = char(append( FullFilePath, '/', NsxList(1).(ExtType) ));
    mergedNsx = openNSx(firstFile);

    % Find the relation of the NEV sampling frequency to the NSx
    timestampDivision = mergedNsx.MetaTags.TimeRes / mergedNsx.MetaTags.SamplingFreq;
    
    % Modify the first NSx data
    mergedNsx.MetaTags.DataPoints = mergedNsx.MetaTags.DataPoints - floor(Timestamps.StartStamp/timestampDivision);
    mergedNsx.MetaTags.DataPointsSec = mergedNsx.MetaTags.DataPointsSec - floor(Timestamps.StartStamp/(30000));
    mergedNsx.MetaTags.DataDurationSec = mergedNsx.MetaTags.DataDurationSec - floor(Timestamps.StartStamp/(30000));
    mergedNsx.Data(:, 1:floor( (Timestamps.StartStamp - mergedNsx.MetaTags.Timestamp) /timestampDivision)) = [];
    
    %% Add on NSx information from the subsequent files
    for idx = 2:length(NsxList)
        % store the new nsx file in a separate location for appending
        locateFile = char(append( FullFilePath, '/', NsxList(idx).(ExtType) ));
        newNsx = openNSx(locateFile);
        
        % If this is the last file, cut some of the data out
        if idx == length(NsxList)
            newNsx.MetaTags.DataPoints = newNsx.MetaTags.DataPoints - floor(Timestamps.StopStamp/timestampDivision);
            newNsx.MetaTags.DataPointsSec = newNsx.MetaTags.DataPointsSec - floor(Timestamps.StopStamp/(30000));
            newNsx.MetaTags.DataDurationSec = newNsx.MetaTags.DataDurationSec - floor(Timestamps.StopStamp/(30000));
            newNsx.Data(:, floor( (Timestamps.StopStamp - newNsx.MetaTags.Timestamp) /timestampDivision):end) = [];
        end

        % Append
        mergedNsx.Data = [mergedNsx.Data, newNsx.Data];
        mergedNsx.MetaTags.DataPoints = mergedNsx.MetaTags.DataPoints + newNsx.MetaTags.DataPoints;
        mergedNsx.MetaTags.DataDurationSec = mergedNsx.MetaTags.DataDurationSec + newNsx.MetaTags.DataDurationSec;
        mergedNsx.MetaTags.DataPointsSec = mergedNsx.MetaTags.DataPointsSec + newNsx.MetaTags.DataPointsSec;
        clear newNsx;
    end
    
    % Save the NSx
    destination = char(append(DestinationPath, '/', mergedNsx.MetaTags.Filename, '-merged.', ExtType));
    saveNSxStolen(mergedNsx, destination);
end

