function [NsxList, NevList] = trim_nsx_nev(FullDirPath, NsxList, NevList, Timestamps)
    %% TRIM THE APPROPRIATE NSXs
    % Get the types of NSX files we will get
    ExtTypes = fieldnames(NsxList(1));

    % Work on the first and final files
    for fileIdx = [1, length(NsxList)]
        % Work on each extension type from the nsx
        for extIdx = 1:length(ExtTypes)
            % Obtain the file
            nsxName = char(append( FullDirPath, '/', NsxList(fileIdx).(ExtTypes{extIdx}) ));
            nsxObj = openNSx(nsxName);
            
            % Find the relation of the NEV sampling frequency to the NSx
            timestampDivision = nsxObj.MetaTags.TimeRes / nsxObj.MetaTags.SamplingFreq;
            
            % Determine whether to apply Starting or Stopping Timestamp
            correctTimestamp = 0;
            if fileIdx == 1
                correctTimestamp = Timestamps.StartStamp;
                nsxObj.Data(:, 1:floor( (Timestamps.StartStamp - nsxObj.MetaTags.Timestamp)/timestampDivision)) = [];
            else
                correctTimestamp = Timestamps.StopStamp;
                nsxObj.Data(:, floor( (Timestamps.StopStamp - nsxObj.MetaTags.Timestamp)/timestampDivision):end) = [];
            end

            % Change the metatags appropriately
            nsxObj.MetaTags.DataPoints      = nsxObj.MetaTags.DataPoints - floor(correctTimestamp/timestampDivision);
            nsxObj.MetaTags.DataPointsSec   = nsxObj.MetaTags.DataPointsSec - correctTimestamp/(30000);
            nsxObj.MetaTags.DataDurationSec = nsxObj.MetaTags.DataDurationSec - correctTimestamp/(30000);

            % Save the NSx
            trimmedNsxName = char( append(nsxObj.MetaTags.Filename, '-trimmed', nsxObj.MetaTags.FileExt ) );
            trimmedNsxPath = char( append(FullDirPath, '/', trimmedNsxName) );
            saveNSxStolen(nsxObj, trimmedNsxPath);
            NsxList(fileIdx).(ExtTypes{extIdx}) = trimmedNsxName;
        end
    end

    
    %% TRIM THE APPROPRIATE NEVs
    NevList = struct("old", NevList, "new", NevList);
    for fileIdx = [1, length(NevList.old)]
        % Obtain the NEV
        nevName = char( append(FullDirPath, '/', NevList.old(fileIdx)) );
        nevObj  = openNEV(nevName, 'nosave');

        % Determine whether to apply Starting or stopping Timestamp
        correctTimestamp = 0;
        if fileIdx == 1;    correctTimestamp = Timestamps.StartStamp;
        else;               correctTimestamp = Timestamps.StopStamp;
        end

        % Modify the NEV data
        nevObj.MetaTags.DataDurationSec  = nevObj.MetaTags.DataDurationSec - floor(correctTimestamp/(30000));
        nevObj.MetaTags.DataDuration     = nevObj.MetaTags.DataDuration - floor(correctTimestamp);

        % Save the NEV
        trimmedNevName = char( append(nevObj.MetaTags.Filename, '-trimmed', nevObj.MetaTags.FileExt ) );
        trimmedNevPath = char( append(FullDirPath, '/', trimmedNevName) );
        saveNEV(nevObj, trimmedNevPath, 'noreport');
        NevList.new(fileIdx) = trimmedNevName;
    end
end