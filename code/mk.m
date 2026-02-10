clear;
clc;

% ===========================
% Purpose:
%   Mann–Kendall (MK) trend test (Z statistic) for annual LOS time series (2001–2023)
%   based on per-year LOS GeoTIFFs. Output is a GeoTIFF of MK Z per pixel.
% Notes:
%   - Input: los_YYYY.tif for each year, same size/projection
%   - Validity rule here: all values must be > -1 (adjust if needed)
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
p = 1;
for year = start_year:end_year
    in_file = ['D:\Z-data\test3\result\los\los_', int2str(year), '.tif'];
    img = importdata(in_file);
    los_stack(:, p) = reshape(img, m*n, 1);
    p = p + 1;
end

% ---- MK S statistic (per pixel) ----
S = nan(1, size(los_stack, 1));   % Store S for each pixel (vector form)

for i = 1:size(los_stack, 1)
    ts = los_stack(i, :);

    % Validity check:
    % Here we require all values > -1 (modify to match your data mask rules)
    if min(ts) > -1
        sgn_list = [];  % Store sign comparisons

        for k = 2:num_years
            for j = 1:(k - 1)
                diff_val = ts(k) - ts(j);

                if diff_val > 0
                    sgn = 1;
                elseif diff_val < 0
                    sgn = -1;
                else
                    sgn = 0;
                end

                sgn_list = [sgn_list, sgn]; %#ok<AGROW>
            end
        end

        S(i) = sum(sgn_list);
    end
end

% ---- Variance of S (no tie correction) ----
% NOTE: This variance formula assumes no ties (or ignores tie correction).
% If your LOS series contains many equal values, consider tie correction.
varS = num_years * (num_years - 1) * (2 * num_years + 5) / 18;

% ---- Compute MK Z statistic (per pixel) ----
Z = nan(m, n);

idx0 = find(S == 0);
Z(idx0) = 0;

idxP = find(S > 0);
Z(idxP) = (S(idxP) - 1) ./ sqrt(varS);

idxN = find(S < 0);
Z(idxN) = (S(idxN) + 1) ./ sqrt(varS);

% ---- Write output ----
out_file = 'D:\Z-data\test3\mk+sen\losmk.tif';
geotiffwrite(out_file, Z, R, 'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);
