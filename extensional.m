% Demo to extract frames and get frame means from a movie and save individual frames to separate image files.
% Then rebuilds a new movie by recalling the saved images from disk.
% Also computes the Diameter of the filament
% And detects the difference between a frame and the previous frame.
% Illustrates the use of the VideoReader and VideoWriter classes.
% A Mathworks demo (different than mine) is located here http://www.mathworks.com/help/matlab/examples/convert-between-image-sequences-and-video.html

clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
imtool close all;  % Close all imtool figures.
clear;  % Erase all existing variables.
workspace;  % Make sure the workspace panel is showing.
fontSize = 15;

% Open the sample.avi in MATLAB.
% First get the folder that it lives in.
folder = fileparts('C:\Users\Asus\Downloads\'); % Determine where folder the is.
movieFullFileName = fullfile(folder, 'sample1.avi');
% Check to see that it exists.
if ~exist(movieFullFileName, 'file')
	strErrorMessage = sprintf('File not found:\n%s\nYou can choose a new one, or cancel', movieFullFileName);
	response = questdlg(strErrorMessage, 'File not found', 'OK - choose a new movie.', 'Cancel', 'OK - choose a new movie.');
	if strcmpi(response, 'OK - choose a new movie.')
		[baseFileName, folderName, FilterIndex] = uigetfile('*.avi');
		if ~isequal(baseFileName, 0)
			movieFullFileName = fullfile(folderName, baseFileName);
		else
			return;
		end
	else
		return;
	end
end

try
	videoObject = VideoReader(movieFullFileName)
	% Determine how many frames there are.
	numberOfFrames = videoObject.NumberOfFrames;

	vidHeight = videoObject.Height;
	vidWidth = videoObject.Width;
	
	numberOfFramesWritten = 0;

	% Prepare a figure to show the images in the upper half of the screen.
	figure;
	% 	screenSize = get(0, 'ScreenSize');
	% Enlarge figure to full screen.
	set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
	
	% Ask user if they want to write the individual frames out to disk.
	promptMessage = sprintf('Do you want to save the individual frames out to individual disk files?');
	button = questdlg(promptMessage, 'Save individual frames?', 'Yes', 'No', 'Yes');
	if strcmp(button, 'Yes')
		writeToDisk = true;
		
		% Extract out the various parts of the filename.
		[folder, baseFileName, extentions] = fileparts(movieFullFileName);
		% Make up a special new output subfolder for all the separate
		% movie frames that we're going to extract and save to disk.
		% (Don't worry - windows can handle forward slashes in the folder name.)
		folder = pwd;   % Make it a subfolder of the folder where this m-file lives.
		outputFolder = sprintf('%s/Movie Frames from %s', folder, baseFileName);
		% Create the folder if it doesn't exist already.
		if ~exist(outputFolder, 'dir')
			mkdir(outputFolder);
		end
	else
		writeToDisk = false;
	end
	
	% Loop through the movie, writing all frames out.
	% Each frame will be in a separate file with unique name.
   	Diameter = zeros(numberOfFramesWritten,1);
        time = linspace(1,numberOfFrames,numberOfFrames);
	for frame = 1 : numberOfFrames

		% Extract the frame from the movie structure.
		thisFrame = read(videoObject, frame);
		
		% Display it
		hImage = subplot(2, 3, 1);
		image(thisFrame);
		caption = sprintf('Frame %4d of %d.', frame, numberOfFrames);
		title(caption, 'FontSize', fontSize);
		drawnow; % Force it to refresh the window.
		
		% Write the image array to the output file, if requested.
		if writeToDisk
			% Construct an output image file name.
			outputBaseFileName = sprintf('Frame %4.4d.png', frame);
			outputFullFileName = fullfile(outputFolder, outputBaseFileName);
			
			% Stamp the name and frame number onto the image.
			% At this point it's just going into the overlay,
			% not actually getting written into the pixel values.
			text(5, 15, outputBaseFileName, 'FontSize', 15);
			
			% Extract the image with the text "burned into" it.
			frameWithText = getframe(gca);
			% frameWithText.cdata is the image with the text
			% actually written into the pixel values.
			% Write it out to disk.
			imwrite(frameWithText.cdata, outputFullFileName, 'png');
		end
		
		% Calculate the diameter.
		grayImage = rgb2gray(thisFrame);% Convert image from rgb to gray
        EdgeFrame = edge(grayImage,"Roberts");% Detect edges
        se=ones(30,8);% Taking a rectangle structural element
        morf = imclose(EdgeFrame,se); % Using Morphology , making image more white to connect the disconnecting lines
        [height, width, dim] = size(morf); % To extract the height and width from the image
        Graycrop = imcrop(morf,[width/4 (height/3) width/2 20]); % Crop the image // imcrop(I , rectangle) .rectangle is a four element position vector[xmin ymin width height]
        % Plot the Morph image
        subplot(2,3,6);
        imshow(morf);
	t = zeros(2,20);% Create an array which stores left edge and right edge in 1st and 2nd row respectively
        for i=1:20 % Iteration of i to go through each column
            r = find((Graycrop(i,:)));% r is a column matrix which stores the index of pixels where the value is 1. 
            if isempty(r) % Continue the loop if r is empty i.e we get an null column matrix
                disp(i)
                continue % Goes to next iteration i.e next value of i
            end
            L = length(r);% Finding the length of the column matrix if its a non zero matrix
            t(1,i)=r(1);% Store the index of the first time it gets white pixel, i.e left edge
            t(2,i)=r(L);% Store the index of the last time it gest white pixel, i.e right edge
        end
        left_edge = max(t(1,:));% Distance of left edge
        right_edge = min(t(2,:));% Distance of lower edge

        Diameter(frame) = abs(left_edge - right_edge); % Calculate the absolute value of diameter of filament
        Diameter(frame) = 0.5*(Diameter(frame));
		% Diameter(frame)=Diameter(frame)*2;
		% Plot the diameter vs frame.
		hPlot = subplot(2, 3, 2);
		hold off;
		plot(Diameter, 'k-', 'LineWidth', 1.5);
		hold on;
		grid on;
		
		% Put title back because plot() erases the existing title.
		title('Diameter vs Frame', 'FontSize', fontSize);
		if frame == 1
			xlabel('Frame Number');
			ylabel('Diameter');
			% Get size data later for preallocation if we read
			% the movie back in from disk.
			[rows, columns, numberOfColorChannels] = size(thisFrame);
		end
		
		% Update user with the progress.  Display in the command window.
		if writeToDisk
			progressIndication = sprintf('Wrote frame %4d of %d.', frame, numberOfFrames);
		else
			progressIndication = sprintf('Processed frame %4d of %d.', frame, numberOfFrames);
		end
		disp(progressIndication);
		% Increment frame count (should eventually = numberOfFrames
		% unless an error happens).
		numberOfFramesWritten = numberOfFramesWritten + 1;
		
		% Now let's do the differencing
		alpha = 0.5;
		if frame == 1
			Background = thisFrame;
		else
			% Change background slightly at each frame
			% 			Background(t+1)=(1-alpha)*I+alpha*Background
			Background = (1-alpha)* thisFrame + alpha * Background;
		end
		% Display the changing/adapting background.
		subplot(2, 3, 3);
		imshow(Background);
		title('Adaptive Background', 'FontSize', fontSize);
		% Plot the edge image.
		subplot(2, 3, 4);
		imshow(EdgeFrame);
        title('Edge Frame Image', 'FontSize', fontSize);
        subplot(2, 3, 5);
		imshow(Graycrop);
		title('Crop Frame Image', 'FontSize', fontSize);
	end
    	time=time*10/30;
	h=log(Diameter);
    	figure()
    	tiledlayout(1,2)
    	nexttile
    
    	plot(time,h,'bo')
    	ylabel('log(Diameter)')
    	xlabel('time')
    	a=polyfit(time,h,1);
    	hold on
    	plot (time,a(1)*time + a(2),'k-')
    	nexttile
    	plot(time,Diameter,'bo',time,exp(a(1)*time + a(2)),'k-')
    	ylabel('Diameter')
    	xlabel('time')
    	title( sprintf('Diameter = %.2f e^{%.2f t}', exp(a(2)), a(1)) );
	
	% Alert user that we're done.
	if writeToDisk
		finishedMessage = sprintf('Done!  It wrote %d frames to folder\n"%s"', numberOfFramesWritten, outputFolder);
	else
		finishedMessage = sprintf('Done!  It processed %d frames of\n"%s"', numberOfFramesWritten, movieFullFileName);
	end
	disp(finishedMessage); % Write to command window.
	uiwait(msgbox(finishedMessage)); % Also pop up a message box.
	
	% Exit if they didn't write any individual frames out to disk.
	if ~writeToDisk
		return;
	end
	
	% Ask user if they want to read the individual frames from the disk,
	% that they just wrote out, back into a movie and display it.
	promptMessage = sprintf('Do you want to recall the individual frames\nback from disk into a movie?\n(This will take several seconds.)');
	button = questdlg(promptMessage, 'Recall Movie?', 'Yes', 'No', 'Yes');
	if strcmp(button, 'No')
		return;
	end

	% Create a VideoWriter object to write the video out to a new, different file.
	writerObj = VideoWriter('FinalPlot.avi');
	open(writerObj);
	
	% Read the frames back in from disk, and convert them to a movie.
	% Preallocate recalledMovie, which will be an array of structures.
	% First get a cell array with all the frames.
	allTheFrames = cell(numberOfFrames,1);
	allTheFrames(:) = {zeros(vidHeight, vidWidth, 3, 'uint8')};
	% Next get a cell array with all the colormaps.
	allTheColorMaps = cell(numberOfFrames,1);
	allTheColorMaps(:) = {zeros(256, 3)};
	% Now combine these to make the array of structures.
	recalledMovie = struct('cdata', allTheFrames, 'colormap', allTheColorMaps)
	for frame = 1 : numberOfFrames
		% Construct an output image file name.
		outputBaseFileName = sprintf('Frame %4.4d.png', frame);
		outputFullFileName = fullfile(outputFolder, outputBaseFileName);
		% Read the image in from disk.
		thisFrame = imread(outputFullFileName);
		% Convert the image into a "movie frame" structure.
		recalledMovie(frame) = im2frame(thisFrame);
		% Write this frame out to a new video file.
		writeVideo(writerObj, thisFrame);
	end
	close(writerObj);
	% Get rid of old image and plot.
	delete(hImage);
	delete(hPlot);
	% Create new axes for our movie.
	subplot(1, 3, 2);
	axis off;  % Turn off axes numbers.
	title('Movie recalled from disk', 'FontSize', fontSize);
	% Play the movie in the axes.
	movie(recalledMovie);
	% Note: if you want to display graphics or text in the overlay
	% as the movie plays back then you need to do it like I did at first
	% (at the top of this file where you extract and imshow a frame at a time.)
	msgbox('Done with this demo!');
	
catch ME
	% Some error happened if you get here.

 	strErrorMessage = sprintf('Error extracting movie frames from:\n\n%s\n\nError: %s\n\n)', movieFullFileName, ME.message);
	uiwait(msgbox(strErrorMessage));
end
