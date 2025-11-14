function RNAPunctaCounterGUI    

% START IGNORING HERE THIS IS ALL GUI STUFF!!!!

    fig = uifigure('Name', 'counting RNA puncta', 'WindowState', 'maximized');
    
    data = struct();
    data.imageFiles = {};
    data.currentIndex = 1;
    data.originalImage = [];
    data.processedImage = [];
    data.resultsTable = table();
    data.imageSettings = struct(); % for carrying over settings per image
    
    createUIComponents();
    function createUIComponents()
        mainGrid = uigridlayout(fig, [1 1]);
       
        leftPanel = uipanel(mainGrid);
        leftPanel.Layout.Row = 1;
        leftPanel.Layout.Column = 1;
        leftGrid = uigridlayout(leftPanel, [2 1]);
        leftGrid.RowHeight = {'1x', 280}; % image pane = remaining space, controls pane 280px
        
        imageGrid = uigridlayout(leftGrid, [1 2]);
        imageGrid.Layout.Row = 1;
        imageGrid.ColumnWidth = {'1x', '1x'};
        imageGrid.Padding = [5 5 5 5];
        imageGrid.RowSpacing = 5;
        imageGrid.ColumnSpacing = 5;
        
        % OG image panel
        origPanel = uipanel(imageGrid, 'Title', 'Original Image');
        origPanel.FontSize = 14;
        origPanel.FontWeight = 'bold';
        
        % edited image panel
        procPanel = uipanel(imageGrid, 'Title', 'Processed Image');
        procPanel.FontSize = 14;
        procPanel.FontWeight = 'bold';

        % image axes (border) fill panels completely
        data.axesOriginal = axes(origPanel, 'Units', 'normalized', 'Position', [0 0 1 1]);
        axis(data.axesOriginal, 'off');
        data.axesProcessed = axes(procPanel, 'Units', 'normalized', 'Position', [0 0 1 1]);
        axis(data.axesProcessed, 'off');
        
        % zoom/pan
        zoom(data.axesOriginal, 'on');
        pan(data.axesOriginal, 'on');
        zoom(data.axesProcessed, 'on');
        pan(data.axesProcessed, 'on');
        
        % control panel
        controlPanel = uipanel(leftGrid, 'Title', 'Controls');
        controlPanel.Layout.Row = 2;
        yPos = 230;
        spacing = 45;
        
        % brightness slider
        uilabel(controlPanel, 'Position', [10 yPos 100 22], 'Text', 'Brightness:', 'FontSize', 11, 'FontWeight', 'bold');
        data.brightnessSlider = uislider(controlPanel, 'Position', [120 yPos+5 200 3], 'Value', 0, ...
            'Limits', [-100 100], 'ValueChangedFcn', @(~,~)updateProcessing(false));
        yPos = yPos - spacing;
        
        % contrast slider
        uilabel(controlPanel, 'Position', [10 yPos 100 22], 'Text', 'Contrast:', 'FontSize', 11, 'FontWeight', 'bold');
        data.contrastSlider = uislider(controlPanel, 'Position', [120 yPos+5 200 3], 'Value', 0, ...
            'Limits', [0 3], 'ValueChangedFcn', @(~,~)updateProcessing(false));
        yPos = yPos - spacing;
        
        % smoothing slider
        uilabel(controlPanel, 'Position', [10 yPos 100 22], 'Text', 'Smoothing:', 'FontSize', 11, 'FontWeight', 'bold');
        data.smoothSlider = uislider(controlPanel, 'Position', [120 yPos+5 200 3], 'Value', 0, ...
            'Limits', [0 5], 'ValueChangedFcn', @(~,~)updateProcessing(false));
        yPos = yPos - 60; % space before buttons
        
        % buttons
        btnWidth = 110;
        btnY = yPos;
        btnX = 10;
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'LOAD IMAGES', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)loadFolder());
        btnX = btnX + btnWidth + 5;
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'PREVIOUS', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)previousImage());
        btnX = btnX + btnWidth + 5;
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'NEXT', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)nextImage());
        btnX = btnX + btnWidth + 5;
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'RESET', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)resetSliders(), 'BackgroundColor', [1 0.8 0.4]);
        yPos = yPos - 40;
        btnY2 = yPos;
        data.countButton = uibutton(controlPanel, 'Position', [10 btnY2 220 35], 'Text', 'count puncta', 'FontSize', 13, ...
            'ButtonPushedFcn', @(~,~)countPuncta(), 'BackgroundColor', [0.2 0.8 0.2], 'FontWeight', 'bold');
        data.statusLabel = uilabel(controlPanel, 'Position', [240 btnY2 300 35], 'Text', '', 'FontSize', 12, 'FontWeight', 'bold');
    end

    function loadFolder()
        folderPath = uigetdir('', 'select image folder');
        if folderPath == 0
            return;
        end
        
        % get image files
        data.imageFiles = {};
        allFiles = dir(folderPath);
        
        for i = 1:length(allFiles)
            if allFiles(i).isdir
                continue;
            end
            [~, ~, ext] = fileparts(allFiles(i).name);
            ext = lower(ext);
            if ismember(ext, {'.tif', '.tiff'})
                data.imageFiles{end+1} = fullfile(folderPath, allFiles(i).name);
            end
        end
        
        % create empty results table for saving puncta counts
        data.resultsTable = table('Size', [length(data.imageFiles), 5], ...
            'VariableTypes', {'string', 'double', 'double', 'double', 'cell'}, ...
            'VariableNames', {'Filename', 'PunctaCount', 'MeanSize', 'TotalArea', 'IndividualSizes'});
             
        % to preserve the brightness/contrast/etc sliders for each image when you click next
        data.imageSettings = struct(); 
        for i = 1:length(data.imageFiles)
            data.imageSettings(i).brightness = 0;
            data.imageSettings(i).contrast = 0;
            data.imageSettings(i).smoothing = 0;
            data.imageSettings(i).minSize = 0;
            data.imageSettings(i).xlim = [];
            data.imageSettings(i).ylim = [];
        end
        
        data.currentIndex = 1;
        loadCurrentImage();
    end

% OK YOU CAN LOOK AT THE CODE NOW!!

    function loadCurrentImage()
        if isempty(data.imageFiles)
            return;
        end
        
        % load image
        data.originalImage = imread(data.imageFiles{data.currentIndex});
        data.originalImage = im2double(data.originalImage);
       
        % load saved settings for current image
        idx = data.currentIndex;
        data.brightnessSlider.Value = data.imageSettings(idx).brightness;
        data.contrastSlider.Value = data.imageSettings(idx).contrast;
        data.smoothSlider.Value = data.imageSettings(idx).smoothing;
        data.minSizeField.Value = data.imageSettings(idx).minSize;
        
        % display original side by side
        cla(data.axesOriginal);
        imshow(data.originalImage, 'Parent', data.axesOriginal);
        axis(data.axesOriginal, 'image');
        
        if ~isempty(data.imageSettings(idx).xlim)
            xlim(data.axesOriginal, data.imageSettings(idx).xlim);
            ylim(data.axesOriginal, data.imageSettings(idx).ylim);
        end
        
        updateProcessing(true);
 
        if ~isnan(data.resultsTable.PunctaCount(idx))
            data.statusLabel.Text = sprintf('Puncta: %d', data.resultsTable.PunctaCount(idx));
            data.statusLabel.FontColor = [0 0.6 0];
        else
            data.statusLabel.Text = '';
        end
    end
    
    function saveCurrentSettings()
        idx = data.currentIndex;
        data.imageSettings(idx).brightness = data.brightnessSlider.Value;
        data.imageSettings(idx).contrast = data.contrastSlider.Value;
        data.imageSettings(idx).smoothing = data.smoothSlider.Value;
        data.imageSettings(idx).minSize = data.minSizeField.Value;
        data.imageSettings(idx).xlim = xlim(data.axesProcessed);
        data.imageSettings(idx).ylim = ylim(data.axesProcessed);
    end

    function updateProcessing(restoreZoom)
        if isempty(data.originalImage)
            return;
        end
        
        % save zoom state 
        if ~restoreZoom
            saveCurrentSettings();
        end
        
        if ~restoreZoom && isvalid(data.axesProcessed)
            currentXLim = xlim(data.axesProcessed);
            currentYLim = ylim(data.axesProcessed);
        else
            idx = data.currentIndex;
            if ~isempty(data.imageSettings(idx).xlim)
                currentXLim = data.imageSettings(idx).xlim;
                currentYLim = data.imageSettings(idx).ylim;
            else
                currentXLim = [];
                currentYLim = [];
            end
        end
        
        img = data.originalImage;
        
        % apply brightness/contrast if slider is NOT at 0
        if data.brightnessSlider.Value ~= 0
            brightness = data.brightnessSlider.Value / 100; % brightness in matlab NOT fiji!!!!! why 100? slider's range is from -100 to +100
            % adds or subtracts a constant value from every pixel's intensity
            img = img + brightness;
            % after adding brightness, caps values between 0 and 1 (max(0, min(1, img))) since MATLAB's im2double images store pixel intensities in that range
            img = max(0, min(1, img));
      
        end
        
        % gamma adjustment for contrast using imadjust: contrast up (slider > 0): increases the gamma so darks get darker, brights get brighter
        if data.contrastSlider.Value ~= 0
            contrast = 1 + data.contrastSlider.Value;
            img = imadjust(img, [], [], contrast); 
            % gamma < 1 mid-tones brighter (more contrast in shadows)
            % > 1 mid-tones darker (more contrast in highlights)
        end
        
        % apply smoothing if slider is not at 0 (Gaussian blur imgaussfilt w standard deviation sigma)
        if data.smoothSlider.Value > 0
            sigma = data.smoothSlider.Value;
            img = imgaussfilt(img, sigma);
        end
        
        % has any editing has been applied??
        anyProcessing = (data.brightnessSlider.Value ~= 0) || ...
                       (data.contrastSlider.Value ~= 0) || ...
                       (data.smoothSlider.Value > 0);
        
        % display edited image
        cla(data.axesProcessed);
        if ~anyProcessing
            imshow(data.originalImage, 'Parent', data.axesProcessed);
        else
            imshow(img, 'Parent', data.axesProcessed);
        end
        axis(data.axesProcessed, 'image');
        
        if ~isempty(currentXLim)
            xlim(data.axesProcessed, currentXLim);
            ylim(data.axesProcessed, currentYLim);
        end
        
        % store edited image for thresholding (count puncta)
        data.adjustedImage = img;
        data.processedImage = [];
    end

    function countPuncta()
        if isempty(data.originalImage)
            uialert(fig, 'no image loaded', 'Error');
            return;
        end
        
        currentXLim = xlim(data.axesProcessed);
        currentYLim = ylim(data.axesProcessed);
        
        % use adjusted image: user modified contrast/brightness/etc etc
        if isfield(data, 'adjustedImage') && ~isempty(data.adjustedImage)
            img = data.adjustedImage;
        else
            img = data.originalImage; % was unedited use OG
        end
        
        % apply threshold (matlab graythresh() function uses Otsu's method to automatically pick a threshold)
        % separates foreground (bright puncta) from background (black)
        level = graythresh(img);
        bw = imbinarize(img, level); % imbinarize(): turns all pixels above that threshold into 1 (white), below into 0 (black)

        
        % clean up small objects only if min size > 0 (specified by user slider)
        if data.minSizeField.Value > 0 
            minSize = data.minSizeField.Value;
            bw = bwareaopen(bw, round(minSize));
        end
        
        % store the binary mask
        data.processedImage = bw;
        
        % label connected components
        labeled = bwlabel(bw); 
        stats = regionprops(labeled, 'Area', 'Centroid'); % centroid =(x,y) center point (for the countmask overlay visualization)
        
        % count puncta: separate fubnctuib to display threshold before
        % image (graythres? otsu? fiji integration) watershed
        numPuncta = length(stats);
        
        if numPuncta == 0
            areas = [];
            meanArea = 0;
        else
            areas = [stats.Area]; % size of each puncta
            meanArea = mean(areas);
        end
        
        % store results in table
        [~, fname, ext] = fileparts(data.imageFiles{data.currentIndex});
        data.resultsTable.Filename(data.currentIndex) = string([fname ext]);
        data.resultsTable.PunctaCount(data.currentIndex) = numPuncta;
        data.resultsTable.MeanSize(data.currentIndex) = meanArea;
        data.resultsTable.TotalArea(data.currentIndex) = sum(areas);
        data.resultsTable.IndividualSizes{data.currentIndex} = areas;
            
        % colored visualization!!!!!
        rgb = label2rgb(labeled, 'jet', 'k', 'shuffle');
        
        % display counting mask with puncta labels (numbered connected comps)
        cla(data.axesProcessed);
        imshow(rgb, 'Parent', data.axesProcessed);
        axis(data.axesProcessed, 'image');
        hold(data.axesProcessed, 'on');
        for i = 1:length(stats)
            % add text to the formerly stored/calculated Centroid of each puncta connected comp
            text(data.axesProcessed, stats(i).Centroid(1), stats(i).Centroid(2), ...
                sprintf('%d', i), 'Color', 'white', 'FontSize', 10, ... % CHANGE THIS TO MAKE THE TEXT SMALLER!!!!
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        end
        hold(data.axesProcessed, 'off');
        title(data.axesProcessed, sprintf('counted puncta mask (n=%d)', numPuncta), ...
            'FontSize', 14, 'FontWeight', 'bold');
        
        xlim(data.axesProcessed, currentXLim);
        ylim(data.axesProcessed, currentYLim);
        
        % update labels
        data.statusLabel.Text = sprintf('counted %d puncta (Mean: %.1f px)', numPuncta, meanArea);
        data.statusLabel.FontColor = [0 0.6 0];
    end

    function previousImage()
        if isempty(data.imageFiles) || data.currentIndex <= 1
            return;
        end
        saveCurrentSettings();
        data.currentIndex = data.currentIndex - 1;
        loadCurrentImage();
    end

    function nextImage()
        if isempty(data.imageFiles) || data.currentIndex >= length(data.imageFiles)
            return;
        end
        saveCurrentSettings();
        data.currentIndex = data.currentIndex + 1;
        loadCurrentImage();
    end
    
    function resetSliders()
        if isempty(data.originalImage)
            return;
        end
        
        % reset sliders to default values
        data.brightnessSlider.Value = 0;
        data.contrastSlider.Value = 0;
        data.smoothSlider.Value = 0;
        data.minSizeField.Value = 0;
        
        updateProcessing(false);
        
        data.statusLabel.FontColor = [0.5 0.5 0.5];
    end
end