function Comments = openNEVCom_v2(fileFullPath)
    Comments = struct;
    Comments.exist = false;

    FID = fopen(fileFullPath, 'r', 'ieee-le');

    % Find how many external headers we have
    BasicHeader             = fread(FID, 336, '*uint8');
    fExtendedHeader         = double(typecast(BasicHeader(13:16), 'uint32'));
    countPacketBytes        = double(typecast(BasicHeader(17:20), 'uint32'));
    FileTypeID              = char(BasicHeader(1:8)');
    clear BasicHeader;

    fseek(FID, 0, 'eof');
    fData = ftell(FID);
    countDataPacket = (fData - fExtendedHeader)/countPacketBytes;
    Timestamp = [];

    fseek(FID, fExtendedHeader, 'bof');
    if strcmpi(FileTypeID, 'NEURALEV')
        tRawData  = fread(FID, [10 countDataPacket], '10*uint8=>uint8', countPacketBytes - 10);
        Timestamp = tRawData(1:4,:);
        Timestamp = typecast(Timestamp(:), 'uint32').' + 0;
        timeStampBytes = 4;
    elseif strcmpi(FileTypeID, 'BREVENTS')
        tRawData  = fread(FID, [14 countDataPacket], '14*uint8=>uint8', countPacketBytes - 14);
        Timestamp = tRawData(1:8,:);
        Timestamp = typecast(Timestamp(:), 'uint64').' + 0;
        timeStampBytes = 8;
    end
    clear FileTypeID;

    Trackers.readPackets = [1, length(Timestamp)];

    PacketIDs = tRawData(timeStampBytes+1:timeStampBytes+2,Trackers.readPackets(1):Trackers.readPackets(2));
    PacketIDs = typecast(PacketIDs(:), 'uint16').';
    clear tRawData;

    commentPacketID = 65535;
    commentIndices = find(PacketIDs == commentPacketID);

    fseek(FID, fExtendedHeader, 'bof');
    fseek(FID, (Trackers.readPackets(1)-1) * countPacketBytes, 'cof');
    tRawData  = fread(FID, [countPacketBytes Trackers.readPackets(2)], ...
        [num2str(countPacketBytes) '*uint8=>uint8'], 0);

    if ~isempty(commentIndices)
        Comments.exist = true;
        [Comments.TimeStamp, orderOfTS] = sort(Timestamp(commentIndices));
        tempText = char(tRawData(timeStampBytes+9:countPacketBytes, commentIndices).');
        Comments.Text  = tempText(orderOfTS,:); 
        clear tempText;
        CharSet = tRawData(timeStampBytes+3, commentIndices);
        clear tRawData;
        clear commentIndices;
        
        CharSet = CharSet(orderOfTS);
        neuroMotiveEvents = find(CharSet == 255);
        clear CharSet;

        Comments.TimeStamp(neuroMotiveEvents) = [];
        Comments.Text(neuroMotiveEvents,:) = [];
    end

    fclose(FID);
end

