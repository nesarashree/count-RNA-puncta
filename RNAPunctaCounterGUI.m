function RNAPunctaCounterGUI
    % RNA Puncta Counter - GUI for threshold adjustment and puncta counting
    
    % Create main figure (maximized)
    fig = uifigure('Name', 'RNA Puncta Counter', 'WindowState', 'maximized');
    
    % Data structure to hold state
    data = struct();
    data.imageFiles = {};
    data.currentIndex = 1;
    data.originalImage = [];
    data.processedImage = [];
    data.resultsTable = table();
    data.imageSettings = struct(); % Store settings per image
    
    % Create UI components
    createUIComponents();
    
    function createUIComponents()
        % Create grid layout
        mainGrid = uigridlayout(fig, [1 2]);
        mainGrid.ColumnWidth = {'4x', 300}; % Fixed width for controls
        
        % Left panel - Images only
        leftPanel = uipanel(mainGrid);
        leftPanel.Layout.Row = 1;
        leftPanel.Layout.Column = 1;
        
        leftGrid = uigridlayout(leftPanel, [2 1]);
        leftGrid.RowHeight = {'1x', 200}; % Fixed height for controls
        
        % Image display panels
        imageGrid = uigridlayout(leftGrid, [1 2]);
        imageGrid.Layout.Row = 1;
        imageGrid.ColumnWidth = {'1x', '1x'};
        imageGrid.Padding = [5 5 5 5];
        imageGrid.RowSpacing = 5;
        imageGrid.ColumnSpacing = 5;
        
        % Original image panel
        origPanel = uipanel(imageGrid, 'Title', 'Original Image');
        origPanel.FontSize = 14;
        origPanel.FontWeight = 'bold';
        
        % Processed image panel
        procPanel = uipanel(imageGrid, 'Title', 'Processed Image');
        procPanel.FontSize = 14;
        procPanel.FontWeight = 'bold';
        
        % Create axes that fill panels completely
        data.axesOriginal = axes(origPanel, 'Units', 'normalized', 'Position', [0 0 1 1]);
        axis(data.axesOriginal, 'off');
        
        data.axesProcessed = axes(procPanel, 'Units', 'normalized', 'Position', [0 0 1 1]);
        axis(data.axesProcessed, 'off');
        
        % Add zoom/pan to both axes
        zoom(data.axesOriginal, 'on');
        pan(data.axesOriginal, 'on');
        zoom(data.axesProcessed, 'on');
        pan(data.axesProcessed, 'on');
        
        % Control panel - simple 2 column layout
        controlPanel = uipanel(leftGrid, 'Title', 'Controls');
        controlPanel.Layout.Row = 2;
        
        % Create controls using absolute positioning
        yPos = 160;
        spacing = 25;
        
        % Brightness
        uilabel(controlPanel, 'Position', [10 yPos 100 22], 'Text', 'Brightness:', 'FontSize', 11, 'FontWeight', 'bold');
        data.brightnessSlider = uislider(controlPanel, 'Position', [120 yPos+5 200 3], 'Value', 0, ...
            'Limits', [-100 100], 'ValueChangedFcn', @(~,~)updateProcessing(false));
        yPos = yPos - spacing;
        
        % Contrast
        uilabel(controlPanel, 'Position', [10 yPos 100 22], 'Text', 'Contrast:', 'FontSize', 11, 'FontWeight', 'bold');
        data.contrastSlider = uislider(controlPanel, 'Position', [120 yPos+5 200 3], 'Value', 0, ...
            'Limits', [0 3], 'ValueChangedFcn', @(~,~)updateProcessing(false));
        yPos = yPos - spacing;
        
        % Smoothing
        uilabel(controlPanel, 'Position', [10 yPos 100 22], 'Text', 'Smoothing:', 'FontSize', 11, 'FontWeight', 'bold');
        data.smoothSlider = uislider(controlPanel, 'Position', [120 yPos+5 200 3], 'Value', 0, ...
            'Limits', [0 5], 'ValueChangedFcn', @(~,~)updateProcessing(false));
        yPos = yPos - spacing;
        
        % Min size
        uilabel(controlPanel, 'Position', [10 yPos 100 22], 'Text', 'Min Size (px):', 'FontSize', 11, 'FontWeight', 'bold');
        data.minSizeField = uieditfield(controlPanel, 'numeric', 'Position', [120 yPos 80 22], 'Value', 0, ...
            'ValueChangedFcn', @(~,~)updateProcessing(false));
        yPos = yPos - 35;
        
        % Buttons
        btnWidth = 110;
        btnX = 10;
        uibutton(controlPanel, 'Position', [btnX yPos btnWidth 30], 'Text', 'Load Folder', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)loadFolder());
        btnX = btnX + btnWidth + 5;
        uibutton(controlPanel, 'Position', [btnX yPos btnWidth 30], 'Text', '← Previous', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)previousImage());
        btnX = btnX + btnWidth + 5;
        uibutton(controlPanel, 'Position', [btnX yPos btnWidth 30], 'Text', 'Next →', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)nextImage());
        btnX = btnX + btnWidth + 5;
        uibutton(controlPanel, 'Position', [btnX yPos btnWidth 30], 'Text', 'Reset', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)resetSliders(), 'BackgroundColor', [1 0.8 0.4]);
        yPos = yPos - 40;
        
        % Count button
        data.countButton = uibutton(controlPanel, 'Position', [10 yPos 450 35], 'Text', 'Count Puncta', 'FontSize', 13, ...
            'ButtonPushedFcn', @(~,~)countPuncta(), 'BackgroundColor', [0.2 0.8 0.2], 'FontWeight', 'bold');
        yPos = yPos - 40;
        
        % Export button
        data.exportButton = uibutton(controlPanel, 'Position', [10 yPos 450 30], 'Text', 'Export Results', 'FontSize', 12, ...
            'ButtonPushedFcn', @(~,~)exportResults());
        yPos = yPos - 30;
        
        % Labels at bottom
        data.imageLabel = uilabel(controlPanel, 'Position', [10 yPos-5 450 20], 'Text', 'No image loaded', ...
            'FontSize', 10, 'HorizontalAlignment', 'center');
        yPos = yPos - 25;
        
        data.countLabel = uilabel(controlPanel, 'Position', [10 yPos-5 450 22], 'Text', '', ...
            'FontSize', 13, 'FontWeight', 'bold', 'FontColor', [0 0.6 0], 'HorizontalAlignment', 'center');
        yPos = yPos - 25;
        
        data.statusLabel = uilabel(controlPanel, 'Position', [10 yPos-5 450 20], 'Text', 'Load a folder to begin', ...
            'FontWeight', 'bold', 'FontColor', [0.5 0.5 0.5], 'FontSize', 10, 'HorizontalAlignment', 'center');
        
        % Right panel - Results
        rightPanel = uipanel(mainGrid, 'Title', 'Results Summary');
        rightPanel.Layout.Row = 1;
        rightPanel.Layout.Column = 2;
        rightPanel.FontSize = 13;
        rightPanel.FontWeight = 'bold';
        
        rightGrid = uigridlayout(rightPanel, [1 1]);
        
        % Results table
        data.resultsUITable = uitable(rightGrid, 'FontSize', 10);
        data.resultsUITable.Layout.Row = 1;
    end

    function loadFolder()
        folderPath = uigetdir('', 'Select folder containing images');
        if folderPath == 0
            return;
        end
        
        % Get all image files (case-insensitive)
        data.imageFiles = {};
        allFiles = dir(folderPath);
        
        for i = 1:length(allFiles)
            if allFiles(i).isdir
                continue;
            end
            [~, ~, ext] = fileparts(allFiles(i).name);
            ext = lower(ext);
            if ismember(ext, {'.tif', '.tiff', '.png', '.jpg', '.jpeg', '.bmp'})
                data.imageFiles{end+1} = fullfile(folderPath, allFiles(i).name);
            end
        end
        
        if isempty(data.imageFiles)
            uialert(fig, 'No image files found in selected folder', 'Error');
            return;
        end
        
        % Initialize results table
        data.resultsTable = table('Size', [length(data.imageFiles), 5], ...
            'VariableTypes', {'string', 'double', 'double', 'double', 'cell'}, ...
            'VariableNames', {'Filename', 'PunctaCount', 'MeanSize', 'TotalArea', 'IndividualSizes'});
        
        % Initialize settings storage for each image
        data.imageSettings = struct();
        for i = 1:length(data.imageFiles)
            data.imageSettings(i).brightness = 0;
            data.imageSettings(i).contrast = 0;
            data.imageSettings(i).smoothing = 0;
            data.imageSettings(i).minSize = 0;
            data.imageSettings(i).xlim = [];
            data.imageSettings(i).ylim = [];
        end
        
        % Load first image
        data.currentIndex = 1;
        loadCurrentImage();
        
        data.statusLabel.Text = sprintf('Loaded %d images', length(data.imageFiles));
    end

    function loadCurrentImage()
        if isempty(data.imageFiles)
            return;
        end
        
        % Save current zoom/pan state before switching
        if ~isempty(data.originalImage)
            idx = data.currentIndex;
            % Will be saved by the image we're leaving, handled in next/previous
        end
        
        % Load image
        data.originalImage = imread(data.imageFiles{data.currentIndex});
        
        % Convert to grayscale if needed
        if size(data.originalImage, 3) > 1
            data.originalImage = rgb2gray(data.originalImage);
        end
        
        % Convert to double for processing
        data.originalImage = im2double(data.originalImage);
        
        % Update image label
        [~, fname, ext] = fileparts(data.imageFiles{data.currentIndex});
        data.imageLabel.Text = sprintf('Image %d/%d: %s%s', ...
            data.currentIndex, length(data.imageFiles), fname, ext);
        
        % Load saved settings for this image
        idx = data.currentIndex;
        data.brightnessSlider.Value = data.imageSettings(idx).brightness;
        data.contrastSlider.Value = data.imageSettings(idx).contrast;
        data.smoothSlider.Value = data.imageSettings(idx).smoothing;
        data.minSizeField.Value = data.imageSettings(idx).minSize;
        
        % Display original
        cla(data.axesOriginal);
        imshow(data.originalImage, 'Parent', data.axesOriginal);
        axis(data.axesOriginal, 'image');
        title(data.axesOriginal, 'Original Image', 'FontSize', 14, 'FontWeight', 'bold');
        
        % Restore zoom if saved
        if ~isempty(data.imageSettings(idx).xlim)
            xlim(data.axesOriginal, data.imageSettings(idx).xlim);
            ylim(data.axesOriginal, data.imageSettings(idx).ylim);
        end
        
        % Update processing with saved settings
        updateProcessing(true);
        
        % Update count label if already processed
        if ~isnan(data.resultsTable.PunctaCount(idx))
            data.countLabel.Text = sprintf('Puncta: %d', data.resultsTable.PunctaCount(idx));
        else
            data.countLabel.Text = '';
        end
    end
    
    function saveCurrentSettings()
        % Save current settings and zoom state
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
        
        % Save zoom state before update
        if ~restoreZoom
            saveCurrentSettings();
        end
        
        % Get current zoom limits
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
        
        % Only apply brightness if slider is not at 0
        if data.brightnessSlider.Value ~= 0
            brightness = data.brightnessSlider.Value / 100;
            img = img + brightness;
            img = max(0, min(1, img));
        end
        
        % Only apply contrast if slider is not at 0
        if data.contrastSlider.Value ~= 0
            contrast = 1 + data.contrastSlider.Value;
            img = imadjust(img, [], [], contrast);
        end
        
        % Only apply smoothing if slider is not at 0
        if data.smoothSlider.Value > 0
            sigma = data.smoothSlider.Value;
            img = imgaussfilt(img, sigma);
        end
        
        % Check if any processing has been applied
        anyProcessing = (data.brightnessSlider.Value ~= 0) || ...
                       (data.contrastSlider.Value ~= 0) || ...
                       (data.smoothSlider.Value > 0);
        
        % Display processed image
        cla(data.axesProcessed);
        if ~anyProcessing
            imshow(data.originalImage, 'Parent', data.axesProcessed);
            title(data.axesProcessed, 'Processed Image (No adjustments)', 'FontSize', 14, 'FontWeight', 'bold');
        else
            imshow(img, 'Parent', data.axesProcessed);
            title(data.axesProcessed, 'Adjusted Image (Ready to threshold)', 'FontSize', 14, 'FontWeight', 'bold');
        end
        axis(data.axesProcessed, 'image');
        
        % Restore zoom
        if ~isempty(currentXLim)
            xlim(data.axesProcessed, currentXLim);
            ylim(data.axesProcessed, currentYLim);
        end
        
        % Store the adjusted image for thresholding
        data.adjustedImage = img;
        data.processedImage = [];
    end

    function countPuncta()
        if isempty(data.originalImage)
            uialert(fig, 'No image loaded', 'Error');
            return;
        end
        
        % Save current zoom state
        currentXLim = xlim(data.axesProcessed);
        currentYLim = ylim(data.axesProcessed);
        
        % Use adjusted image if available, otherwise use original
        if isfield(data, 'adjustedImage') && ~isempty(data.adjustedImage)
            img = data.adjustedImage;
        else
            img = data.originalImage;
        end
        
        % Apply threshold
        try
            level = graythresh(img);
            bw = imbinarize(img, level);
        catch
            bw = imbinarize(img);
        end
        
        % Clean up small objects only if min size > 0
        if data.minSizeField.Value > 0
            minSize = data.minSizeField.Value;
            bw = bwareaopen(bw, round(minSize));
        end
        
        % Store the binary mask
        data.processedImage = bw;
        
        % Label connected components
        labeled = bwlabel(bw);
        stats = regionprops(labeled, 'Area', 'Centroid');
        
        % Count puncta
        numPuncta = length(stats);
        
        if numPuncta == 0
            areas = [];
            meanArea = 0;
            totalArea = 0;
        else
            areas = [stats.Area];
            meanArea = mean(areas);
            totalArea = sum(areas);
        end
        
        % Store results
        [~, fname, ext] = fileparts(data.imageFiles{data.currentIndex});
        data.resultsTable.Filename(data.currentIndex) = string([fname ext]);
        data.resultsTable.PunctaCount(data.currentIndex) = numPuncta;
        data.resultsTable.MeanSize(data.currentIndex) = meanArea;
        data.resultsTable.TotalArea(data.currentIndex) = totalArea;
        data.resultsTable.IndividualSizes{data.currentIndex} = areas;
        
        % Update display table
        data.resultsUITable.Data = data.resultsTable(:, 1:4);
        
        % Create colored visualization
        rgb = label2rgb(labeled, 'jet', 'k', 'shuffle');
        
        % Display with numbers
        cla(data.axesProcessed);
        imshow(rgb, 'Parent', data.axesProcessed);
        axis(data.axesProcessed, 'image');
        hold(data.axesProcessed, 'on');
        for i = 1:length(stats)
            text(data.axesProcessed, stats(i).Centroid(1), stats(i).Centroid(2), ...
                sprintf('%d', i), 'Color', 'white', 'FontSize', 10, ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        end
        hold(data.axesProcessed, 'off');
        title(data.axesProcessed, sprintf('Labeled Puncta (n=%d)', numPuncta), ...
            'FontSize', 14, 'FontWeight', 'bold');
        
        % Restore zoom
        xlim(data.axesProcessed, currentXLim);
        ylim(data.axesProcessed, currentYLim);
        
        % Update labels
        data.countLabel.Text = sprintf('Puncta: %d', numPuncta);
        data.statusLabel.Text = sprintf('Counted %d puncta (Mean: %.1f px)', numPuncta, meanArea);
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

    function exportResults()
        if isempty(data.resultsTable) || height(data.resultsTable) == 0
            uialert(fig, 'No results to export', 'Error');
            return;
        end
        
        [file, path] = uiputfile('*.csv', 'Save Results As');
        if file == 0
            return;
        end
        
        % Export summary (without cell array column)
        summaryTable = data.resultsTable(:, 1:4);
        writetable(summaryTable, fullfile(path, file));
        
        % Also export detailed sizes
        [~, fname, ~] = fileparts(file);
        detailFile = fullfile(path, [fname '_detailed.mat']);
        resultsTable = data.resultsTable;
        save(detailFile, 'resultsTable');
        
        uialert(fig, sprintf('Results exported to:\n%s\n%s', ...
            fullfile(path, file), detailFile), 'Success');
        
        data.statusLabel.Text = 'Results exported successfully';
        data.statusLabel.FontColor = [0 0.6 0];
    end
    
    function resetSliders()
        if isempty(data.originalImage)
            return;
        end
        
        % Reset all sliders to default values
        data.brightnessSlider.Value = 0;
        data.contrastSlider.Value = 0;
        data.smoothSlider.Value = 0;
        data.minSizeField.Value = 0;
        
        % Update processing to show original image
        updateProcessing(false);
        
        data.statusLabel.Text = 'Sliders reset';
        data.statusLabel.FontColor = [0.5 0.5 0.5];
    end
end