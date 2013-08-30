% This file is part of the project CLASS (https://github.com/beckel/class).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich & TU Darmstadt, 2012
% Authors: Christian Beckel (beckel@inf.ethz.ch), Leyna Sadamori (sadamori@inf.ethz.ch)

function data_selection_cv(Config, class_func, feat_func)

fprintf('\nCollect household properties: %s\n\n', class_func('name'));

path = [ Config.path_classification, num2str(Config.week), '/CrossValid', num2str(Config.cross_validation), '/', Config.feature_set, '/'];
traces_per_household = Config.weeks;
num_traces_per_household = length(traces_per_household);

% ISSM: load consumption
load('consumption_questionnaires');
read_questionnaires;

%% Settings

% Information for filename
sInfo.classes = class_func('name');
sInfo.features = Config.feature_set;

% Feature Set 
feat_set = feat_func();

% Classes
sClass = class_func();
classes = sClass.classes;
constraints = sClass.constr;
C = length(classes);

%% REFACTOR: get data

% Ireland part to get household ids based on properties
% connection = cer_db_get_connection();
% select = 'ID';
% from = 'UserProfile';
% orderby = 'ID';
% ids = cell(1,C);
% for c = 1:C
% 	where = { ...
% 		'Type = 1', ...			% Only Residents
% 		constraints{c}, ...
% 		};
% 	query = query_builder(select, from, where, orderby);
% 	fprintf('%s\n', query);
% 	curs = fetch(exec(connection, query));
% 	ids{c} = cell2mat(curs.data);
% end
% 
% close(connection);

% ISSM part to get household ids based on properties
ids = cell(1,C);
for c = 1:C
    read_questionnaires;
    names = sClass.constraint_names;
    constraint = constraints{c};
    % this will be needed as soon as two properties are supported - not
    % yet, though.
    for i = 1:length(names)
        single_constraint = constraint{i};
        column_name = names{i};
        column_number = find(ismember(questionnaire_columns,column_name));
        expression = [ 'idx = questionnaire_data(:,column_number) ', single_constraint];
        % filter entries with '-1'
        expression = [ expression, ' & questionnaire_data(:,column_number) > -1;'];
        eval(expression);
        ids{c} = questionnaire_data(idx);
    end
end

%% Generate Samples

samples = cell(1,C);
households = cell(1,C);
truth = cell(1,C);

for c = 1:C
    num_households = length(ids{c});
    N = length(ids{c}) * num_traces_per_household;
    
	samples{c} = zeros(compose_featureset('dim', feat_set), N);
    households{c} = zeros(1, N);
	truth{c} = ones(1,N) * c;

	avg_time = 0;
    itemsToDelete = [];
    for i = 1:num_households
		tic;

		id = ids{c}(i);
        Consumer = get_weekly_consumption(id, 'issm');
            
        for j = 1:num_traces_per_household
            idx = (i-1)*num_traces_per_household + j;
            week = traces_per_household{j};
            % discard trace if it contains more than 4 zeros
            weekly_trace = Consumer.consumption(week, :);
            if sum(weekly_trace == 0) > 4
                itemsToDelete(end+1) = idx;
                continue;
            end
            samples{c}(:,idx) = compose_featureset(weekly_trace', feat_set);
            households{c}(:,idx) = id;
        end
        
        t = toc;
		avg_time = (avg_time * (i-1) + t * 1) / i;
		eta = avg_time * (num_households - i);
		fprintf('Progress: %i%% (%i of %i). ETA: %s\n', round(i*100/num_households), i, num_households, seconds2str(eta));
    end
    samples{c}(:,itemsToDelete) = [];
    households{c}(:,itemsToDelete) = [];
    truth{c}(:,itemsToDelete) = [];
end

sD.classes = classes;
sD.samples = samples;
sD.households = households;
sD.truth = truth;

%% Store Data Struct

name = ['sD-', sInfo.classes];
if exist(path, 'dir') == 0
    mkdir(path);
end
filename = [path, name];
if (not(exist([filename, '.mat'], 'file')))
	save([filename, '.mat'], 'sD', 'sInfo');
else
	i = 1;
	filename_dupl = filename;
	filename = [filename_dupl, '-', num2str(i)];
	while (exist([filename, '.mat'], 'file'))
		i = i +1;
		filename = [filename_dupl, '-', num2str(i)];
	end
	save([filename, '.mat'], 'sD', 'sInfo');
end

%% Print Summary

fid = fopen([filename, '.txt'], 'w');
maxlength = 0;
for c = 1:length(classes)
	if (length(classes{c}) > maxlength)
		maxlength = length(classes{c});
	end
end
fprintf(fid, 'Classes:\n');
fprintf(fid, '--------\n');
for c = 1:C
	fprintf(fid, ['\t%i:\t%-', num2str(maxlength), 's\t\t%4i samples\n'], c, classes{c}, size(sD.samples{c},2));
end
fprintf(fid, '\nConstraints:\n');
fprintf(fid, '----------------------------\n');
for c = 1:C
    % TODO: change when multiple constraints are supported
    constraint = constraints{c};
	fprintf(fid, '\t%i:\t %s %s\n', c, names{1}, constraint{1});
end
fprintf(fid, '\nFeature Set:\n');
fprintf(fid, '--------------\n');
maxlength = 0; 
for f = 1:length(feat_set)
	if (length(func2str(feat_set{f})) > maxlength)
		maxlength = length(func2str(feat_set{f}));
	end
end
i = 1;
for f = 1:length(feat_set)
	D = feat_set{f}('dim');
	fprintf(fid, ['\t%-', num2str(maxlength), 's\tdim: %i\tIndex: %i..%i\n'], func2str(feat_set{f}), D, i, i+D-1);
	i = i + D;
end
fprintf(fid, '\nFeature Vector total dim: %i\n', compose_featureset('dim', feat_set));