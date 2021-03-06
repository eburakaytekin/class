% This file is part of the project CLASS (https://github.com/beckel/class).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich & TU Darmstadt, 2012
% Authors: Christian Beckel (beckel@inf.ethz.ch), Leyna Sadamori (sadamori@inf.ethz.ch)

function plot_classifier_comparison_f1score_all()
	
    %% Preset Files 
	
	result_path = 'projects/+e_energy/results/classification/';
	figure_path = 'projects/+e_energy/images/';
    
    labels_positive = { ...
        'Singles'...
        'OldHouses'...
		'Families'...
		'NoKids'...
        'Persons'...
		'eCooking'...
		'Retired'...
        'Employment'...
		};
    
    labels_negative = { ...
        'Persons'...
		'eCooking'...
	};

    
    labelsInPlot = { ...
        'single'...
        'age\_house (old)'...
        'family'...
        '#children = 0'...
        '#residents (\leq2)'...
        'cooking (el.)'...
        'retirement'...
        'employment'...
        '#residents (\geq3)'...
        'cooking (not el.)'
    };
    
    method = { ...
            'knn'...
            'lda'...
            'mahal'...
            'svm'...
            };

    colors = { ...
            'r'...
            'b'...
            'g'...
            'k'...
            };
        %[1,0.4,0.6]...
        
    markers = { ...
            '*'...
            '+'...
            'x'...
            };

    l_legend = {'kNN', ...
                'LDA', ...
                'Mahal.', ...
                'SVM' ...
               };

    width = 13; 
    height = 8.5;
    
    num_methods = length(method);
    num_labels = length(labels_positive) + length(labels_negative);
    fm_all = zeros(num_methods, num_labels);
    for l = 1:num_labels
        for m = 1:length(method)
            if l <= length(labels_positive)
                load([result_path, 'sCR-', labels_positive{l}, '_all_', method{m}, '.mat']);
                fm_all(m,l) = f_measure(sCR, 1, 1);
            else
                load([result_path, 'sCR-', labels_negative{l-length(labels_positive)}, '_all_', method{m}, '.mat']);
                fm_all(m,l) = f_measure(sCR, 1, 2);
            end
        end
    end

    %% Plot results
	fig_h = figure();
	hold on;
    
    for l=1:num_labels
        for m=1:3
            tmp = plot(l, fm_all(m,l), markers{m}, 'Color', colors{m});
            set(tmp, 'MarkerFaceColor', colors{m});
        end
        
        plot_x = l;
        plot_y = fm_all(4,l);
        plot([plot_x-0.15 plot_x+0.15], [plot_y plot_y],'-', 'Color', colors{4});
    end
    
    hold off;
    
    xlim([0, (length(labelsInPlot)+1)]);

    ylim([0.2 0.9]);
    ylabel('F_{1} score');
    set(gca, 'YGrid', 'on');
    set(gca, 'XGrid', 'on');
    
    % legend(l_legend, 'Location', 'SW');
    legend(l_legend, 'Location', 'NorthOutside', 'orientation', 'horizontal');
    
    fig_h = make_report_ready(fig_h, 'size', [width height], 'fontsize', 9);

    xticklabel_rotate(1:length(labelsInPlot),45,labelsInPlot);

    y_ticks = [ 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 ];
    set(gca, 'YTick', y_ticks);
    y_tick_labels = cell(1, length(y_ticks));
    for i = 1:length(y_ticks)
        y_tick_labels{i} = [num2str(y_ticks(i)*100), '%'];
%        y_tick_labels{i} = num2str(y_ticks(i));
    end
    set(gca, 'YTickLabel', y_tick_labels);
   
    %% Save figure
	filename = 'classifier_comparison_f1score';
    saveas(fig_h, [figure_path, filename, '.eps'], 'psc2');
    warning off
    mkdir(figure_path);
    warning on
 	close(fig_h);
end


