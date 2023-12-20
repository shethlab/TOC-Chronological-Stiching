function [NsxList, NevList, Timestamps] = get_nevFiles(FullFilePath, StartComment, StopComment)
    %% Obtain a list of all the NEV files
    % Go into the directory where the NEVs are exist
    here = pwd();
    cd(FullFilePath);
    
    % Make a complete list of all the files
    [files, nevFiles] = deal(dir());
    
    % Filter out all files that do not have the .nev extension
    for idx=length(nevFiles):-1:1
        if ~endsWith(nevFiles(idx).name, '.nev')
            nevFiles(idx) = [];
        end
    end

    %% Start recording all relevant files
    % Create all the variables we need
    [NsxList, NevList] = deal([]);
    [inRecording, outOfRecording] = deal(false);
    Timestamps = struct("StartStamp", 0, "StopStamp", 0);

    % Go through each NEV
    for idx = 1:length(nevFiles)
        % Get the comments section
        file = append(FullFilePath, '\', nevFiles(idx).name);
        disp(file);
        nevFile = openNEV(file,'nosave');
        nevComment = nevFile.Data.Comments;
        clear nevFile;
        
        for comIdx = 1:height(nevComment.Text)
            % If the comments indicate that this is the starting NEV, start recording the file names
            if contains(char(nevComment.Text(comIdx,:)), StartComment)
                inRecording = true;
                Timestamps.StartStamp = nevComment.TimeStamp(comIdx);
            end
        end
        
        % Record the data we need
        if inRecording
            % record the name of the NEV file
            NevList = [NevList, string(nevFiles(idx).name)];

            % Look through the files to find the corresponding NSXs
            [ns3, ns5] = deal([]);
            groupName = nevFiles(idx).name(1:end-4);
            for nsxIdx = 1:length(files)
                if contains(files(nsxIdx).name, groupName)
                    % Save NS3s and NS5s separately
                    if endsWith(files(nsxIdx).name, '.ns3')
                        ns3 = files(nsxIdx).name;
                    elseif endsWith(files(nsxIdx).name, '.ns5')
                        ns5 = files(nsxIdx).name;
                    end
                end
            end
            % Save the NSx information as a struct
            NsxList = [NsxList, struct("ns3", ns3, "ns5", ns5)];
            clear ns3 ns5 groupName nsxIdx;
        end
    
        for comIdx = 1:height(nevComment.Text)
            % If this is the final file we need, stop the loop
            if contains(char(nevComment.Text(comIdx,:)), StopComment)
                Timestamps.StopStamp = nevComment.TimeStamp(comIdx);
                outOfRecording = true;
                break;
            end
        end
        clear nevComment;

        % If we encountered the Stoping Comment exit the loop  
        if outOfRecording; break; end
    end
    cd(here);   
end