function CountThresholdedPuncta    

    fig = uifigure('Name', 'Puncta Counter (already thresholded)', 'WindowState', 'maximized');

    data = struct();
    data.imageFiles = {};
    data.currentIndex = 1;
    data.originalImage = [];
    data.resultsTable = table();
    data.imageSettings = struct();
    data.globalMinSize = 0; % Global min size for all images
    data.processedImages = struct(); % Store processed images
    
    createUIComponents();
    function createUIComponents()
        mainGrid = uigridlayout(fig, [1 1]);
       
        leftPanel = uipanel(mainGrid);
        leftPanel.Layout.Row = 1;
        leftPanel.Layout.Column = 1;
        leftGrid = uigridlayout(leftPanel, [2 1]);
        leftGrid.RowHeight = {'1x', 200};
        
        imageGrid = uigridlayout(leftGrid, [1 2]);
        imageGrid.Layout.Row = 1;
        imageGrid.ColumnWidth = {'1x', '1x'};
        imageGrid.Padding = [5 5 5 5];
        imageGrid.RowSpacing = 5;
        imageGrid.ColumnSpacing = 5;
        
        % OG image panel
        origPanel = uipanel(imageGrid, 'Title', 'Binary Input Image');
        origPanel.FontSize = 14;
        origPanel.FontWeight = 'bold';
        
        % count mask panel
        procPanel = uipanel(imageGrid, 'Title', 'Labeled Puncta');
        procPanel.FontSize = 14;
        procPanel.FontWeight = 'bold';

        % image axes
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
        yPos = 150;
        
        % minimum size filter (now global)
        uilabel(controlPanel, 'Position', [10 yPos 150 22], 'Text', 'Min size (px) [Global]:', 'FontSize', 11, 'FontWeight', 'bold');
        data.minSizeField = uieditfield(controlPanel, 'numeric', 'Position', [170 yPos 80 22], 'Value', 0, ...
            'ValueChangedFcn', @(src,~)updateGlobalMinSize(src));
        yPos = yPos - 50;
        
        % buttons
        btnWidth = 110;
        btnSpacing = 5;
        startX = 400; 
        btnY = yPos;
        btnX = startX;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'LOAD IMAGES', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)loadFolder());
        btnX = btnX + btnWidth + btnSpacing;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'PREVIOUS', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)previousImage());
        btnX = btnX + btnWidth + btnSpacing;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'NEXT', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)nextImage());
        btnX = btnX + btnWidth + btnSpacing;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'RESET', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)resetView(), 'BackgroundColor', [1 0.8 0.4]);
        yPos = yPos - 40;
        btnY2 = yPos;
        
        data.countButton = uibutton(controlPanel, 'Position', [startX btnY2 110 35], 'Text', 'COUNT', 'FontSize', 13, ...
            'ButtonPushedFcn', @(~,~)countPuncta(), 'BackgroundColor', [0.2 0.8 0.2], 'FontWeight', 'bold');
        
        data.countAllButton = uibutton(controlPanel, 'Position', [startX+115 btnY2 110 35], 'Text', 'COUNT ALL', 'FontSize', 13, ...
            'ButtonPushedFcn', @(~,~)countAllPuncta(), 'BackgroundColor', [0.2 0.6 0.8], 'FontWeight', 'bold');
        
        data.exportButton = uibutton(controlPanel, 'Position', [startX+230 btnY2 110 35], 'Text', 'EXPORT', 'FontSize', 13, ...
            'ButtonPushedFcn', @(~,~)exportResults(), 'BackgroundColor', [0.8 0.4 0.8], 'FontWeight', 'bold');
        
        data.statusLabel = uilabel(controlPanel, 'Position', [startX+350 btnY2 400 35], 'Text', '', 'FontSize', 12, 'FontWeight', 'bold');
    end

    function updateGlobalMinSize(src)
        data.globalMinSize = src.Value;
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
            if ismember(ext, {'.tif', '.tiff', '.png', '.jpg', '.jpeg', '.bmp'})
                data.imageFiles{end+1} = fullfile(folderPath, allFiles(i).name);
            end
        end
        
        if isempty(data.imageFiles)
            uialert(fig, 'No image files found', 'Error');
            return;
        end
        
        % create empty results table
        data.resultsTable = table('Size', [length(data.imageFiles), 5], ...
            'VariableTypes', {'string', 'double', 'double', 'double', 'cell'}, ...
            'VariableNames', {'Filename', 'PunctaCount', 'MeanSize', 'TotalArea', 'IndividualSizes'});
             
        % save zoom/pan settings per image
        data.imageSettings = struct(); 
        data.processedImages = struct();
        for i = 1:length(data.imageFiles)
            data.imageSettings(i).xlim = [];
            data.imageSettings(i).ylim = [];
            data.processedImages(i).rgb = [];
            data.processedImages(i).stats = [];
        end
        
        data.currentIndex = 1;
        loadCurrentImage();
        
        data.statusLabel.Text = sprintf('Loaded %d images', length(data.imageFiles));
        data.statusLabel.FontColor = [0 0 0.6];
    end

    function loadCurrentImage()
        if isempty(data.imageFiles)
            return;
        end
        
        % load image (assume it's already binary/thresholded)
        data.originalImage = imread(data.imageFiles{data.currentIndex});
        
        % convert to binary if not already
        if ~islogical(data.originalImage)
            data.originalImage = im2double(data.originalImage);
            data.originalImage = data.originalImage > 0.5; % simple threshold
        end
       
        % display original binary image
        cla(data.axesOriginal);
        imshow(data.originalImage, 'Parent', data.axesOriginal);
        axis(data.axesOriginal, 'image');
        
        idx = data.currentIndex;
        if ~isempty(data.imageSettings(idx).xlim)
            xlim(data.axesOriginal, data.imageSettings(idx).xlim);
            ylim(data.axesOriginal, data.imageSettings(idx).ylim);
        end
        
        % display processed image if it exists
        cla(data.axesProcessed);
        if ~isempty(data.processedImages(idx).rgb)
            imshow(data.processedImages(idx).rgb, 'Parent', data.axesProcessed);
            axis(data.axesProcessed, 'image');
            hold(data.axesProcessed, 'on');
            stats = data.processedImages(idx).stats;
            for i = 1:length(stats)
                text(data.axesProcessed, stats(i).Centroid(1), stats(i).Centroid(2), ...
                    sprintf('%d', i), 'Color', 'white', 'FontSize', 4, ...
                    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            end
            hold(data.axesProcessed, 'off');
            numPuncta = data.resultsTable.PunctaCount(idx);
            title(data.axesProcessed, sprintf('Counted Puncta (n=%d)', numPuncta), ...
                'FontSize', 14, 'FontWeight', 'bold');
                
            if ~isempty(data.imageSettings(idx).xlim)
                xlim(data.axesProcessed, data.imageSettings(idx).xlim);
                ylim(data.axesProcessed, data.imageSettings(idx).ylim);
            end
        end
 
        if ~isnan(data.resultsTable.PunctaCount(idx))
            meanSize = data.resultsTable.MeanSize(idx);
            data.statusLabel.Text = sprintf('Image %d/%d - Puncta: %d (Mean: %.1f px)', ...
                idx, length(data.imageFiles), data.resultsTable.PunctaCount(idx), meanSize);
            data.statusLabel.FontColor = [0 0.6 0];
        else
            data.statusLabel.Text = sprintf('Image %d/%d', idx, length(data.imageFiles));
            data.statusLabel.FontColor = [0 0 0];
        end
    end
    
    function saveCurrentSettings()
        idx = data.currentIndex;
        data.imageSettings(idx).xlim = xlim(data.axesProcessed);
        data.imageSettings(idx).ylim = ylim(data.axesProcessed);
    end

    function countPuncta()
        if isempty(data.originalImage)
            uialert(fig, 'no image loaded', 'Error');
            return;
        end
        
        processImage(data.currentIndex);
        loadCurrentImage(); % Refresh display
    end
    
    function countAllPuncta()
        if isempty(data.imageFiles)
            uialert(fig, 'No images loaded', 'Error');
            return;
        end
        
        % Show progress dialog
        d = uiprogressdlg(fig, 'Title', 'Processing Images', ...
            'Message', 'Counting puncta in all images...', ...
            'Indeterminate', 'off');
        
        % Process each image
        for i = 1:length(data.imageFiles)
            d.Value = (i-1) / length(data.imageFiles);
            d.Message = sprintf('Processing image %d of %d...', i, length(data.imageFiles));
            
            % Load and process image
            img = imread(data.imageFiles{i});
            if ~islogical(img)
                img = im2double(img);
                img = img > 0.5;
            end
            
            processImageData(i, img);
            
            if d.CancelRequested
                break;
            end
        end
        
        d.Value = 1;
        d.Message = 'Complete!';
        pause(0.5);
        close(d);
        
        % Reload current image to show results
        loadCurrentImage();
        
        totalPuncta = sum(data.resultsTable.PunctaCount, 'omitnan');
        data.statusLabel.Text = sprintf('Processed all images! Total puncta: %d', totalPuncta);
        data.statusLabel.FontColor = [0 0.6 0];
    end
    
    function processImage(idx)
        img = imread(data.imageFiles{idx});
        if ~islogical(img)
            img = im2double(img);
            img = img > 0.5;
        end
        processImageData(idx, img);
    end
    
    function processImageData(idx, img)
        currentXLim = xlim(data.axesOriginal);
        currentYLim = ylim(data.axesOriginal);
        
        bw = img;
        
        % clean up small objects if min size specified
        if data.globalMinSize > 0 
            bw = bwareaopen(bw, round(data.globalMinSize));
        end
        
        % label connected components
        labeled = bwlabel(bw); 
        stats = regionprops(labeled, 'Area', 'Centroid');
        
        % count puncta
        numPuncta = length(stats);
        
        if numPuncta == 0
            areas = [];
            meanArea = 0;
        else
            areas = [stats.Area];
            meanArea = mean(areas);
        end
        
        % store results
        [~, fname, ext] = fileparts(data.imageFiles{idx});
        data.resultsTable.Filename(idx) = string([fname ext]);
        data.resultsTable.PunctaCount(idx) = numPuncta;
        data.resultsTable.MeanSize(idx) = meanArea;
        data.resultsTable.TotalArea(idx) = sum(areas);
        data.resultsTable.IndividualSizes{idx} = areas;
            
        % colored visualization
        rgb = label2rgb(labeled, 'jet', 'k', 'shuffle');
        
        % Store processed image
        data.processedImages(idx).rgb = rgb;
        data.processedImages(idx).stats = stats;
    end

    function exportResults()
        if isempty(data.resultsTable) || height(data.resultsTable) == 0
            uialert(fig, 'No results to export', 'Error');
            return;
        end
        
        % Check if any images have been counted
        if all(isnan(data.resultsTable.PunctaCount))
            uialert(fig, 'No images have been counted yet', 'Error');
            return;
        end
        
        % Get save location
        [filename, pathname] = uiputfile('*.csv', 'Save Results As', 'puncta_counts.csv');
        if filename == 0
            return;
        end
        
        % Create export table (without IndividualSizes cell array)
        exportTable = data.resultsTable(:, 1:4);
        
        % Write to CSV
        fullpath = fullfile(pathname, filename);
        writetable(exportTable, fullpath);
        
        data.statusLabel.Text = sprintf('Results exported to: %s', filename);
        data.statusLabel.FontColor = [0 0.6 0];
        
        uialert(fig, sprintf('Results saved successfully to:\n%s', fullpath), 'Export Complete', 'Icon', 'success');
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
    
    function resetView()
        if isempty(data.originalImage)
            return;
        end
        
        % reset min size
        data.globalMinSize = 0;
        data.minSizeField.Value = 0;
        
        % reload image
        loadCurrentImage();
        
        data.statusLabel.Text = 'View reset';
        data.statusLabel.FontColor = [0.5 0.5 0.5];
    end
end