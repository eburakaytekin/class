% This file is part of the project CLASS (https://github.com/beckel/class).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich & TU Darmstadt, 2012
% Authors: Christian Beckel (beckel@inf.ethz.ch), Leyna Sadamori (sadamori@inf.ethz.ch)

% daily minimum
function feature = min_cons(consumption)
    if strcmp(consumption, 'reference')
        feature = 0;
    elseif (strcmp(consumption, 'dim'))
		feature = 7;
	elseif (strcmp(consumption, 'input_dim'))
        feature = 48*7;
    else
		feature = zeros(7,1);
        for i=1:7
            start = (i-1) * 48 + 1;
            stop = (i-1) * 48 + 48;
            indices = start : stop;
            feature(i) = min(consumption(indices));
            
            
            if feature(i) > 0.5
                feature(i) = 0.5;
            end
            
            feature(i) = sqrt(feature(i));
        end
    end
end 