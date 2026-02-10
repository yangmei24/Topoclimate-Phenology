clear;
clc;

% ===========================
% Purpose:
%   Compute Sen's slope (Theil–Sen median slope) for LOS time series (2001–2023)
%   based on annual LOS GeoTIFFs. Output is a GeoTIFF of Sen slope per pixel.
% Notes:
%   - Input: los_YYYY.tif for each year, same size/projection
%   - Validity rule here: all values must be >= 0 (adjust if needed)
% ===========================

% ---- Read one raster to obtain spatial reference ----
[a, R] = geotiffread("D:\Z-data\test3\result\los\los_2001.tif");  % Reference GeoTIFF (projection/geo-info)
info = geotiffinfo("D:\Z-data\test3\result\los\los_2001.tif");
[m, n] = size(a);

% ---- Time span settings ----
start_year = 2001;
end_year   = 2023;
num_years  = end_year - start_year + 1;   % Number of years

% ---- Read LOS stack (pixel x time) ----
los_stack = nan(m*n, num_years);
k = 1;

for year = start_year:end_year
    in_file = ['D:\Z-data\test3\result\los\los_', int2str(year), '.tif'];
    img = importdata(in_file);
    los_stack(:, k) = reshape(img, m*n, 1);
    k = k + 1;
end

% ---- Compute Sen slope for each pixel ----
sen_slope = nan(m, n);

for i = 1:size(los_stack, 1)
    ts = los_stack(i, :);

    % Validity check:
    % Here we require all values >= 0 (modify to match your data mask rules)
    if min(ts) >= 0
        pair_slopes = [];

        % All pairwise slopes: (x_j - x_i) / (j - i)
        for k1 = 2:num_years
            for k2 = 1:(k1 - 1)
                diff_val = ts(k1) - ts(k2);
                diff_t   = k1 - k2;
                pair_slopes = [pair_slopes; diff_val ./ diff_t]; %#ok<AGROW>
            end
        end

        sen_slope(i) = median(pair_slopes);
    end
end

% ---- Write output ----
out_file = "D:\Z-data\test3\mk+sen\lossen.tif";
geotiffwrite(out_file, sen_slope, R, 'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);
