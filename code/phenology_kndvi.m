clear
clc

% ===========================
% Purpose:
%   Extract SOS/EOS from 16-day kNDVI GeoTIFF time series (one year)
%   using SG smoothing + dynamic threshold method.
% Notes:
%   - Input: all *.tif in one folder (same size/projection)
%   - Output: SOS/EOS GeoTIFF (Julian day)
% ===========================

% ---- Read one sample GeoTIFF to get spatial reference ----
file = 'D:\Z-data\test3\kndvi_clip\2023\2023001.tif';   % Path to any GeoTIFF in the folder
[aa, R] = geotiffread(file);
info = geotiffinfo(file);
[m, n] = size(aa);

% ---- Settings ----
count = 23;                 % Number of images in the year (e.g., 23 for 16-day composites)
xq = 1:5:365;               % Daily grid for fitting (step=5 days)
scale_factor = 0.0001;      % kNDVI scale factor (adjust if needed)
sg_order = 3;               % Savitzky-Golay polynomial order
sg_frame = 9;               % Savitzky-Golay frame length (must be odd)
thresh_ratio = 0.2;         % Dynamic threshold ratio (0.2 -> 20% amplitude)

% ---- Input folder (ONLY target *.tif files, no extra tif) ----
fileFolder = fullfile('D:\Z-data\test3\kndvi_clip\2023\');
dirOutput = dir(fullfile(fileFolder, '*.tif'));
fileNames = {dirOutput.name}';

% ---- Pre-allocate ----
doy = zeros(1, count);              % Day-of-year for each image
data = zeros(m*n, count);           % Pixel-wise time series

% ---- Load all images and parse DOY from filename ----
k = 1;
for i = 1:count
    % Read raster
    bz = importdata(fullfile(fileFolder, fileNames{i}));
    data(:, k) = reshape(bz, m*n, 1);
    k = k + 1;

    % Parse DOY from filename: e.g., "2023001.tif" -> 001
    doy(1, i) = str2double(fileNames{i}(5:7));
end

% ---- Mask invalid values ----
data(data < 0) = NaN;

% ---- Output matrices ----
sos = nan(m, n);
eos = nan(m, n);

warning('off', 'all');

% ===========================
% Main loop: per pixel
% ===========================
for i = 1:length(data)
    ts = data(i, :);

    % Require at least a few valid observations
    if numel(ts(ts > 0)) > 3
        % Optional progress print (comment out if too slow)
        % disp(i)

        ts = ts(:) * scale_factor;      % Convert to real value
        x = doy(~isnan(ts))';           % Valid DOY
        v = ts(~isnan(ts));             % Valid values

        % Interpolate to original composite DOYs (fills gaps at those DOYs)
        v1 = interp1(x, v, doy, 'linear', 'extrap');

        % SG smoothing on composite series
        vq = sgolayfilt(v1, sg_order, sg_frame);

        % Interpolate to 5-day grid for threshold searching
        sgf = interp1(doy, vq, xq, 'linear', 'extrap');

        if numel(sgf(sgf > 0)) > 3
            % Peak and pre-peak minimum (SOS)
            [pks, loc1] = max(sgf);
            [min1, loc2] = min(sgf(1:loc1));
            thresh1 = (pks - min1) * thresh_ratio + min1;

            seg1 = sgf(loc2:loc1);
            seg1_over = seg1(seg1 >= thresh1);
            sos0 = xq(sgf == seg1_over(1));

            % Post-peak minimum (EOS)
            [min2, loc3] = min(sgf(loc1:end));
            loc3 = loc3 + loc1 - 1;
            thresh2 = (pks - min2) * thresh_ratio + min2;

            seg2 = sgf(loc1:loc3);
            seg2_over = seg2(seg2 >= thresh2);
            eos0 = xq(sgf == seg2_over(end));

            sos(i) = sos0(1);
            eos(i) = eos0(end);

            clearvars sgf vq v1 ts pks loc1 min1 loc2 thresh1 seg1 seg1_over sos0 ...
                     min2 loc3 thresh2 seg2 seg2_over eos0 x v
        end
    end
end

% ---- Write outputs ----
out_sos = 'D:\Z-data\test3\result\sos\sos_2023.tif';   % Update output path if needed
geotiffwrite(out_sos, sos, R, 'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag)

out_eos = 'D:\Z-data\test3\result\eos\eos_2023.tif';   % Update output path if needed
geotiffwrite(out_eos, eos, R, 'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag)
