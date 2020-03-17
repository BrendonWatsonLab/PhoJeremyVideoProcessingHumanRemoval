% Jeremy Human Exclusion Video Processing Project
% Pho Hale, created 03-12-2020
% Goal: Given an input video of Jeremy running a rat on his circular water table, construct a vector of pairs of frames (start, end) to exclude from analysis because they have Jeremy in them.

% Input Settings:
currentFolder = pwd;
videoFrameGateRect = [319.913260485224 9.09676368265632 17.174890796144 15.3794414144288];
% Video 1:
% curr_files_path = '..\Peekay_200116_143440';
% curr_video_file.filename = 'Peekay_20200116_143605803.avi';
% curr_video_file.relative_file_path = fullfile("..\Peekay_200116_143440\Peekay_20200116_143605803.avi");
% Video 2:
% curr_files_path = '..\Peekay_200117_130855';
% curr_video_file.filename = 'Peekay_20200117_131022908.avi';
% curr_video_file.relative_file_path = fullfile("..\Peekay_200117_130855\Peekay_20200117_131022908.avi");

% Video 3:
% curr_files_path = '..\Peekay_200120_142401';
% curr_video_file.filename = 'Peekay_20200120_142612695.avi';

% Video 4:
curr_files_path = '..\Peekay_200121_140135';
curr_video_file.filename = 'Basler acA1920-40uc (22355049)_20200121_140231002.avi';

curr_video_file.relative_file_path = fullfile(curr_files_path, curr_video_file.filename);

[~,curr_video_file.basename, curr_video_file.extension] = fileparts(curr_video_file.filename);
v = VideoReader(curr_video_file.relative_file_path);
curr_video_file.full_parent_path = v.Path;
curr_video_file.full_path = fullfile(curr_video_file.full_parent_path, curr_video_file.filename);

% Frames:
% currShiftIndex = 2; % What set of frames to load (to conserve memory)
% startFrameIndex = 1 + ((currShiftIndex-1)*round(v.NumFrames/16));
% endFrameIndex = (currShiftIndex*round(v.NumFrames/16));
startFrameIndex = 1;
endFrameIndex = v.NumFrames;
frameIndexes = startFrameIndex:endFrameIndex;
selectedNumberOfFrames = length(frameIndexes);

% Output Settings:
curr_output_data_path = fullfile(curr_video_file.full_parent_path,"Data"); % Location to save the data
mkdir(curr_output_data_path);

curr_output_settings.video_name_string = curr_video_file.basename;
% curr_output_settings.video_frame_string = sprintf("frames_%d-%d",num2str(startFrameIndex),num2str(endFrameIndex));
curr_output_settings.video_frame_string = sprintf("frames_%d-%d",startFrameIndex,endFrameIndex);
curr_output_settings.frames_data_output_suffix = 'output_indicator_region_intensities';

curr_output_settings.final_output_name = join([curr_output_settings.frames_data_output_suffix, curr_output_settings.video_name_string, curr_output_settings.video_frame_string, ".mat"],"_");
curr_output_settings.final_output_path = fullfile(curr_output_data_path, curr_output_settings.final_output_name);

% Read the frames
% frames = read(v,[startFrameIndex endFrameIndex],"native");

% Pre-allocate output structures
% greyscale_frames = zeros([v.Height, v.Width, selectedNumberOfFrames], 'uint8');
% processsed.mean_intensity = zeros([1, selectedNumberOfFrames], 'uint8');
mean_intensity_in_indicator_frame = zeros([1, selectedNumberOfFrames], 'uint8');
min_intensity_in_indicator_frame = zeros([1, selectedNumberOfFrames], 'uint8');

% Read one frame at a time. 
parfor k = 1 : selectedNumberOfFrames
%     greyscale_frames(:,:,k) = rgb2gray(frames(:,:,:,k));
%     greyscale_frames(:,:,k) = rgb2gray(read(v,k,"native"));
    curr_greyscale_frame = rgb2gray(read(v,k,"native"));
    %% Select small portion of the video frame for all frames.
    gate_indicator_frame_region = curr_greyscale_frame(9:18,320:335); % Get the small region of the current frame
    min_intensity_in_indicator_frame(k)= squeeze(min(gate_indicator_frame_region,[],[1,2])); %% Remove dimensions of length 1
    mean_intensity_in_indicator_frame(k) = squeeze(mean(gate_indicator_frame_region, [1,2]));
    % region_mean_per_frame =  squeeze(mean(gate_indicator_frame_region, [1,2]));
%     region_mean_per_frame = squeeze(min(gate_indicator_frame_region,[], [1,2])); %% Remove dimensions of length 1
end

% Done looping through frames:
save(curr_output_settings.final_output_path,'min_intensity_in_indicator_frame', 'mean_intensity_in_indicator_frame','frameIndexes','-v7.3');

%% Post Analayis
% https://www.mathworks.com/matlabcentral/answers/230702-how-to-find-consecutive-values-above-a-certain-threshold
threshold = 120;
num_consecutive_frames_above_threshold = 40; % at 20fps that's 2 seconds
% Find logical vector where A > threshold
binaryVector = min_intensity_in_indicator_frame > threshold;
% Label each region with a label - an "ID" number.
[labeledVector, numRegions] = bwlabel(binaryVector);
% Measure lengths of each region and the indexes
measurements = regionprops(labeledVector, min_intensity_in_indicator_frame, 'Area', 'PixelValues', 'BoundingBox');
% Find regions where the area (length) are 3 or greater and
% put the values into a cell of a cell array
% toRemoveIndicies = zeros(numRegions,2);
toRemoveIndicies = [];
for k = 1 : numRegions
  if measurements(k).Area >= num_consecutive_frames_above_threshold
    % Area (length) is num_consecutive_frames_above_threshold or greater, so store the values.
%     ca{k} = measurements(k).PixelValues; % Stores the frames where such is the case?
    currPosition = round(measurements(k).BoundingBox(1));
    currWidth = ceil(measurements(k).BoundingBox(3));
%     toRemoveIndicies(k,:) = [currPosition, (currPosition+currWidth)];
    toRemoveIndicies = [toRemoveIndicies; [currPosition, (currPosition+currWidth)]];
    % Get current binary region:
%     currBinaryVectorRegion = ismember(labeledVector, k) > 0;
  end
end
% Display the regions that meet the criteria:
% celldisp(ca)
save(curr_output_settings.final_output_path,'min_intensity_in_indicator_frame', 'mean_intensity_in_indicator_frame','frameIndexes','toRemoveIndicies','-v7.3');

% toRemoveIndicies: contain the indicies that contain human movement and should be spliced out.

% Draw the thing
temp = double(min_intensity_in_indicator_frame);
temp(~binaryVector) = 0;
hold off;
plot(temp);
title('Mean Gate Intensity - Thresholded')

