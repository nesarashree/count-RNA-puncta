function Colocalization    

    fig = uifigure('Name', 'Puncta-Cell Colocalization Counter', 'WindowState', 'maximized');

    data = struct();
    data.punctaFiles = {};
    data.cellFiles = {};
    data.currentIndex = 1;
    data.punctaImage = [];
    data.cellImage = [];
    data.resultsTable = table();
    data.imageSettings = struct();
    data.globalMinSize = 0;
    data.globalMaxSize = inf;
    data.processedImages = struct();
    data.hasOverlay = false;
    
    % set pixel size (microns per pixel)
    data.pixelSize = 1.0; 
    
    createUIComponents();
    
    function createUIComponents()
        mainGrid = uigridlayout(fig, [1 1]);
       
        leftPanel = uipanel(mainGrid);
        leftPanel.Layout.Row = 1;
        leftPanel.Layout.Column = 1;
        leftGrid = uigridlayout(leftPanel, [2 1]);
        leftGrid.RowHeight = {'1x', 250};
        
        imageGrid = uigridlayout(leftGrid, [1 2]);
        imageGrid.Layout.Row = 1;
        imageGrid.ColumnWidth = {'1x', '1x'};
        imageGrid.Padding = [5 5 5 5];
        imageGrid.RowSpacing = 5;
        imageGrid.ColumnSpacing = 5;
        
        % Overlay panel
        overlayPanel = uipanel(imageGrid, 'Title', 'Overlay (Puncta=Magenta, Cells=Green)');
        overlayPanel.FontSize = 14;
        overlayPanel.FontWeight = 'bold';
        
        % Counted puncta panel
        procPanel = uipanel(imageGrid, 'Title', 'Labeled Puncta');
        procPanel.FontSize = 14;
        procPanel.FontWeight = 'bold';

        % Image axes
        data.axesOverlay = axes(overlayPanel, 'Units', 'normalized', 'Position', [0 0 1 1]);
        axis(data.axesOverlay, 'off');
        data.axesProcessed = axes(procPanel, 'Units', 'normalized', 'Position', [0 0 1 1]);
        axis(data.axesProcessed, 'off');
        
        % Link zoom/pan between both axes
        linkaxes([data.axesOverlay, data.axesProcessed]);
        zoom(data.axesOverlay, 'on');
        pan(data.axesOverlay, 'on');
        zoom(data.axesProcessed, 'on');
        pan(data.axesProcessed, 'on');
        
        % Control panel
        controlPanel = uipanel(leftGrid, 'Title', 'Controls');
        controlPanel.Layout.Row = 2;
        yPos = 200;
        
        % Min size filter
        uilabel(controlPanel, 'Position', [10 yPos 150 22], 'Text', 'Min size (px) [Global]:', 'FontSize', 11, 'FontWeight', 'bold');
        data.minSizeField = uieditfield(controlPanel, 'numeric', 'Position', [170 yPos 80 22], 'Value', 0, ...
            'ValueChangedFcn', @(src,~)updateGlobalMinSize(src));
        yPos = yPos - 35;
        
        % Max size filter
        uilabel(controlPanel, 'Position', [10 yPos 150 22], 'Text', 'Max size (px) [Global]:', 'FontSize', 11, 'FontWeight', 'bold');
        data.maxSizeField = uieditfield(controlPanel, 'numeric', 'Position', [170 yPos 80 22], 'Value', inf, ...
            'ValueChangedFcn', @(src,~)updateGlobalMaxSize(src));
        yPos = yPos - 35;
        
        % File info labels
        data.punctaFileLabel = uilabel(controlPanel, 'Position', [10 yPos 700 20], ...
            'Text', 'Puncta folder: Not loaded', 'FontSize', 10);
        yPos = yPos - 25;
        data.cellFileLabel = uilabel(controlPanel, 'Position', [10 yPos 700 20], ...
            'Text', 'Cell folder: Not loaded', 'FontSize', 10);
        yPos = yPos - 40;
        
        % Load buttons
        btnWidth = 140;
        btnSpacing = 5;
        startX = 10;
        btnY = yPos;
        btnX = startX;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'LOAD PUNCTA', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)loadPunctaFolder(), 'BackgroundColor', [1 0.7 0.9], 'FontWeight', 'bold');
        btnX = btnX + btnWidth + btnSpacing;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'LOAD CELLS', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)loadCellFolder(), 'BackgroundColor', [0.7 1 0.7], 'FontWeight', 'bold');
        btnX = btnX + btnWidth + btnSpacing;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'PREVIOUS', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)previousImage());
        btnX = btnX + btnWidth + btnSpacing;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'NEXT', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)nextImage());
        btnX = btnX + btnWidth + btnSpacing;
        
        uibutton(controlPanel, 'Position', [btnX btnY btnWidth 30], 'Text', 'RESET', 'FontSize', 11, ...
            'ButtonPushedFcn', @(~,~)resetView(), 'BackgroundColor', [1 0.8 0.4], 'FontWeight', 'bold');
        
        yPos = yPos - 45;
        btnY2 = yPos;
        btnX2 = startX;
        
        % Analysis buttons
        data.countButton = uibutton(controlPanel, 'Position', [btnX2 btnY2 140 35], 'Text', 'COUNT ALL PUNCTA', 'FontSize', 12, ...
            'ButtonPushedFcn', @(~,~)countPuncta(), 'BackgroundColor', [0.2 0.8 0.2], 'FontWeight', 'bold');
        btnX2 = btnX2 + 145;
        
        data.countAllButton = uibutton(controlPanel, 'Position', [btnX2 btnY2 140 35], 'Text', 'BATCH COUNT', 'FontSize', 12, ...
            'ButtonPushedFcn', @(~,~)countAllPuncta(), 'BackgroundColor', [0.2 0.6 0.8], 'FontWeight', 'bold');
        btnX2 = btnX2 + 145;
        
        data.colocButton = uibutton(controlPanel, 'Position', [btnX2 btnY2 140 35], 'Text', 'COLOCALIZATION', 'FontSize', 12, ...
            'ButtonPushedFcn', @(~,~)countColocalization(), 'BackgroundColor', [1 0.6 0.2], 'FontWeight', 'bold', ...
            'Enable', 'off');
        btnX2 = btnX2 + 145;
        
        data.batchColocButton = uibutton(controlPanel, 'Position', [btnX2 btnY2 140 35], 'Text', 'BATCH COLOC', 'FontSize', 12, ...
            'ButtonPushedFcn', @(~,~)batchColocalization(), 'BackgroundColor', [0.9 0.5 0.1], 'FontWeight', 'bold', ...
            'Enable', 'off');
        btnX2 = btnX2 + 145;
        
        data.exportButton = uibutton(controlPanel, 'Position', [btnX2 btnY2 140 35], 'Text', 'EXPORT', 'FontSize', 12, ...
            'ButtonPushedFcn', @(~,~)exportResults(), 'BackgroundColor', [0.8 0.4 0.8], 'FontWeight', 'bold');
        
        yPos = yPos - 40;
        data.statusLabel = uilabel(controlPanel, 'Position', [10 yPos 900 30], 'Text', '', 'FontSize', 11, 'FontWeight', 'bold');
    end

    function updateGlobalMinSize(src)
        data.globalMinSize = src.Value;
    end

    function updateGlobalMaxSize(src)
        data.globalMaxSize = src.Value;
    end

    function loadPunctaFolder()
        folderPath = uigetdir('', 'Select PUNCTA image folder');
        if folderPath == 0
            return;
        end
        
        data.punctaFiles = getImageFiles(folderPath);
        
        if isempty(data.punctaFiles)
            uialert(fig, 'No image files found', 'Error');
            return;
        end
        
        % Initialize results table
        numFiles = length(data.punctaFiles);
        if data.hasOverlay
            data.resultsTable = table('Size', [numFiles, 13], ...
                'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'cell'}, ...
                'VariableNames', {'Filename', 'TotalPuncta', 'MeanSize', 'TotalArea', ...
                                  'NumCells', 'ColocPuncta', 'NonColocPuncta', 'PunctaPerCell', ...
                                  'Density', 'CellsWithPuncta', 'PercentCellsWithPuncta', 'PercentPunctaColocalized', 'IndividualSizes'});
        else
            data.resultsTable = table('Size', [numFiles, 6], ...
                'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'cell'}, ...
                'VariableNames', {'Filename', 'TotalPuncta', 'MeanSize', 'TotalArea', 'Density', 'IndividualSizes'});
        end
        
        data.imageSettings = struct();
        data.processedImages = struct();
        for i = 1:numFiles
            data.imageSettings(i).xlim = [];
            data.imageSettings(i).ylim = [];
            data.processedImages(i).rgb = [];
            data.processedImages(i).colocRgb = [];
            data.processedImages(i).stats = [];
        end
        
        data.currentIndex = 1;
        loadCurrentImage();
        
        data.punctaFileLabel.Text = sprintf('Puncta folder: %s (%d images)', folderPath, numFiles);
        data.statusLabel.Text = sprintf('Loaded %d puncta images', numFiles);
        data.statusLabel.FontColor = [0 0 0.6];
    end

    function loadCellFolder()
        folderPath = uigetdir('', 'Select CELL MASK folder');
        if folderPath == 0
            return;
        end
        
        data.cellFiles = getImageFiles(folderPath);
        
        if isempty(data.cellFiles)
            uialert(fig, 'No image files found', 'Error');
            return;
        end
        
        if ~isempty(data.punctaFiles) && length(data.cellFiles) ~= length(data.punctaFiles)
            answer = uiconfirm(fig, sprintf('Warning: %d cell masks vs %d puncta images. Continue?', ...
                length(data.cellFiles), length(data.punctaFiles)), 'Mismatch Warning');
            if ~strcmp(answer, 'OK')
                return;
            end
        end
        
        data.hasOverlay = true;
        
        % Update results table to include colocalization columns
        if ~isempty(data.resultsTable) && height(data.resultsTable) > 0
            numFiles = height(data.resultsTable);
            newTable = table('Size', [numFiles, 13], ...
                'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'cell'}, ...
                'VariableNames', {'Filename', 'TotalPuncta', 'MeanSize', 'TotalArea', ...
                                  'NumCells', 'ColocPuncta', 'NonColocPuncta', 'PunctaPerCell', ...
                                  'Density', 'CellsWithPuncta', 'PercentCellsWithPuncta', 'PercentPunctaColocalized', 'IndividualSizes'});
            
            % Copy existing data
            if ismember('Filename', data.resultsTable.Properties.VariableNames)
                newTable.Filename = data.resultsTable.Filename;
                newTable.TotalPuncta = data.resultsTable.TotalPuncta;
                newTable.MeanSize = data.resultsTable.MeanSize;
                newTable.TotalArea = data.resultsTable.TotalArea;
                newTable.Density = data.resultsTable.Density;
                newTable.IndividualSizes = data.resultsTable.IndividualSizes;
            end
            data.resultsTable = newTable;
        end
        
        % Enable colocalization buttons
        data.colocButton.Enable = 'on';
        data.batchColocButton.Enable = 'on';
        
        loadCurrentImage();
        
        data.cellFileLabel.Text = sprintf('Cell folder: %s (%d images)', folderPath, length(data.cellFiles));
        data.statusLabel.Text = sprintf('Loaded %d cell masks - Colocalization enabled!', length(data.cellFiles));
        data.statusLabel.FontColor = [0 0.6 0];
    end

    function files = getImageFiles(folderPath)
        files = {};
        allFiles = dir(folderPath);
        
        for i = 1:length(allFiles)
            if allFiles(i).isdir
                continue;
            end
            [~, ~, ext] = fileparts(allFiles(i).name);
            ext = lower(ext);
            if ismember(ext, {'.tif', '.tiff', '.png', '.jpg', '.jpeg', '.bmp'})
                files{end+1} = fullfile(folderPath, allFiles(i).name);
            end
        end
    end

    function loadCurrentImage()
        if isempty(data.punctaFiles)
            return;
        end
        
        idx = data.currentIndex;
        
        % Load puncta image
        data.punctaImage = imread(data.punctaFiles{idx});
        if ~islogical(data.punctaImage)
            data.punctaImage = im2double(data.punctaImage);
            data.punctaImage = data.punctaImage > 0.5;
        end
        
        % Load cell image if available
        if data.hasOverlay && idx <= length(data.cellFiles)
            data.cellImage = imread(data.cellFiles{idx});
            if ~islogical(data.cellImage)
                data.cellImage = im2double(data.cellImage);
                data.cellImage = data.cellImage > 0.5;
            end
        else
            data.cellImage = [];
        end
        
        % Create overlay visualization
        displayOverlay();
        
        % Display processed image if it exists
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
            
            if data.hasOverlay && ~isnan(data.resultsTable.ColocPuncta(idx))
                title(data.axesProcessed, sprintf('Total: %d | Coloc: %d | Non-coloc: %d', ...
                    data.resultsTable.TotalPuncta(idx), data.resultsTable.ColocPuncta(idx), ...
                    data.resultsTable.NonColocPuncta(idx)), 'FontSize', 12, 'FontWeight', 'bold');
            else
                title(data.axesProcessed, sprintf('Counted Puncta (n=%d)', data.resultsTable.TotalPuncta(idx)), ...
                    'FontSize', 12, 'FontWeight', 'bold');
            end
            
            if ~isempty(data.imageSettings(idx).xlim)
                xlim(data.axesProcessed, data.imageSettings(idx).xlim);
                ylim(data.axesProcessed, data.imageSettings(idx).ylim);
            end
        end
        
        % Update status
        updateStatus();
    end
    
    function displayOverlay()
        idx = data.currentIndex;
        cla(data.axesOverlay);
        
        % Create RGB overlay: Puncta=Magenta, Cells=Green
        [h, w] = size(data.punctaImage);
        rgb = zeros(h, w, 3);
        
        % Magenta channel for puncta (R + B)
        rgb(:,:,1) = double(data.punctaImage); % Red
        rgb(:,:,3) = double(data.punctaImage); % Blue
        
        % Green channel for cells
        if ~isempty(data.cellImage)
            rgb(:,:,2) = double(data.cellImage); % Green
        end
        
        imshow(rgb, 'Parent', data.axesOverlay);
        axis(data.axesOverlay, 'image');
        
        if ~isempty(data.imageSettings(idx).xlim)
            xlim(data.axesOverlay, data.imageSettings(idx).xlim);
            ylim(data.axesOverlay, data.imageSettings(idx).ylim);
        end
    end
    
    function updateStatus()
        idx = data.currentIndex;
        if data.hasOverlay && ~isnan(data.resultsTable.ColocPuncta(idx))
            ppc = data.resultsTable.PunctaPerCell(idx);
            data.statusLabel.Text = sprintf('Image %d/%d | Cells: %d | Total: %d | Coloc: %d (%.1f%%) | Per Cell: %.2f', ...
                idx, length(data.punctaFiles), data.resultsTable.NumCells(idx), ...
                data.resultsTable.TotalPuncta(idx), data.resultsTable.ColocPuncta(idx), ...
                100*data.resultsTable.ColocPuncta(idx)/max(1,data.resultsTable.TotalPuncta(idx)), ppc);
            data.statusLabel.FontColor = [0 0.6 0];
        elseif ~isnan(data.resultsTable.TotalPuncta(idx))
            data.statusLabel.Text = sprintf('Image %d/%d - Puncta: %d (Mean: %.1f px)', ...
                idx, length(data.punctaFiles), data.resultsTable.TotalPuncta(idx), ...
                data.resultsTable.MeanSize(idx));
            data.statusLabel.FontColor = [0 0.6 0];
        else
            data.statusLabel.Text = sprintf('Image %d/%d', idx, length(data.punctaFiles));
            data.statusLabel.FontColor = [0 0 0];
        end
    end

    function saveCurrentSettings()
        idx = data.currentIndex;
        data.imageSettings(idx).xlim = xlim(data.axesOverlay);
        data.imageSettings(idx).ylim = ylim(data.axesOverlay);
    end

    function countPuncta()
        if isempty(data.punctaImage)
            uialert(fig, 'No image loaded', 'Error');
            return;
        end
        
        processImage(data.currentIndex, false);
        loadCurrentImage();
    end
    
    function countColocalization()
        if isempty(data.punctaImage) || isempty(data.cellImage)
            uialert(fig, 'Need both puncta and cell images loaded', 'Error');
            return;
        end
        
        processImage(data.currentIndex, true);
        loadCurrentImage();
    end
    
    function countAllPuncta()
        if isempty(data.punctaFiles)
            uialert(fig, 'No images loaded', 'Error');
            return;
        end
        
        d = uiprogressdlg(fig, 'Title', 'Processing Images', ...
            'Message', 'Counting puncta...', 'Indeterminate', 'off');
        
        for i = 1:length(data.punctaFiles)
            d.Value = (i-1) / length(data.punctaFiles);
            d.Message = sprintf('Processing image %d of %d...', i, length(data.punctaFiles));
            
            processImage(i, false);
            
            if d.CancelRequested
                break;
            end
        end
        
        close(d);
        loadCurrentImage();
        
        totalPuncta = sum(data.resultsTable.TotalPuncta, 'omitnan');
        data.statusLabel.Text = sprintf('Batch complete! Total puncta: %d', totalPuncta);
        data.statusLabel.FontColor = [0 0.6 0];
    end
    
    function batchColocalization()
        if isempty(data.punctaFiles) || isempty(data.cellFiles)
            uialert(fig, 'Need both puncta and cell folders loaded', 'Error');
            return;
        end
        
        d = uiprogressdlg(fig, 'Title', 'Colocalization Analysis', ...
            'Message', 'Analyzing colocalization...', 'Indeterminate', 'off');
        
        numToProcess = min(length(data.punctaFiles), length(data.cellFiles));
        
        for i = 1:numToProcess
            d.Value = (i-1) / numToProcess;
            d.Message = sprintf('Processing image %d of %d...', i, numToProcess);
            
            processImage(i, true);
            
            if d.CancelRequested
                break;
            end
        end
        
        close(d);
        loadCurrentImage();
        
        totalColoc = sum(data.resultsTable.ColocPuncta, 'omitnan');
        totalPuncta = sum(data.resultsTable.TotalPuncta, 'omitnan');
        data.statusLabel.Text = sprintf('Batch coloc complete! %d/%d puncta colocalized (%.1f%%)', ...
            totalColoc, totalPuncta, 100*totalColoc/max(1,totalPuncta));
        data.statusLabel.FontColor = [0 0.6 0];
    end
    
    function processImage(idx, doColoc)
        % Load images
        punctaImg = imread(data.punctaFiles{idx});
        if ~islogical(punctaImg)
            punctaImg = im2double(punctaImg);
            punctaImg = punctaImg > 0.5;
        end
        
        if doColoc && idx <= length(data.cellFiles)
            cellImg = imread(data.cellFiles{idx});
            if ~islogical(cellImg)
                cellImg = im2double(cellImg);
                cellImg = cellImg > 0.5;
            end
        else
            cellImg = [];
        end
        
        % Clean up small puncta
        bw = punctaImg;
        if data.globalMinSize > 0
            bw = bwareaopen(bw, round(data.globalMinSize));
        end
        
        % Remove large puncta
        if ~isinf(data.globalMaxSize)
            labeled_temp = bwlabel(bw);
            stats_temp = regionprops(labeled_temp, 'Area');
            for i = 1:length(stats_temp)
                if stats_temp(i).Area > data.globalMaxSize
                    bw(labeled_temp == i) = false;
                end
            end
        end
        
        % Label puncta
        labeled = bwlabel(bw);
        stats = regionprops(labeled, 'Area', 'Centroid', 'PixelIdxList');
        numPuncta = length(stats);
        
        if numPuncta == 0
            areas = [];
            meanArea = 0;
        else
            areas = [stats.Area];
            meanArea = mean(areas);
        end
        
        % Calculate image area in microns^2
        [h, w] = size(punctaImg);
        imageAreaMicrons = h * w * data.pixelSize^2;
        
        % Calculate density (puncta per micron^2)
        density = numPuncta / imageAreaMicrons;
        
        % Store basic results
        [~, fname, ext] = fileparts(data.punctaFiles{idx});
        data.resultsTable.Filename(idx) = string([fname ext]);
        data.resultsTable.TotalPuncta(idx) = numPuncta;
        data.resultsTable.MeanSize(idx) = meanArea;
        data.resultsTable.TotalArea(idx) = sum(areas);
        data.resultsTable.Density(idx) = density;
        data.resultsTable.IndividualSizes{idx} = areas;
        
        % Colocalization analysis
        if doColoc && ~isempty(cellImg)
            % Label cells
            cellLabeled = bwlabel(cellImg);
            numCells = max(cellLabeled(:));
            
            % Find which puncta overlap with cells and which cells have puncta
            colocIndices = false(numPuncta, 1);
            cellsWithPuncta = false(numCells, 1);
            
            for i = 1:numPuncta
                % Check if centroid is inside a cell
                centroid = stats(i).Centroid;
                x = round(centroid(1));
                y = round(centroid(2));
                
                % Bounds checking
                if y >= 1 && y <= size(cellImg, 1) && x >= 1 && x <= size(cellImg, 2)
                    cellLabel = cellLabeled(y, x);
                    if cellLabel > 0
                        colocIndices(i) = true;
                        cellsWithPuncta(cellLabel) = true;
                    end
                end
            end
            
            % Count colocalized vs non-colocalized
            numColoc = sum(colocIndices);
            numNonColoc = numPuncta - numColoc;
            numCellsWithPuncta = sum(cellsWithPuncta);
            
            % Calculate percentages
            percentCellsWithPuncta = 100 * numCellsWithPuncta / max(1, numCells);
            percentPunctaColocalized = 100 * numColoc / max(1, numPuncta);
            meanPunctaPerCell = numColoc / max(1, numCells);
            
            % Create colocalization mask for visualization
            colocMask = false(size(bw));
            for i = 1:numPuncta
                if colocIndices(i)
                    colocMask(stats(i).PixelIdxList) = true;
                end
            end
            
            % Store colocalization results
            data.resultsTable.NumCells(idx) = numCells;
            data.resultsTable.ColocPuncta(idx) = numColoc;
            data.resultsTable.NonColocPuncta(idx) = numNonColoc;
            data.resultsTable.PunctaPerCell(idx) = meanPunctaPerCell;
            data.resultsTable.CellsWithPuncta(idx) = numCellsWithPuncta;
            data.resultsTable.PercentCellsWithPuncta(idx) = percentCellsWithPuncta;
            data.resultsTable.PercentPunctaColocalized(idx) = percentPunctaColocalized;
            
            % Create visualization with colocalized puncta highlighted
            rgb = createColocVisualization(labeled, colocMask, cellImg);
            data.processedImages(idx).colocRgb = rgb;
            data.processedImages(idx).rgb = rgb;
        else
            % Regular visualization
            rgb = label2rgb(labeled, 'jet', 'k', 'shuffle');
            data.processedImages(idx).rgb = rgb;
        end
        
        data.processedImages(idx).stats = stats;
    end
    
    function rgb = createColocVisualization(labeled, colocMask, cellImg)
        % Create visualization: colocalized=yellow, non-coloc=cyan, cells=green outline
        [h, w] = size(labeled);
        rgb = zeros(h, w, 3);
        
        % Separate colocalized and non-colocalized puncta
        colocPuncta = double(labeled) .* double(colocMask);
        nonColocPuncta = double(labeled) .* double(~colocMask & labeled > 0);
        
        % Colocalized puncta = Yellow (R+G)
        rgb(:,:,1) = rgb(:,:,1) + double(colocPuncta > 0);
        rgb(:,:,2) = rgb(:,:,2) + double(colocPuncta > 0);
        
        % Non-colocalized puncta = Cyan (G+B)
        rgb(:,:,2) = rgb(:,:,2) + double(nonColocPuncta > 0);
        rgb(:,:,3) = rgb(:,:,3) + double(nonColocPuncta > 0);
        
        % Cell boundaries in green
        cellBoundary = bwperim(cellImg);
        rgb(:,:,2) = rgb(:,:,2) + 0.5*double(cellBoundary);
        
        % Normalize
        rgb = min(rgb, 1);
    end

    function exportResults()
        if isempty(data.resultsTable) || height(data.resultsTable) == 0
            uialert(fig, 'No results to export', 'Error');
            return;
        end
        
        if all(isnan(data.resultsTable.TotalPuncta))
            uialert(fig, 'No images have been counted yet', 'Error');
            return;
        end
        
        [filename, pathname] = uiputfile('*.csv', 'Save Results As', 'puncta_colocalization.csv');
        if filename == 0
            return;
        end
        
        % Export table with all relevant columns
        if data.hasOverlay
            exportTable = data.resultsTable(:, {'Filename', 'TotalPuncta', 'MeanSize', 'TotalArea', ...
                'Density', 'NumCells', 'ColocPuncta', 'NonColocPuncta', 'PunctaPerCell', ...
                'CellsWithPuncta', 'PercentCellsWithPuncta', 'PercentPunctaColocalized'});
        else
            exportTable = data.resultsTable(:, {'Filename', 'TotalPuncta', 'MeanSize', 'TotalArea', 'Density'});
        end
        
        fullpath = fullfile(pathname, filename);
        writetable(exportTable, fullpath);
        
        data.statusLabel.Text = sprintf('Results exported to: %s', filename);
        data.statusLabel.FontColor = [0 0.6 0];
        
        uialert(fig, sprintf('Results saved to:\n%s', fullpath), 'Export Complete', 'Icon', 'success');
    end

    function previousImage()
        if isempty(data.punctaFiles) || data.currentIndex <= 1
            return;
        end
        saveCurrentSettings();
        data.currentIndex = data.currentIndex - 1;
        loadCurrentImage();
    end

    function nextImage()
        if isempty(data.punctaFiles) || data.currentIndex >= length(data.punctaFiles)
            return;
        end
        saveCurrentSettings();
        data.currentIndex = data.currentIndex + 1;
        loadCurrentImage();
    end
    
    function resetView()
        if isempty(data.punctaImage)
            return;
        end
        
        data.globalMinSize = 0;
        data.globalMaxSize = inf;
        data.minSizeField.Value = 0;
        data.maxSizeField.Value = inf;
        loadCurrentImage();
        
        data.statusLabel.Text = 'View reset';
        data.statusLabel.FontColor = [0.5 0.5 0.5];
    end
end
