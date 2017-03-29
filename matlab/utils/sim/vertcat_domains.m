function [X] = vertcat_domains(exclude_last, varargin)
% Vertically concatenate vectors resulting from a multi-domain ODE integration.
% Eliminate non-unique points by excluding points in between each data set
% (for steps 1 .. N-1, remove last point, so it's right continuous*)
% useful for interpolation. Since it's varargin, call via argument expansion:
% >> horzcat_domains(data.steps.ts)
% >> horzcat(dataCell{:})
% Example:
% >> horzcat_domains([1, 2, 3; 10, 20, 30], [3, 4, 5, 6; 30, 40, 50 60])
%      1     2     3     4     5     6
%     10    20    30    40    50    60
% For now, this will reject any empty matrices, since that doesn't make
% sense since an initial condition is always present.
% Can test resulting thing with (there should be no indices)
% >> [row, col] = find(diff(results, 1, 2) == 0); [row, col]
% * Right continuity, see [Grizzle p85]

% ALTERNATIVE: When saving the solution set, don't save the last point...
% But that might lose the last point of the last step unless it's
% explicitly kept, and might prove a problem if integration dies halfway
% through

% PROBLEM: This does not handle dissimilar domains...

if nargin < 1 || isempty(exclude_last)
    exclude_last = true;
end

nin = length(varargin);
if nin == 0
	X = [];
	return;
end

cols = [];
argCols = zeros(nin, 1);
argRows = zeros(nin, 1);
for i = 1:nin
	argSize = size(varargin{i});
	argRows(i) = argSize(1);
	argCols(i) = argSize(2);
	assert(argCols(i) > 0, 'Each argument must have at least one entry (initial condition)');
	if ~isempty(varargin{i})
		if isempty(cols)
			cols = argCols(i);
		else
			assert(argCols(i) == cols, 'Horzcat dimensions must be consistent, ya foo.');
		end
	end
end
if exclude_last
    rows = sum(argRows) - nin + 1;
else
    rows = sum(argRows);
end

if isempty(cols)
	% Not sure if this would really make sense, but oh well
	X = zeros(rows, 0);
	return;
end

tpl = varargin{1};
if isstruct(tpl)
    X = repmat(tpl(1), cols, rows);
elseif iscell(tpl)
    X = cell(rows, cols);
else
    X = zeros(rows, cols);
end

%X(:, 1:argCols(1)) = varargin{1};
index = 0;
for i = 1:nin
	% Exclude first points (initial conditions) on subsequent pieces
    count = argRows(i);
    if exclude_last && i < nin
        count = count - 1;
    end
	X(index + (1:count), :) = varargin{i}(1:count, :);
	index = index + count;
end

end
