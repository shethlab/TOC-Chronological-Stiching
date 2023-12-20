function stich_nev_chronologically(FullFilePath, NevList, Timestamps, DestinationPath)
    % Use the information of the first relevant file as an append point
    firstFileLocation = char( append(FullFilePath, '/', NevList(1)) );
    mergedNev = openNEV( firstFileLocation, 'nosave');
    
    % Modify the first NEV data
    mergedNev.MetaTags.DataDurationSec  = mergedNev.MetaTags.DataDurationSec - floor(Timestamps.StartStamp/(30000));
    mergedNev.MetaTags.DataDuration     = mergedNev.MetaTags.DataDuration - floor(Timestamps.StartStamp);
    

    %% Add on NEV information from the subsequent files
    for idx=2:length(NevList)
        % store the new NEV file in a separate location for appending
        locateFile  = char(append( FullFilePath, '/', NevList(idx) ));
        newNev      = openNEV(locateFile, 'nosave');

        % If this is the last file, cut some of the data out
        if idx == length(NevList)
            newNev.MetaTags.DataDurationSec = newNev.MetaTags.DataDurationSec - floor(Timestamps.StopStamp/(30000));
            newNev.MetaTags.DataDuration    = newNev.MetaTags.DataDuration - floor(Timestamps.StopStamp);
        end

        % Append
        mergedNev.MetaTags.DataDuration             = mergedNev.MetaTags.DataDuration + newNev.MetaTags.DataDuration;
        mergedNev.MetaTags.DataDurationSec          = mergedNev.MetaTags.DataDurationSec + newNev.MetaTags.DataDurationSec;
        mergedNev.Data.Spikes.Electrode             = [mergedNev.Data.Spikes.Electrode, newNev.Data.Spikes.Electrode];
        mergedNev.Data.Spikes.TimeStamp             = [mergedNev.Data.Spikes.TimeStamp, newNev.Data.Spikes.TimeStamp];
        mergedNev.Data.Spikes.Unit                  = [mergedNev.Data.Spikes.Unit, newNev.Data.Spikes.Unit];
        mergedNev.Data.Spikes.Waveform              = [mergedNev.Data.Spikes.Waveform, newNev.Data.Spikes.Waveform];
        mergedNev.Data.Comments.TimeStamp           = [mergedNev.Data.Comments.TimeStamp, newNev.Data.Comments.TimeStamp];
        mergedNev.Data.Comments.TimeStampSec        = [mergedNev.Data.Comments.TimeStampSec, newNev.Data.Comments.TimeStampSec];
        mergedNev.Data.Comments.TimeStampStarted    = [mergedNev.Data.Comments.TimeStampStarted, newNev.Data.Comments.TimeStampStarted];
        mergedNev.Data.Comments.TimeStampStartedSec = [mergedNev.Data.Comments.TimeStampStartedSec, newNev.Data.Comments.TimeStampStartedSec];
        mergedNev.Data.Comments.CharSet             = [mergedNev.Data.Comments.CharSet, newNev.Data.Comments.CharSet];
        mergedNev.Data.Comments.Text                = [mergedNev.Data.Comments.Text; newNev.Data.Comments.Text];
        try
            mergedNev.Data.Comments.Color           = [mergedNev.Data.Comments.Color; newNev.Data.Comments.Color];
        catch
        end
    end
    
    % Save the NEV
    destination = char(append(DestinationPath, '/', mergedNev.MetaTags.Filename, '-trimmed-merged'));
    save([destination, '.mat'], "mergedNev");
    saveNEV(mergedNev, [destination, '.nev'],'noreport');
end