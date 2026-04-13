%\[text] # Run samples of the ServiceQueue simulation
%\[text] Collect statistics and plot histograms along the way.
%%\
%\[text] ## Set up
%\[text] We'll measure time in hours
%\[text] Arrival rate: 0.8 per minute
lambda = 0.8;

%\[text] Departure (service) rate: 1 per 6.5 minutes, so 12 per hour
mu = 1/8;

%\[text] Number of serving stations
s = 8;

%\[text] Run 100 samples of the queue.
NumSamples = 100;

%\[text] Each sample is run up to a maximum time.
MaxTime = 240;

%\[text] Make a log entry every so often
LogInterval = 5;

%%\
%\[text] ## Numbers from theory for M/M/1 queue
%\[text] Compute `P(1+n)` = $P_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$.
rho = lambda / mu;
P0 = 1 - rho;
nMax = 10;
P = zeros([1, nMax+1]);
P(1) = P0;

for n = 1:nMax
    P(1+n) = P0 * rho^n;
end

% Theoretical values
L_theory = rho / (1 - rho);
Lq_theory = rho^2 / (1 - rho);
W_theory = 1 / (mu - lambda);
Wq_theory = rho / (mu - lambda);

%%\
%\[text] ## Run simulation samples
%\[text] This is the most time consuming calculation in the script, so let's put it in its own section. That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%\[text] Reset the random number generator. This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.
rng("default");

%\[text] We'll store our queue simulation objects in this list.
QSamples = cell([NumSamples, 1]);

%\[text] The statistics come out weird if the log interval is too short, because the log entries are not independent enough. So the log interval should be long enough for several arrival and departure events happen.
for SampleNum = 1:NumSamples %[output:group:0c822fcd]
    fprintf("Working on sample %d\n", SampleNum); %[output:9bb20cec]

    q = ServiceQueue( ...
        ArrivalRate=lambda, ...
        DepartureRate=mu, ...
        NumServers=s, ...
        LogInterval=LogInterval);

    % Start the simulation by scheduling the first arrival
    q.schedule_event(Arrival(q.InterArrivalDist(), Customer(1)));

    run_until(q, MaxTime);
    QSamples{SampleNum} = q;
end %[output:group:0c822fcd]

%%\
%\[text] ## Collect measurements of how many customers are in the system
%\[text] Count how many customers are in the system at each log entry for each sample run.
NumInSystemSamples = cell([NumSamples, 1]);

for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};

    % Pull out samples of the number of customers in the queue system.
    NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end

% Or using cellfun
NumInSystemSamples = cellfun( ...
    @(q) q.Log.NumWaiting + q.Log.NumInService, ...
    QSamples, ...
    UniformOutput=false);

% Join numbers from all sample runs.
NumInSystem = vertcat(NumInSystemSamples{:});

%%\
%\[text] ## Pictures and stats for number of customers in system
meanNumInSystem = mean(NumInSystem);
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:38873324]

fig = figure(); %[output:2151c4bc]
t = tiledlayout(fig,1,1); %[output:2151c4bc]
ax = nexttile(t); %[output:2151c4bc]

hold(ax, "on"); %[output:2151c4bc]

h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:2151c4bc]
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:2151c4bc]

title(ax, "Number of customers in the system"); %[output:2151c4bc]
xlabel(ax, "Count"); %[output:2151c4bc]
ylabel(ax, "Probability"); %[output:2151c4bc]
legend(ax, "simulation", "theory"); %[output:2151c4bc]

ylim(ax, [0, 0.3]); %[output:2151c4bc]
xlim(ax, [-1, 21]); %[output:2151c4bc]

pause(2);
exportgraphics(fig, "Number in system histogram.pdf"); %[output:2151c4bc]

%%\
%\[text] ## Collect measurements of how long customers spend in the system
TimeInSystemSamples = cell([NumSamples, 1]);

for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};

    TimeInSystemSamples{SampleNum} = ...
        cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served');
end

% Or using cellfun twice
TimeInSystemSamples = cellfun( ...
    @(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);

TimeInSystem = vertcat(TimeInSystemSamples{:});

%%\
%\[text] ## Pictures and stats for time customers spend in the system
meanTimeInSystem = mean(TimeInSystem);
fprintf("Mean time in system: %f\n", meanTimeInSystem); %[output:9feb0099]

fig = figure(); %[output:553c73f1]
t = tiledlayout(fig,1,1); %[output:553c73f1]
ax = nexttile(t); %[output:553c73f1]

h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60); %[output:553c73f1]

title(ax, "Time in the system"); %[output:553c73f1]
xlabel(ax, "Time"); %[output:553c73f1]
ylabel(ax, "Probability"); %[output:553c73f1]

ylim(ax, [0, 0.2]); %[output:553c73f1]
xlim(ax, [0, 2.0]); %[output:553c73f1]

pause(2);
exportgraphics(fig, "Time in system histogram.pdf"); %[output:553c73f1]

%%\
%\[text] ## Answers
%\[text] For the M/M/1 queue with arrival rate $\lambda = 10$ customers/hour and service rate $\mu = 12$ customers/hour:
%\[text] - $L = 5$
%\[text] - $L_q = 4.1667$
%\[text] - $W = 0.5$ hours = 30 minutes
%\[text] - $W_q = 0.4167$ hours = 25 minutes
%\[text]
%\[text] From the simulation:
%\[text] - Mean number in system = see Command Window output
%\[text] - Mean time in system = see Command Window output
%\[text]
%\[text] Percent discrepancy formulas:
%\[text] - $L$: $\frac{|L_{sim} - 5|}{5} \times 100$
%\[text] - $W$: $\frac{|W_{sim} - 0.5|}{0.5} \times 100$

% Also print the theory values at the end
fprintf("\n--- Theoretical Values ---\n"); %[output:36c09a93]
fprintf("L  = %.4f\n", L_theory); %[output:8f9fd217]
fprintf("Lq = %.4f\n", Lq_theory); %[output:15d60b95]
fprintf("W  = %.4f hours (%.2f minutes)\n", W_theory, W_theory*60); %[output:65a56c73]
fprintf("Wq = %.4f hours (%.2f minutes)\n", Wq_theory, Wq_theory*60); %[output:59dfe1f9]

% Compute discrepancies
percentDiscrepancy_L = abs(meanNumInSystem - L_theory) / L_theory * 100;
percentDiscrepancy_W = abs(meanTimeInSystem - W_theory) / W_theory * 100;

fprintf("\n--- Simulation Comparison ---\n"); %[output:3af794fe]
fprintf("Simulated mean number in system = %.4f\n", meanNumInSystem); %[output:6a3c659c]
fprintf("Simulated mean time in system   = %.4f hours\n", meanTimeInSystem); %[output:90d5630e]
fprintf("Percent discrepancy for L = %.2f%%n", percentDiscrepancy_L); %[output:8ac810f8]
fprintf("Percent discrepancy for W = %.2f%%n", percentDiscrepancy_W); %[output:72878adc]

%\[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[text] 
fprintf("\n==============================\n"); %[output:8811ab3f]
fprintf("        FINAL ANSWERS\n"); %[output:5485326b]
fprintf("==============================\n"); %[output:6521b782]

% Theoretical values
fprintf("\n--- THEORETICAL (M/M/1) ---\n"); %[output:9223c91e]
fprintf("L  (avg # in system): %.4f\n", L_theory); %[output:9b01d036]
fprintf("Lq (avg # waiting)  : %.4f\n", Lq_theory); %[output:41b01363]
fprintf("W  (time in system) : %.4f hours (%.2f min)\n", W_theory, W_theory*60); %[output:25d27bb9]
fprintf("Wq (waiting time)   : %.4f hours (%.2f min)\n", Wq_theory, Wq_theory*60); %[output:85ef9ae9]

% Simulation values
fprintf("\n--- SIMULATION ---\n"); %[output:76ec64d8]
fprintf("Mean number in system: %.4f\n", meanNumInSystem); %[output:736d781a]
fprintf("Mean time in system  : %.4f hours (%.2f min)\n", meanTimeInSystem, meanTimeInSystem*60); %[output:3a1d9ac8]

% Discrepancy
percent_L = abs(meanNumInSystem - L_theory) / L_theory * 100;
percent_W = abs(meanTimeInSystem - W_theory) / W_theory * 100;

fprintf("\n--- DISCREPANCY ---\n"); %[output:1282cfe8]
fprintf("L difference: %.2f%%n", percent_L); %[output:691c3a0e]
fprintf("W difference: %.2f%%n", percent_W); %[output:2bb309dc]
fprintf("==============================\n"); %[output:13c79e5f]
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":30.7}
%---
%[output:9bb20cec]
%   data: {"dataType":"text","outputData":{"text":"Working on sample 1\nWorking on sample 2\nWorking on sample 3\nWorking on sample 4\nWorking on sample 5\nWorking on sample 6\nWorking on sample 7\nWorking on sample 8\nWorking on sample 9\nWorking on sample 10\nWorking on sample 11\nWorking on sample 12\nWorking on sample 13\nWorking on sample 14\nWorking on sample 15\nWorking on sample 16\nWorking on sample 17\nWorking on sample 18\nWorking on sample 19\nWorking on sample 20\nWorking on sample 21\nWorking on sample 22\nWorking on sample 23\nWorking on sample 24\nWorking on sample 25\nWorking on sample 26\nWorking on sample 27\nWorking on sample 28\nWorking on sample 29\nWorking on sample 30\nWorking on sample 31\nWorking on sample 32\nWorking on sample 33\nWorking on sample 34\nWorking on sample 35\nWorking on sample 36\nWorking on sample 37\nWorking on sample 38\nWorking on sample 39\nWorking on sample 40\nWorking on sample 41\nWorking on sample 42\nWorking on sample 43\nWorking on sample 44\nWorking on sample 45\nWorking on sample 46\nWorking on sample 47\nWorking on sample 48\nWorking on sample 49\nWorking on sample 50\nWorking on sample 51\nWorking on sample 52\nWorking on sample 53\nWorking on sample 54\nWorking on sample 55\nWorking on sample 56\nWorking on sample 57\nWorking on sample 58\nWorking on sample 59\nWorking on sample 60\nWorking on sample 61\nWorking on sample 62\nWorking on sample 63\nWorking on sample 64\nWorking on sample 65\nWorking on sample 66\nWorking on sample 67\nWorking on sample 68\nWorking on sample 69\nWorking on sample 70\nWorking on sample 71\nWorking on sample 72\nWorking on sample 73\nWorking on sample 74\nWorking on sample 75\nWorking on sample 76\nWorking on sample 77\nWorking on sample 78\nWorking on sample 79\nWorking on sample 80\nWorking on sample 81\nWorking on sample 82\nWorking on sample 83\nWorking on sample 84\nWorking on sample 85\nWorking on sample 86\nWorking on sample 87\nWorking on sample 88\nWorking on sample 89\nWorking on sample 90\nWorking on sample 91\nWorking on sample 92\nWorking on sample 93\nWorking on sample 94\nWorking on sample 95\nWorking on sample 96\nWorking on sample 97\nWorking on sample 98\nWorking on sample 99\nWorking on sample 100\n","truncated":false}}
%---
%[output:38873324]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 7.584583\n","truncated":false}}
%---
%[output:2151c4bc]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAWgAAADYCAYAAADGWHkUAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQe4FUXy9lsxYERYzAkVswjqillERAUMKCrmACiCEXVBASMqklFBkSAmFDEh6ooRYc1ZzII5xxXU\/Rvx89f71dk+c+dMOGHOzD1Vz7PPyj0zHd7ufqe6qrp6sT\/\/\/PNPo6IIKAKKgCKQOgQWU4JO3ZhogxQBRUARsAgoQetEUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAgoQescUAQUAUUgpQgoQad0YLRZioAioAiEEvQnn3xifvvttxxSa6+9tlliiSXqILdgwQLz3Xff2b\/zO8+lUT799NNcs1ZYYQWz4oorprGZZWnT77\/\/br788kvDGP7nP\/8xm2yyiVl99dXLUrYWUj8QYI689NJLuc6sscYaZs0116xa5\/79738b2oQ0bNjQsEZrWUIJettttzXffvttDqNBgwaZI444og5mEyZMMIMHD879nUFv1KhR6rBdf\/31c2066aSTzJlnnpm6NpajQe+\/\/7455ZRTzBtvvJEr7owzzjAnn3xyOYqvWhk\/\/fSTQRkQWXXVVU2DBg2q1p6sV\/zDDz+Yli1b5rrRp08fO28qKV988YVZtGiRraJx48ZmmWWWyVXXsWNH89Zbb9l\/d+rUyVx55ZWVbErqy45N0Mstt5x5\/PHH65CvEnS6xvrwww83Tz\/9dF6j6gNB33nnneass87K9euZZ54xK6+8crrAz1BrkiZodnO77rprDqGrrrrK7L333krQBeZMbIKmnB49epj+\/fvnFakEnZ5V+ccff5gNN9wwr0H77ruv1Uj23HPP9DS0iJYoQRcBWsArXoI+++yzzQknnFDeSpzSPvjgA7P77rsrQUdEuCiCpuxHHnnErLfeerlqkiToP\/\/809a72GKL+XYTgiq07S1k4qBM\/rf44otHhM6YhQsXFm3D\/r\/\/+7+8rV3USr\/66iuz9NJLB5qP8AX8\/e9\/zxVZiuYs9kA\/v0PUNkd9DvMF9QWZxuISNHOBLXWTJk2Kwpu2B82noN+8\/aZv+HPcLX1UbDAJ8C5j75Vff\/3VzkXMBcWYe1wfE+NcaF259f7yyy++bQnrT7EEDc70Mw52paxPbz8wq4ENFoRKincNFE3Qe+yxhxk\/fnwoQTMg5513Xu654447zrRt2zb3748\/\/tgMGDAg92\/sX9i9EbayOA2Q\/fff36y22mrm7rvvNg8++KD5+eefzV577WUOPvhgs91225nXXnvNXHvttXZbz4Lccsstzamnnpr3taYcL0Hz7m233WYeffRRAzjbb7+92W+\/\/cyhhx7qOw7333+\/ueWWW6xjhef\/9re\/2frRTjt06JD3zg033GAefvhh+7ctttjC0PepU6eaGTNmGCb4nDlzIo01ZdC3V1991daJUO\/WW29tIN+NN944V87o0aMN9ud77rkn9zdsjDyz0047GTTpMAFzbH8vvviimTt3rn0c7HfccUfTvXt3s+mmm+aKKGV8KeSzzz4ztHnWrFl5vo5tttnGHHbYYXYsWBjffPONGT58uHn33XfNCy+8kKuf\/rBozznnnByxs5gnTZpk\/vnPf+bazwsoFIwv8woycwV8n3jiCfunjTbayBxyyCGGj8HMmTNtne3atbPje+CBB9o5SZuffPJJ+xvldu3a1e4svR94yG\/ixInmgQceyLVlgw02MPTvyCOPtPPCFTRYMEGY282bN7fzk\/Fk93PJJZfY3\/jAUy6\/YTYQoS28B3ZRfECU07Nnz9z7nTt3tn1E6P99991n\/xunP8\/dcccdFhN8G5BVmzZtzGmnnVZnx+Y3x8Ds9ddft8qdCOOxzjrrWPy22mor47VB4zPBt8WYM\/fBDpMIa3vJJZesU02c9Rm2DljjtJl1IOuOPu+yyy7m6KOPtnNJxuLEE0+0Ch6yyiqr2LnqCmWNGjUq9yf6C2cgQWugaIKmYAho5513tpUU0qDffPPNXEN4bujQoeaggw7KNZSGd+nSJffvcePG5bbhroMSknnllVfqYApgl112mWFiC4juQ0OGDLETVsQlaCYzZOYnTFTaKpojC61fv35m+vTpBcfVq6nSpmnTptnnGUzKEHJZa621QgkajYv2QzZB4mIKifKB8hM+EOeee25gWYwHW1zXMex9YezYsbmPUSnj633Xr2EQDaTEhxwyKCT4RYhAgMgZB\/5dSPjYXH311XnOMd6RseV3xsoPg0svvdTcdNNNec5XqQdicxcmCw8sXUett03XX3+9XfAi7vjRdz7mMq8FCzTDAw44oODcpazNNtvMKgPLL7984HgH2aDBXeYeCgERT4XWCwpOs2bNAusKmpuXX365VR5cgqZOFDG\/dQ03MA5C0sWsz6DG3nrrrfajHySQNwoEwni4\/PSvf\/0rLxqGdXzNNdfkiuMjhyIQtgZiETQTkC22TH6+ZnyxILFKE3QgUgE\/MshoOjKQLkGHlTlixAgLPMLH6IILLgh7xQwcONB069bNPucStPfFKAQdZZJIuWg6aLZMcMjMO6n5kB177LGBUSto9exuChG82wcwhchKIWi0UnfBQypodF4SuPnmm60G5xKZ2xb6Nnv2bGvGcIk2aLCYF+xgZMsc9b2wCfDQQw9ZLQ9B4+TfYXLXXXflPhZBJCYEfeGFFxqIXYS5RDSLu7PgtygRGVEJOqwPKDQjR44MfMw73u7D7AawTbsEHVbnmDFj7PPFrs9C5fNhFcVTnuGD8N5779X5aLMjYA7xsXAtBXzI3V14+\/bt7W4LIdyV3R0StgZiE\/Txxx+ft5WXhiRB0BAkHWLbTYicK\/wdUwl2Kraa7rZPvlY87yVoBoLtCSDfeOONeRoyBMQiZhLjeRbS4+9su1q3bm23xSwE+Y3FAllgx\/MjaAaHrRyEQ72FhPJ22223vAnB7oJ+0kfMS2gdIrTvuuuus\/\/EXkYdIuDGlixM2OZffPHFeWWCKW3B5IEZQkQ+XsUStNcW6e4+IBp31+OGQwbZoDFziUZDOxkLtBY+XGjWaETu9tp1iHkJGhMHBIu22qtXr7yPFuNPuU2bNrXavSw26gQ\/iaDh\/0X4uPzjH\/+w23kIGZIVEeLl334EzRzF6YtJi22xu7NkDqIpIxALpCBzn10ndQVJHIIWPDG7MBfc+ctu1MW2UJ1xbNCUQX\/BdNlll7XznagPEfDlN0xOxazPQm30zjHwBWd2tKwRduwiYkX4+uuvralTxDUBf\/7559a8KMI8hEejrIHYBM0WjgVPwxC0F0gKbc8vDrrYBUzZ7kR0vzr8xkR89tlnc512txRsy8RWxwPYzYSwXIJGi2JSyWEVtkkQg9hdeZetGxPeJTgv4YGJO3GwC2Jj9BI0NkfejeKIZAFg7xXx04a8GEBs2FaLJWhvaB74QkKIdwLK4ih2fL1kCun17t3b7LDDDtamiy8BjR7h4ATbQSSIoL3bSHwF7qKBbFu1apXD1J1TXoJ24\/j5OLn2QzRFNEaEba3ssvi3kD7PuzG8ssORynnfnWeiiXkJWrb+Lpl4lQxswBDU5ptvbrU02QFh3hB\/TiEyikPQXjy923o0zDCJS9BuMIJ3DorWzo6+mPVZqK1eRQUMWbv8P3Z9N3wVH4KEebJDdf1KMqbeOcszfOyirIGiCJooAeyBojWiabC9rCRBY59yNUYv+TExxfuMQ4VJK+JOLHdy+23LvIuRD9GHH36YZ7tlYa+00kq58iFwV2MXLcrbRpx9UU0s3kni7gKk4ilTpuS1Sz5ExRK0+0HEyRpkb5c2FEvQP\/74o3Xk+gkffba7jDkmFzcyIYigsfeKU5YycKp6BaeTq\/G+88471kTnErT3XW+d2IXFuefVjuRD6q1HHErSHtfhy99kfF2CLtQHHEzPPfecL3Zo22id\/C\/M\/kwBcQiaD4pbJs5WsBEpN0Hz0caU5kqLFi1yvIN5AzOHdx1EXZ+FCJo6IWQ\/oU04i+EO2uKKd56gKDJ\/4SJx2qO4ocAhUdZAUQRN4V6bLFtCcYjxu2ggxS5gynAJw+uAwdaLbRLxTmQvQaPdiybhEiTAuUROWV6QcQTQB9fAH6YlyBbGS9BCBmHv8\/v5559vTS4ioh277xLN4m4zRdsqhqDRVt3oDO8HsVCbSxnf22+\/3fTt2zcQDsYN045EXQQRtGvP8+64pBJOwk6ePDlXp+y8XIJmZ+USoHc+uR9LL0GLqWafffYJdA56Oy0fV5egMYu4tmZ5B80Lh2+QIxciwQzmjRLx1huVoP0+Ft75XW6CFgJ22+xygvzu3TmFrS9Zn0HPYdpDsQsStHbWqSiGXiz5HZ5i9y7KrPckdtgaKJqgMQcQ7lLIq1uIoL1RFXwBXedCoSiOShC0nwaNqcL1xGP8Zxs7bNiw3FhBXn4hPvIAuGCDciewd9GHTSKvJo9d25vfxDu4Yg8rhqCxr4kZgbbx5Q+LHuE5L0F7xxcTET4BEXd8+RuLGo2C8MlCzkl37IMI2jXR+Glf1OfV+mQbWi6CpnxMNcccc4yB\/EWBICQ0SHgH5cElaO+cd99H+0JBQZsvFCUCBo899phZaqmlCladZoL2O+rtR9BE5BSzPsPWIEoR2jmOXr9IEt73RqW5OyfWPB9JN0rN7+Rr0BoomqBpHKTBl9xPhKCpHLIS8WqtxD1LrCXPsLUgPwa2nkpr0GgFkK9rE\/badbGBvf3223bRifiZG\/wwKIWg2Ya7eTPckB6py6vBiDZYDEFTJnZMMdV4CQ77LTZxObiCVxpMwsaXCeo6VYSgcWhJ4irwxwGGfRK7NzsD1yHJOLG9RlMJImjXN0J\/xNYneNF2TCd+fSw3QV900UU5p63b\/jBSCCNoiJmPogjx7ex+nn\/+eYsZH21XvLZvb\/31gaBZj8Wsz0JjwU5X8r3gnyIqhw85cxOnq+QK4X2UMdf\/hInNPYnJrk6cp94dUZQ1UBJB00AWrbuYpNNC0F7DPp5lvKKciGJ7SAeZJCIEe7MQ2b5AOPJbKRq0OO2ow2sDdr+AXocPX8CnnnrKOl7cQyi07YorrsgROxq3uxXFNIEzqhSChrzcsDKcCpiQIE7EG+nA72hLkF2xBO21m7rOMK+dDwLiYxo2vkRVuFtxIWjMMa5PwQ01o3\/eD6WYh7wETZ+JjEC8HzXGiWgTOX3n\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\/\/33L9sFkyU1JOBl1aArhayWqwjUDgKJE3StQKsEXSsjrf1UBCqHgBJ0hbBVgq4QsFqsIlBDCCRO0O3btze\/\/PKL6dSpk+nXr5\/BnjxgwIBYkN9xxx3qJIyFmD6sCCgCWUQgcYLWo95ZnCbaZkVAEagGAokTNLeh\/Pzzz2azzTYzO++8s3nvvffMww8\/HKvvhx9+uFl++eVjvZP0w2riSBpxrU8RqH8IJE7Q1YCQ7HnffPONadiwoVlhhRVKasKCBQvMl19+adZee+3ASJJqEPTll19uuCVdRRGoFQS22247c9ppp9Xb7qaSoDnIwv2DTZo0MY0aNSoafIiZC2ZHjRplfvrpJ1vOJptsYrCDn3LKKZHzeSxatMhcccUV5p577jHvv\/9+rj3rrbeeGTRokNlxxx3rtLEaBM3Ogttpgm6mKRpMfVERSBkCMtdvvvnmlLWsfM1JDUF\/+umn5sorrzSPPPKI+fbbb3M9XG655cxWW21ljj\/+eGsSIR90VBkyZIi55pprco9zMa2UTbrTwYMHh5b3xx9\/WCfmtGnTbDm0By1cLrDlb2PHjjUdOnTIa1a1CJpG1OcJG3Xs9bn6jwAKSX2f76kg6EcffdT06NEjdEZB0BDuMsssE\/rsO++8Y\/bee2\/73EknnWROPfVUs+SSS9qokWOOOcb+fejQoeaggw4KLOull14yXbp0sc9cfPHF5tBDD7Wk\/vLLL5tzzz3XvPHGG\/ZG8scffzzvIlsl6NAh0gcUgZIQUIIuCb5oL6OJYnIQE0Tnzp3NHnvsYVZddVWbs+Ojjz4yd911l3nhhRdsgfvuu68ZPXp0qOZ76aWXmokTJ9rLaDm9yKWzIvIbpoAwbfPaa6+1xAzZX3XVVXmdwuQh9q8ZM2YY0qCKKEFHG399ShEoFgEl6GKRi\/HeTTfdZM477zz7xq233mq23XZb37eJ\/rjgggvsb0R9hOX0OPbYY82cOXPM2WefbU444YS8MtF2jz76aPs3NOEVV1yxYItPPvlkQ3Imv3JwGGJ+QfgY7L777krQMcZeH1UESkFACboU9CK+279\/fzN16lRLmELAhV5Fu547d64ZOXKk4b+DBMcd2vltt91mttlmm7xHuSRA\/hZG9k8++aS1W2+99dZ1LrV1iR7bOU5D1aAjDrw+pgiUiIASdIkARnl94MCB1syAI6579+6Br4g2yzvdunUr+Cymkc0337ygto3jb8MNN7S\/B2ntQY159913zVFHHWU\/ApA95bhmFFfDj2JKiYJV2DNhE1aiPMLK0d8LI3DLLbcYQrtUqo9A2HyvfgtLb0HVnYRTpkyxzraOHTuaMWPGBPYI8wfarNfe630J8sSujRAX7Jc7Wgh00qRJpm3btpGRJBPfddddZy677DL7DlEdtMfVnvk75WOflpC3JBZ12ITl9\/lf\/cc03WDLyP3VB\/+HwFsP3WSUoNMzI8Lme3paWnxLqk7Qn3\/+udlzzz2tkxCChqi9wh2GhODxPyImIF1XW\/U+\/\/HHH5s2bdrYP2OiWG211fIe+e2338zGG29s\/+ZnAikE5+zZs81FF12Ui4WG2C+55JI65QtBJ72YwyasEPROPYcUP2Nq+M27+3UomaDxZ7AT5OOd9AELiZYiqunMM8+MPZI\/\/vijadCgQS6KirW70047Wb8RO8ikJWy+J92eStSXOEE\/+OCDNlmSK0888UQuzpgIDsh19dVXN99\/\/72ZP3++JVlszwh26q5du+aFtHmBgexbtGhh\/zxz5kyz0UYb5T3CqcLWrVvbv4XZoHkGkwmRHBAustZaa1nHJm0tJGmM4lCCLm0JlYOgJfKnZ8+eNllYkiIETUgrvp84wprddNNN7dzH+Y4IQRMpNX369DjFleVZJeiywPi\/QtCEvWRZTBVRblQRE4afVv7KK6+YAw44wFb96quvWjNFIaHNvXr1sgdokDPOOMNGhSy11FKBTVeCLmZk0\/1OOQgaLRQnNblkGjdunGiHy0HQ7EZRmBDWBiTN+QLvLjWJjilBlxllBpQ7CUsVvtarrLJKYDFsH9FW\/GzbcsKQtmBPDpLbb7\/d9O3b1z5CSKDfsW6\/95WgSx3l9L0fhaAJvWRH+Mknn1jfB85oNz6e3zHBQWhNmza1JIfCsOyyy1oNleRhzz77rH2vZcuWNh0B77z44ovms88+swpOq1atLCkiaLbsLiF83neFsvDZoOEuvfTSJoigaZOYDgkdbdasWe6sAfWjyBBphYmR8wBrrrmm7d\/bb79t0zGQm8aV1157zbz++uvm66+\/Ns2bN7eOVfeDJP0mxJXf33rrLdsPcGD3S\/1hogQdhlCKf581a1YuKsR1BDJxDjvsMGvzdsP1mDDjx483RHhgExcbNRozHwTeufDCCwv2mIXkihJ0iidHkU0LI2hi6onskUNXUs2RRx5pTWLMEa+JwzUTQH7MWxHMCRyq6tOnT176A0xrpBeApMkN065dO187MKdeIXvZcfoRNCkWmNt8UFyhLePGjbMRShz0Ouuss\/J+51wAh8awQbsmDq85UF5ilzpixAi7thDpN0oSqRPuu+++vPJJ\/EX5QaIEXeRErtRr2Is5UcjAeL\/Y3joh3NNPP90eMkGwOfOlf+ihh+y\/DzzwQDN8+PDca67d2p0cEjkS1ievs1EJOgyx7P0eRtD4Rp577jkbMorGiPYIwRJVxEErUhUUImhBgwNW+F9QFiRvDNo2uWPQNiXx1\/XXX2922WWXkglaQi8hefHtcHIXpYTEYqwfSBwtH+emEC1aLykXvARNdBNt32CDDayNHaLHZs2aQsTnIwQt\/WbHi+aMj4q8N9SDRh2Ue0cJOsE1ROY5tlle7cNtAqYJGeywryvvERKHBiwkLWVh9hg2bFheTg83dloI2juJguAgltvNIqcEneDkSaiqIIKeN2+e2WuvvSyxoESIjwLCxiEHwZLwK4igXROaq7W6kUhinjvnnHNseaVo0BLNxAcAs4yQIXZytGKEjwt\/Fyeha4P2OgkxwfARQrzhrawpWVf8v7u23FO48ABBAmj0Yb4mJeiEJj4TGs0hiJzdpvCFDoqg8Db7hx9+sDY00oayZYuSbKnUritBl4pg+t5uplD9AAAfwklEQVQPImjmGDZjhBh8TB3Ycr0O6EIEzXPMURHWxMEHH2znK7szEXmf9YLZpBSCpkxIGgLG\/ILzkoNXTz31lI1aikvQREz17t07z+Qh7RbHPOcFcLgLQaNh8xFzRQ6khYWpKkEnsEbcr3WU6jBNsI3y2nyjvJvkM0rQSaKdTF1hJg4\/Wy0aJRFD7PjCbNBuqJpkUfQ6ueMQtJhcgmzQH3zwgc11junPT0GKo0FPmDDBpvD1CyF0TYiUyYfAax6RUcTeDZbeXal3lJWgE5j3MqnRIHCGYCs+7rjjrP0Nu518YTFJIEzQKB7eBJoeWIUSdLVHoPz1hxE0NRJj\/9hjj9ntOU45IT2JPS6kQXsPe5SDoCUfTSGCxqzHeqON2JsxLWA7Jk0CERuswTgETUgrjncuw2Atu0JECbteWc9Bh1yUoP+HXOIHVbzLRlJ\/YqOT49Nir+JrjBaASGIiJhIe3ziJ+8u\/VMNLVIIOxyhrTwQRNAREqBh3bYoCgfmAG+ixQYsJo1IETb333ntvDlLXp1KIoDn9hy2bNUW7OCWIuO\/GIWjpm9\/BFXYH+IPEZKMEHW32V52gJV7ZJWPRqkmehEdcZJ999rEJ8r2Z46J1NdmnlKCTxTuJ2oIIGqUBzdFVNGiTpB2oFEGL8466sPPKnZukRSDiAylE0EQxEdNMGCApDEQkBzr\/9hK0azP2OgndFAuugw\/fz4knnmgjOM4\/\/3x7YYYSdLQZW3WChoBxBuCUEJsSd43x39jvMHOIEIdMeBETC1t0mkUJOs2jU1zbgggaBxsxvZgLIKAddtjBfPXVV4aDToSLCQmWW4OmJ9i4IWe0aByUKDESThpE0O5NRuTn4OAJ0RzuuxAqtw7xgRGTCR8hdrZEdHjtyBA9h78gckiZAzTUQ5kScoeTXgk62hysOkETkYFpg20R3mqC73EgyIk99yg2E58vM\/YttJU0ixJ0mkenuLaF2aBRLDiMIbf\/SC04+pjjkJUkSxJHmsx1bMHkRRcJs0G7u0siOVgbcthE4qb5Ox+EICehmBilXoiYBGBEpZBlEoG0ic3mwBe\/IRxU2W+\/\/ew6dU0aaPRgQOicK0S4oK1TDlKo3\/wmNmiN4jCm6gRNEDwB9wgTC5sYHm9iPDFlMLmZjG6we5RTRsUtwfK9lVaChkSarq\/pRosZ6W\/emxspmx2nVSHHlVZayay77rpmnXXWKaa62O+wltDgOSYex0fDe9jQOb5NGJy8y0Eboqzog2SPZKdAHVxJJ8fN\/Rr63XffGe4FxQ7PoRYh5tidCnhBozjKiWZAWa7NS25WIbUn0RxeYZsEcQddU5VQswOrSSNBc3gAglYpHgEOIyWR27v4FtbOm0rQCY41WzrIgy8z9mVyYrCdcpMZkZuAHASSSjTB5sWuKo0EHbsT+oIikGIElKBTMDhss\/Akk0eDrVLQtioFzc01QQk6TaOhbamPCChBV2lUicPEidCkSRNLzFkUJegsjpq2OUsIKEEnOFo4KojdxL4sWbyoHq8yOQ1wGhJ2F8f5Ic0nAQsnvBo2bJiLEy2la+THxQTDB6SQKEGXgrC+qwiEI6AEHY5RWZ5w4zGDCoSgr7nmmsjJjiDmyZMn51I0UjanpogVJUyvmHweklPAm9zG224l6LJMDS1EESiIgBJ0ApMDUwaEKTkLOnfubM\/s4yzE1PHRRx8Z8tNKbCkheKNHj46kSUtqRukGESCinRNsz+nFuBq5xG0rQZdncnD4iHsmXdltt93sPzkkIf9dntqSL4WdFrnJ8Z0EXXScfMuyX6MSdAJjSA5c0iYi5AYgaYyfcKJQFnKUi16Jwdx7771tUZySOvXUU+0iIWifoH5k6NCh9pRUmJAO8c0337Tvyt2EStBhqAX\/LsS8rjHmH8aYvYwx3ND3b2PMA3+ZtkiN9eFfRTDmEHUWhEMaxP1yUk7yWjC3meNxrkvLQl\/T0EYl6ARGgUQynKCS+OegKtGuOTbrXlVV6Hk5IcUpJ3J7uNqL\/EZMKykNw4TDMiTCcUUJOgy1wr8LOd\/BzTYBxdz516W+XTJE0uzsSN3pHqQaOHCgnWNK0MXPl0JvKkGXH9M6JcoEJicHJwaDRBJ58063bt0CnyWhOacPOZLKLdyuSGY8\/sY9cmGHXkhELqYRLslksSlBFzc5hJzn\/XUJb\/MIRcw3xmyYEZIWgnZzxShBRxjkIh9Rgi4SuDivTZkyxZ7597t921uO3A84Y8aMvJuS\/eqTxC7euwJ5luOqpD1EophL3PLFoakEHWeU\/\/sseZLbtm1rwjRnb8miSeP0TauQrIhEXqTVxKSG7Zw55hI0t3s\/\/\/zzNmcGzmoOXPnd7kPsPzlo8M9wUzdJkLiV2yuYU\/DNoDRwvRtlsit0zwoQHcVVVFyCTBmY6EiKJDvKrbfeuo4fhr5QHnWTPyStogSdwMiQ1YqbfnESkvAbovYKThZC8Pgfjj65Hr5Q89x8tn4EjOOGfAVIkN3br\/w4BC3vRzWllAp32ics5Pz+Y4+ZD4roaLO\/bNLHpdgeLQqB2zXyWwhBc3M2yX9cQeEgAZFLgqKwuM+hDOCDIdxUBOLlUmRvYiZIGk1+o402so\/KJa7sUPk76wx\/DPXy315lhwx8crdmlN1lEUNZtlfSPt\/L0dHEkyVxay\/OFFfIlsVNvggRHNzsQHKV77\/\/3syfP99waSa2ZwSnkdw+XAgATh4SGYJ4L6+UdwiDQ5ioEEdUiUPQ5LqWyZ5E\/oa0T1hwPuixx8xJUcF2nhv7120lJ\/8V2ZFWLRoHMh97stVhXoOwmctC0HQFTRiibty4sU2vi4Y8aNAgc8QRR9ieurcL8R7Ji5j748aNs78\/8MADVrEgvzKZ5EgrikJDKlOUGHaLZK8j4RHtQGMWguZ9lBue53\/333+\/JX20\/TPPPDOHtHwgiJaSm7iLGK5EXkn7fC8HCIkSNJNIvuylND7stl83cbh7I7LUKbcZ828\/E0hQ2+IQdFi6xFIw8Hs37ROWkMaotmdv\/8QWnVaCpr1BNmjMHRC4mBbQXNGAIWxyzrDrI5+0XPUmt2NTrtwwhC8FnwrkCrGiLVOOxPOzM+SyWnLa4Ag\/9NBDcwSNFo5Pho8DIpfSkt+Gv4vwzrPPPhtbcSn3XI5SXtrne5Q+hD2TOEEzCUsV7HyrrLJKwWLcCypx8Hk\/CpwqJP8uojboUkcj2vtif\/4GTS7aK3lPfWuMaWqMmTVrVmpjo4MI2r2Qgo6RkhQtWMxf8m+0XPooYXo8S8goSfm5L5DE95IUn4T4ffv2zcNJcjZD1DhkRYMmM6Tkd+YFtHA+Amjx3AaDvRnbNzs9yPzFF19Mfd4bJegiFlJaXhEThp9dW66Ap63uhQBR2q4adBSU\/J+pZQ3aa0oTM5xcFiuJ\/IPQFce0RCj5meckzh9FiEyQQtCYSfD1uCKaOTZptHnCXQl7pXw5m1D8aFf+TSXoymPsWwNfd7Z6hL\/5ea+jNEvuOvSLDpEThjKJo5QnzyhBx0Er\/1kIegwHh4ooAhv07bvtZrXLtEqcMDsvQYvJAw1aDlJ5+7nsssva8FKICTMGNmTXFMLzchEsZwY4LyAEzQlYbOKuSBuwWRPdIeVy0a3rkEwr3krQCY4MNjjybOBEdA+FcMsK4UjY3yQ0LkqzWMgSV+1qGmwlsfthBnEPvGAfZxJjx0PTICzJT5Sgo6Dv\/wxb7skXXFB0FMd69Zig5YortGSiJ1wTx8KFC+2t9k2bNrWmOXE89u7d214P5Qo2ahzuohUHETTvyUXMkD2HxbBJc1lG3BQIxc+K4t9Ugi4eu1hv8iXHRiZ3qhV6mcgMEvZHSXIE4bJtY+uIMLFJXSoXYnIpAAcKRFy7ddCVWkrQsYa2zsMs\/GLjoNNsf6ajokG7N9QXOqji1aC5WoqLZpmHmBrER0K5suPr0aOHNUGIto1N+t57783tMsmyiJbM7lPC58IIWlIo8GGg7jPOOMNwICwLogSdwChBpOTDkDA67ifkeDbhRBC23LQiyZRkkkZpGsH2TDghaXkHs8ewYcPyDgm4sdNRCNq9ft6vLZrNrrAWTahk1GiOLJ0kJKkXIWuYDHDqQXRRCRq0xAYMWfbq1cve0YnmjFOcvxFmt8Yaa9hdHmFw7DTZVWLO4G9ozoTekYOGC1qRMIIWx6CMFhEdaNFZECXoBEbJdY742cloAjZpchzwPwQttlkzji5EE24oxhlIOUxov9Nb0UqK\/pQSdGGs6msuDsgO0kA7RjioIsmSvFoxl8q2a9cuF8XB84QQkrfDjbbg74TTEYrn2oWpC\/MGTkFXCJMjuZT4bkT7LrS2eFecjsX4ZKKviPI\/qQRdfkzrlChfeIkHDaqSAypklvPzSCfQ1FhVKEEHw1Ufs9nRYzRZTvmtsMIKuZjjWBPHGHuT9rx582xKAg5sEQLnJxA6x7gJw+M0IuGkxdxAJHbrIBKP24cknleCTgDlnj17WrswX\/qDDz44sEbJQtenTx+bcD\/NogQdPjrERkPUCP\/tSpbSjIb3NL1PSF4aTHYc6srKnZ8gqgSdwLwSG10U0pUvvfd4agLNjF2FEnRsyPSFBBEgv\/mECROs6Q+TjHvkPMFmlFSVEnRJ8EV7WRwjOCaIvyTTlp+wbcT5gbMwC1sxJeho469PVQcBOepN7Tgcubyi2DMH1emBatCJ4O5eeYX3m9A4QoXEkUfeDI5jE7pEVAfebJIrheVwTqTxAZUoQVd7BLT++o6AatAJjbB7DZVUiU0MexgE7koWtGfaqwSd0OTRamoWASXoBIeeeGciOojS8BNCjbBXk8YxC6IEnYVR0jZmGQEl6CqMHkexP\/zwQ3ubN3mj11lnHbPuuuuaVq1a5R1\/rULTYlVZLYImR4PkoI7VYH1YEcgYAjLXo9wrmrGu5ZqbaLpRP5A4tccRXk4Pkkaxvkg1CBosuaAgSJjUTdffMhLM37w3t6rPUj8Spb2VfDZK\/bQzLl6RBuH\/P6QfXX+0SI9KYrT6KlUnaE493XjjjfZYK3GY9UWSJGhJrRoVu516DgklPcjmiWv6mTjP7j\/k\/tAmvP3wFPPNu3NtuWFC\/UjUZ5tusKXZeI\/\/3k4SJHf362A2aX9k5GcrgcFbD91k2xAmYNV8lWVjkVASt\/eEtVt\/Lw8CVSdo94Ztchm0bNmyPD2rcilJEzRa3sbtw8kpLulWgpyUoKcYCDrqB41no0pS919GbY8+VxoCVSdomn\/11Vfb5EVEbnCikJwAUTLWldb1+G9ztJbbWBo2bGiP8gZJ0gRdKY1QCbpDRXYRcQg6zgcNbbs+22Tjr9psv1F1gibxEbd1c8uJK5B1ISHBUqEDLZUYDoh58uTJZtSoUfagDEJUCelPOXLu9zFRgvYfCTVxGAMGlSJoscVHWQfYbuuz\/TYKBml\/puoELTcZxwEq7NLYOGVFeVYygsmzfDzIuYsccsgh9hCNN8G5ErQSdKG5VUmCps4opq63H5pibdtR7dVK5FGYovzPVJ2gP\/jgA3t9TxzZf\/\/9E0kZSpvIFMYRc4QcINxUwQEa93ANx2TJae1KqQQdFo3h1kUmQDVx9DNZcxJGtUHHMXEwL6I6VaNGnfActm0l8zgsVZ5nq07Q5elG5UqRDHqEAaLtL7744rnK5Dc\/x0xUgoaI+UB5NRS5Hy5qz5SgkyNoYvW5Vd69WV6iXqKSbqVMHHEIOs4HLeo85Lk4ZB4nfDDqB8Lb1kJrLE6fqvVs1QmawyhIWhO1SDJzMulxL6IrbgQK98i5+UHiEDQa8C233JKnoUDQ87\/6T6TtKpEZStDJETQXrCIk3Bep7wQdx1lcKTKLambxfiAgaL81Vql2lrPcqhA0CZC4IJawOm6WQEiUxG0QXFyZJrLmaDn5QG677bY6l9ZKLl3aT0InNx65EEHL8VR3EP1O\/\/G3OKQb59k4iy3Os1G1x0pt2eNohKXgpQTtT0GVjJ2PE2pYKkGmyXmaOEFz4wQkVSjnBldSoU2mIczOvafQS8BMAvrC3YkI191vu+22ublR6PDIouVXizR\/Fv\/xC\/Pbai1NlOeXnv9A2Z+l\/iW\/eCVSufLsL833Cu0bZSL0LUziPvvH8qtWHa+oGIBZ1Gezglcl50xcvJgLYdLgxy99H6EuritLgyRO0BDZOeecY\/vO6cG2bdvauGJuVZFbvfv27WtOPPHEquMjNy\/TELZJfqF9QsSTJk2yfRGJ4+Sreke1AYqAIpCHQLH27nLDmDhBi02XBP043Zo2bWr7xD1s3IQMKaJFY1Kotnz88cemTZs2thkcQ+eD4gqmmo033tj+yc8EUu32a\/2KgCKQbQQSJ2jMAMQQn3HGGfZaeldGjBhhxo4da5Pyz507t05scdJQcyilRYsWttqZM2faSzld4VRh69at7Z\/8TCBJt1frUwQUgfqFQOIELSYBv5u50VKPPPK\/CWSIP06DHVraO2bMGNOxY8e80ef0I1o\/wt1ufFhUFAFFQBEoFwJVI2hvWBkdwjDPdVdpImg8uvfcc48lZ0jaFTlhSO6Q6667rlxjouUoAoqAImARUIIOmQjkqu7evbt9ynUEcliB2ErMICNHjjSdO3fWKaUIKAKKQFkRUIIOgfP333+3F9mSoAnB5tyoUSMbdYIceOCBZvjw4WUdFC1MEVAEFAHVoCPOgV9\/\/dU6NYWk5TXMHqRJlRvIIxaX9xgfAJyNjRs3TtUBnWL6Uh\/fWbBggY13b9KkSWD3dByrP\/qM1ZdffmnWXnvt0DWZlfGqmgbNyUFvTmXMBYTZIeS+8BOyxk2YMCEXnpfktPjhhx+sM3DRokU2FLAUYl64cKEhaoXbZESIcMFsouaSJEe1cF0SxYPzl3H3Ex3H6o4Va\/GKK66wfiI5lUyL4JdBgwbVuWQ6a+NVNYIuZViTTjdaSlv93iX\/CEfa5TQl6Ut\/\/vnnXK5piFuiQ8pdt5YXHYHx48fbm+YLEbSOY3QsK\/EkO5sBAwaYadOm2eIZJ5Q+UjOIELbboUMH+88sjlfiBE3sM4dSShGccmFbzlLKr\/S73HgxcOBAWw0kQNIdJhuhh\/QN0bjqSo+Cf\/l8NN98802bTlZybhQiaB3H6oyR1PrSSy+ZLl262H9efPHFNpcPO2wSl5177rnmjTfesLc0kdSM\/D5ZHK\/ECbq6Q5qO2rFdv\/XWW6Znz56mX7\/\/XoyKsF3bb7\/97MTq06ePva1FJVkEZGzcWgsRtI5jsmPjre3aa6+1xEy+9quuuirvZ0wekv1uxowZZosttrChsllbd0rQCc8xN8ESR91btWqV14LRo0dbm9pmm21m7r333oRbp9VxYlRuy3n77bfNTTfd5Gvi0HGs\/lxhN47j3i8VMA7DrbbayjZy4sSJNmWDJDbL0rpTgk54npEQioMtyLx580yDBg3yWoBpg7zTQY6phJtcs9VxX2aPHj18x0LHsfrTgpPHfEy33nprs+aaa+Y1yM3VjqmKW5CyuO6UoBOeZzJxChEwNtCuXbvaVqXluHvCEKWmuiCC1nFMzTDVaQiRYEcddZR1FhJtRQZNyBzHfNbWnRJ0wvNs6tSppn\/\/\/jYMSJxQbhM4oYgdGiHXhzcUMeHm1nR1QQSt45i+qcF5BVIuEHmDQMbYn1lrWR0vJeiE55ncYk661Tlz5tSp\/dlnn7XeaGT+\/Pl5dyAm3NSary6IoHUc0zU9Zs+ebS666KJcLDS52S+55JJciuCsjpcSdMLzTG4DL7TVevDBB+1lBYQHFbp1JuEm12x1QQSt45iOacGtR0RykHwNQfE577zzcknXpJVZHS8l6ITnGTG2nTp1srX6XQLAKcnBgwfb67OwnalUD4EggtZxrN64SM0c1+7Vq1fOVEg6BhzsSy21VJ3GZXW8lKATnmdMqh122MF6nzmKesQRR+S1YJ999rFx0FwLdvzxxyfcOq3ORSCIoHUcqz9Xbr\/9dsP1eAjhkFzwXEiyOl5K0FWYZ5JHGjMHWfHkKi2uzZKDKzgQcW6oVA+BIIKmVTqO1RsbakZjnj59us1fc+GFFxZsjFz8kcXxUoKuwhz7+uuvrSNQkru0b9\/ekIjp6aeftq0ZOnSoOeigg6rQMq0yqgbNczqO1Z0vcn1eWCvkvtAsjpcSdNjoVuj3zz77zBxzzDG57H1Ug0bNwQg5olqhqrXYiAiIBh3ksNVxjAhmmR\/7\/PPPzU477RSpVHJwbL\/99vbZrI2XEnSkIa7cQ0w0HBgkfyJfQBruYaxcb+tvyTqO2RrbrIyXEnS25pW2VhFQBGoIASXoGhps7aoioAhkCwEl6GyNl7ZWEVAEaggBJegaGmztqiKgCGQLASXobI2XtlYRUARqCAEl6BoabO2qIqAIZAsBJehsjZe2VhFQBGoIASXoGhps7aoioAhkCwEl6GyNl7Y2BAHuCvzwww\/t5aBcKcYpwHXXXddssMEGZo011lD8FIFMIaAEnanh0sYGIeBmN\/N7jqP1p59+umnUqJECqQhkAgEl6EwMkzYyCAGStpPNbNq0abnHyGuy+eabmx9\/\/NGmbxVBo+Ym6JVXXjkToJJGkwT0ha5Iy0QntJFFI6AEXTR0+mJaEDj77LNz5AyRXX755ZacF1tsMdvEBQsW2L9xXx2y8847m8mTJ9e5UT0t\/XHbcf3119uPDylpueBBpbYQUIKurfGud73l5vO9997b9qt169aWeJdZZpk6\/Vy0aJE58MADzdy5c+1v3FZDusq0ixJ02keosu1Tgq4svlp6hRHgiqOHH37Y1nL33XebFi1aFKzxpZdeMl26dLG\/n3TSSebMM8\/Me\/aZZ54x3AnJzerk515\/\/fUt6ZO723uNEleT\/fTTT4bLSVu2bJlXDmaViRMn2r917drVrL766va\/b7jhBvPdd9+ZDh06WOclN07TJvIUb7nllmbXXXe12j1C\/ZMmTbI5wrlIGJNN9+7dTePGjW2aWpXaQEAJujbGuV728s8\/\/7TRGUi7du0MpBkmpHbl+qMVVljBNGvWzD7Ov8eMGWOuuOIK39epY+zYsWajjTbK\/S7J4i+44AJz9NFH570H4W633Xb2b3fddVeOwCHgTz75xH4c7rjjDvPFF1\/UqW\/EiBHmgAMOMIXyHastOmyE69fvStD1azxrqjcQnNxDx\/VHJ598clH9R7OFaJE99tjDmkKWX35588ILL1jbNQJJ41xccskl7b9LIWhpJPW0adPGkvawYcNybX\/llVdMw4YNzT333GNmzZpl7rvvPqtB4yykXWjgKrWBgBJ0bYxzvezlc889Z00IiGiecTuKKQGSx1zRsWNHS8gNGjTIFYP5BDMKcv755+fMC6USNPXsu+++uXogf\/nAuBegqg067ojWr+eVoOvXeNZUb+RKKjqNFiz22zggoKXKFWMzZ87MM2NIOZhPuD8S7Xr8+PEla9C77LKLgXhd+eqrr3LXMmFu4WOBKEHHGc3696wSdP0b05rpkRvB4ZJaHACuvPJKM2rUKLPWWmuZOXPm+L561llnmTvvvDMvFrkUDdrPQUnFOCW9uwEl6DijWf+eVYKuf2NaMz3igArxzkjfvn3NiSeeGNp3TBZcHEo0BCYGIV8\/rVYKExLn3++9916oBk35os37OQkHDhxounXrVqetQtDDhw+3dnDVoEOHs94\/oARd74e4fndQIiP4fzmIUqjHhL8RzoZAgBChEDS3PnP7s5\/ggJw+fXqelh2kQbu2cT+C9ov8UA26fs\/TYnunBF0scvpeKhDAsYaDDSGumJvRC4mbq0OciphGRo4caeOSiTeW04duGTgRiRhxPwJC0H7asFuPEnQqpklmG6EEndmh04aDwLvvvmvat29vweDAyLXXXmvNF14hlO3www+3IW2ErM2ePds0adLE3H\/\/\/TYuGUGDRpN2xTVX9OnTx5xyyin2Z5x4ZMzjEMull16a907v3r0NDkdECVrnaSkIKEGXgp6+mwoExo0bZ4YOHWrbQs6KIUOGWFMGWesWLlxo45mxUX\/77bf2GTfE7ZdffrEED3FzCASnHA5DhN+OO+44e5oPoRwh\/wEDBphbbrnFkj3mD+KksYnzvrSlHAQ9depU079\/f1s\/Jx2zkuQpFROjHjRCCboeDGKtd4GTgDjdHn\/88TwoIE\/im13xO9DixjrzLA6+xRdf3BKyvO\/GQPMMGjKasgjkTigegrlEPgalatCcfOzUqVOuHjfUr9bHvRb6rwRdC6NcA30kGRKaLETqJWW6v8kmm5jBgwfXyZsh0GB\/xtQhxCp\/h+SxV++55551UJRUoO4PaO7UI6TqErTEU8dxEtIvHJn0DdGj3jUwmZ0uKkHX1njX+96iTX\/88cdWmyUxEYTWvHnzSEn6f\/31V2vT5iaWJZZYwr7H+3K82w+83377zcyfP9+aUjA\/8Lyfo7FU4MnNQRTKqquualZcccVSi9P3M4KAEnRGBkqbqQgoArWHgBJ07Y259lgRUAQygoASdEYGSpupCCgCtYeAEnTtjbn2WBFQBDKCgBJ0RgZKm6kIKAK1h4ASdO2NufZYEVAEMoKAEnRGBkqbqQgoArWHgBJ07Y259lgRUAQygoASdEYGSpupCCgCtYeAEnTtjbn2WBFQBDKCgBJ0RgZKm6kIKAK1h4ASdO2NufZYEVAEMoKAEnRGBkqbqQgoArWHgBJ07Y259lgRUAQygoASdEYGSpupCCgCtYeAEnTtjbn2WBFQBDKCgBJ0RgZKm6kIKAK1h4ASdO2NufZYEVAEMoKAEnRGBkqbqQgoArWHgBJ07Y259lgRUAQygoASdEYGSpupCCgCtYeAEnTtjbn2WBFQBDKCgBJ0RgZKm6kIKAK1h4ASdO2NufZYEVAEMoKAEnRGBkqbqQgoArWHgBJ07Y259lgRUAQygsD\/Az0jDf4Le\/s7AAAAAElFTkSuQmCC","height":70,"width":117}}
%---
%[output:9feb0099]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system: 9.366436\n","truncated":false}}
%---
%[output:553c73f1]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAWgAAADYCAYAAADGWHkUAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQfYFMUZx4cmkIBEmiKgYAGkEx6KBEQsBClSRFCi9GJCL6GDoDQBaYJILwZpUgJiCEYQAoRAiDQBkaIgkggKAj7SyfMfn9nM7be3t3u7d7f33f99Hh797nZnZn+z99\/Zd955J8Pt27dvCxoJkAAJkEDgCGSgQAeuT9ggEiABEpAEKNC8EUiABEggoAQo0AHtGDaLBEiABCjQvAdIgARIIKAEKNAB7Rg2iwRIgAQo0LwHSIAESCCgBCjQAe0YNosESIAEKNC8B0iABEggoAQo0AHtGDaLBEiABCjQvAdIgARIIKAEKNAB7Rg2iwRIgAQo0LwHSIAESCCgBCjQAe0YNosESIAEKNC8B0iABEggoAQo0AHtGDaLBEiABCjQvAdIgARIIKAEKNAB7Rg2iwRIgAQo0LwHSIAESCCgBCjQAe0YNosESIAEKNC8B0iABEggoAQo0AHtGDaLBEiABCjQvAdIgARIIKAEKNAB7Rg2iwRIgAQo0LwHSIAESCCgBCjQAe0YNosESIAEKNC8B0iABEggoAQo0AHtGDaLBEiABCjQvAdIgARIIKAEKNAB7Rg2iwRIgAQo0ElyD1y\/fl18\/fXXrlubK1cuceedd4pPP\/3UOPfee+8VBQsWdF1WIk64ceNGoNp+\/vx5gTbBsmXLJnLmzJkILKwzRQhQoJOko3fv3i2ef\/55162tW7euGD16tChXrpxxbs+ePUXXrl1dl5WIEy5duhTXtv\/444\/ihx9+MC717rvvFpkyZTL+Bs\/Dhw\/Lv+vVqyfeeuutRGAJdJ2RGAa68QFrHAU6YB0Srjm7du0SzZs3d91aCrQ7ZCtXrhR9+vQxTvrnP\/8p8uXLR4F2gTESQxdFpfyhFOgkuQX8FOj+\/fuLjh07JsWVm0fQsW57JHHhCDrybROJYeQSeIQiQIFOknsBPugLFy6EtPaLL74QL730kvFZgwYNxODBg0OOyZo1q\/RB43xlmTNnFhkyZIh45Tdv3gx5vddPsPvOquCLFy\/KdkRj0bT96tWrAtfu1iKJSziBBo9r166J7NmzO67SCxNzJXDLoF9\/+ctfOq4\/mgPhvoAPHnMb4SwSQ\/N5P\/30k7zP7rjjDtdNsrsPb926Je9zJ\/e664rjdAIFOk6gY1ENBPq3v\/2tUXSzZs3EmDFj0lSFH0CnTp2Mzxs1aiSaNGki\/547d67Ytm2b\/P9ixYoJlIEf2Pr168WxY8fEk08+KZ555hl5PCbIJk2aJLZv3y6\/K1q0qHS7tG\/fXmTMmDFNvX\/5y1\/E4sWL5SQffth58uQRVapUkb5blOnE7NqOdq5bt04WU7hwYXmNK1askG0\/ePCgFKuaNWuK7t27i4cffti2unPnzonx48fL64K\/XxkeehDdAQMGSFEyC3SXLl2kjx\/n4BoffPBBUadOHdGtWzeRJUuWmDBRhYIr+uPf\/\/63rBuGa65Ro4Zo2bKlqFq1qvzswIEDYuzYsUZbHn\/8cdG2bduQti1ZskR8+OGHxmfDhg0TDzzwgPz7m2++kfVs2rRJfPfdd8YxFStWFC+++KJ49tln5cPBKUMUgGNR5j\/+8Q9x4sQJWSbKq1ChgnjllVdE7ty5jXrOnj0r8OakDC6oQ4cOiY0bN8o24z7ENbVp00YUKlRI3hOrV68WO3bsMModOnSocT1O7rugHEOBDkpPRNEOpwJtN9HWq1cveTPD7rnnHjnS1n+EqlmjRo0Sf\/rTn6TwmQ3iDXFThjL69etnlGt1aagX4hbJ7No+cuRIMWfOHFkExB8jdPVjN5eLH3ORIkXCVnfq1Ckp5uFs69atAtEvukCjzitXrhjiqJ9bqVIlyUuJtJ9MUM\/SpUvlQ8POIIAQT4zUy5cvbxwKEduyZUvIqXho79u3z2AJ4YToQgjxQLUziDT6winDnTt3is6dO1veZ6gH7Vu0aJF86MKOHz8unnrqKaMJEHL9Iaq+KFmypHxgDBkyxLK5EO5HHnkk0i0XqO8p0IHqDneN8Vug3dUeevRHH30kR4+whQsXCozAIhncMeaRnPkcpwIdqS4I0IQJE8Iedvr0aTnytDKMSjdv3ixHdbpAR6pz6tSp8ni\/mWBEW7169ZDq8UCAkJkfrp999pl8A8DDUB8h6\/2F0WzlypWN8tq1aycGDRok\/8YblP7Qgwjircb8IHzvvfekoEZiCLcTRrtWgwD9gvDw++STT+QbgVmgI3EP9z3ehiZPnhzt6Qk5jwKdEOz+VBoLgYaLA64CjLp+\/\/vfi\/\/85z9GYzHCnjFjhsibN68cMek\/+BEjRogWLVpIN8hjjz1mjCpxDlwAEAC4UhDip17HMVKC8Nn5CN0INMpD+x566CH5Oo5XZWV4Df74448jgo\/kPzULNEaXuPZf\/OIX8sf\/9ttvG3WAB77zm4m5jXBPgC98w3BZ6W4uPCwh5hs2bAjhoT8c165dK91AyuAmgqvhyy+\/FE888YTxuf7WYw77xIi4d+\/e8lg7hmCkiyTcEh06dJBtxwNt2bJlRn04DqJqFmiINjjDBYPjzaGOcC+98MILcvSPh40ynLd\/\/\/6I90CQDqBAB6k3XLYlFgINv6aaAMKNP3HiRKNVGIFiJArbu3evaNy4sfGdiq6AKwD+T2UYSet\/wxWii9jy5cul7zGcuRFo+Lvh41aG9qGdyvBDj2RuBRqiD\/GHwVeq169G7X4zgQhD+JVh9IzJYvwXfad8r\/i+dOnSMkwQo16IuHo4wj+NUS8MPl1cNwwPVDxI8dCE7xouEmX47g9\/+IN49NFH5TWjHkzGwrDwCXMYMDuGiOVX7gkIJv5fTQ7iQabfCxiNL1iwII1AY85j4MCBsi7Ur7st0EbMkSiD+OsPZswxJNOkIQU60i82wN\/7LdDmEYb5h7ZmzRr5g4edOXNG\/OY3vzHoqMUv8B3qPsASJUqIX\/3qV8ZxWA2pr4hUI28\/BBo+1Bw5chhF6cKDD\/0WaLMYoI4yZcoYIojRNkaFfjOBAOnROzo7tAkTsHg4oC264SGqj1DxMMZKSCxiUsKNBUzoS9jly5dF2bJlLbsG9wpG1xjh1qpVKyTax06gdT4oWE1kqkr0h4u6H80jaMyHYISsrFq1asabHnzVM2fONL7Dm4J6EOHDI0eOSN96shgFOll6yqKdfgs0\/H6It1ZmfvVFdIQaJZkFWr3+vvHGG9LN4NQw0YVRjleBtnp9NQuS3wKtBFhvO0axyr+qvvebCeqDjxhvDHaGN5dXX33VGDGaR\/J4Q7r\/\/vtDRsmIvClevLhR7Pvvvy\/69u1rWw+u+Z133hF33XWXPC6cQJvfhpzcI+gzs0AjIqVp06bG6XCpqYe+eXWnWaDxm9FXhjppQyKPSTqBxk2GVy88uZMln0SsOjhIAo3RKl5\/p0+fLsaNG2dcMvrJKtxMHYCQNH2G3szKqYsjEQJttdTbSqD9ZqIYwT2A0Tkm\/NQI2MxPFzP4eeGeUA8QRN9AjDFHAMMkL8oyGwQSrqg\/\/\/nPIXMS+nF6JE84gUb96gGPc+Emga\/bzuAS81Ogjx49ahkSGqvfqNdyk06g9c6HTw1+RvzI7QLnvUIK6vlBFGiMsiHUyvRRdzQc04NA+80Er+kqXwhCCyGsiNZA+NqqVauMXCHgjd+G7vPXQxPxUIMLSvmEMVLWJ1YRLYLoFhji3H\/961\/LiUPUg0lHTMQqQ1lwMcG\/a+fiePrpp2WsOczqDcTqHqFAR\/PLSdA5iGW0SvSDzsaEBmJZo1lBlqDL8VRtkAT6j3\/8o4z6+Pzzz0MWoaBfpkyZYoxaMCLCxI+yd999NyRGN2gjaIR63XfffUazIi31thpB+80Ei4OUKwrC+K9\/\/cu45zEZWKpUKaO9+mQgPtyzZ4+xSMnMGhE1KvYY35kjLiD+etIt+IEh1sqUf9cs0DpDc7gfjlUx2ngYYBIRD2UYJgnxcPFToDlJ6ElynJ2MJ\/vf\/vY3AR+pOWAdN+xzzz0nGjZsKDs+mWZsnV39\/48KokCjdQjT01+VEf6GUC8kHtLjZzGhhR+v3RLfeI+gMRHao0cPAzJEAm4ADAowoRaNQPvNxOzTxkQeBidwIWAUq4c\/InxOD6G7ffu2HMSYU9dCeCHAumGErIepYY6iVatWkgPOV4uEcA4eTFg8A7Nj+NVXX4X4vHE8Yq0xqNLbjc\/hesHDyE+BdjIP4fZ3GMvjk87FYYaBySqIAUbW+gQXjoMw4IbCzatnJIsl0HiWHSSB1l+PEW6GGf5wflEwwoMUMbqRfJDxFuhwC1asVhI69UHjev1kgnC02rVrO1rsgd9F\/vz5Q25L88gYX5rDIfEZclngYeskfhyrJhFNAYvE0By+afWb0d+8KNDxVJUY1oVFFbiZMLLWX71QJSarED9pDj2yag5GGVhd5UdCdvgK\/\/vf\/8pXRzeJdJxgwmgUow9l4XJxQCj169bFVA9FixTFgbcWlZ\/BHMVh9l+CH2KorSINMHfw5ptvOprktWu72Z9qXoRgnsF3OnrCpB5erfUHjBLo+vXrG8vdrQRaD\/kyr170iwn6G30\/fPjwNEu21b0A3zP6VvWXfj\/BFYHvdTOnVVXf4QGJ+HfdLaWfh5WFiJYxr2y0Y4jzcS+99tprlptQIPQSS7bV26\/5PreL4jAzj\/YecPL7i8cxST+C1iEp14fVaFodp4LfwwnzvHnzpLCoHycmUTCxgVdcp\/GTGHnA74oHhf5Kj1nr119\/3RhpxKODE10HHlCYOUeeBuSywCo\/PRFOotsXrn4sgPj2229lbhK8fsMd41d4lp9MMDJHVBMiM1Q7Ed0E1namxyPjIT9r1izb4xETjZV56EcIJ95ICxQoIB8A4dyIkRjCJXPy5EnpwgBn3BvIl2IX9RPU+yVW7Up6gcbrFJ7GH3zwQRp\/NEaEiPLAUx7+tb\/\/\/e+SY7iRlNm3h\/NVSBJGp\/CJRfJpI\/0hYlTVggC8ysNnpy+ZnjZtmuNsbrHqeJabugTMy74RwwyXCS14BJJSoPEUx02GEarKwKWjRUwmXnUwg62PeiHQ8ElbCbT+2oe8AipdpDoH5Ztfray6E6uzMEkJw6saZroh6pg9xwo7ZIOD8OOVOVWiTYJ326dmi+B7xkSePljAvYil3dHkYk5NivG96qQTaMz0WqWpxHJTiDImp8IlLYfrAa9RVgKN5aOzZ8+WS1sR+qPnN1bfmUOWrLpK5Ukwx5\/iWH1lnr5sOr5dztpSlQBWFSKsUTfzsulUZRPU6046gdZjLCGmGC0j94CTKA3EiGJixSqpfevWreWEi9WWSvoSWYyE7XYGUXGeVuXA96iiFvAw0DOFBfUGYbtIgAQSRyDpBBqzzUiogqgMqxnqaFGq2Xer7Gp6li09ksGqLiSygd8aq67MS9F1odezoEXbZp5HAiSQvgkknUBD5DD6RLiTnjDFqpuQSQyrrBDjabebhr76ykqAMfGntkyCDw9B+W4NK5hefvll6f9DSkWUo7tR\/HzYuG0bjycBEggl4DQkM9bckk6glYtDTxBuBQkhPFigcvjwYYHQObvtjCCeCKWDhYsHVQKK1VPwdzs1bCQ6f\/58w60C\/zj8zyqHsCoH5WPFlzn9otN6eFziCahE9PrKvcS3ii1wQwBv5+hHCrQLalgEgSWiMCyQwDJTzD7bjToR6aFmq9WuEuGq1PdSg4sCMa+6IUZTpWCMlGBePw+5DRCMr2KhIexYXGEuH+fgWswJ510g4qEBIIAdVGB6\/uEANItNcEEAAzQskqFAu4DmZh84c7FY7o2l4HYhbfpqNavsa\/qebZF80KgfLhOE2KlVdGgDdhW2S6tJgXZxQwT0UDU\/whF0QDvIQbMo0A4gmQ+BWwErpmCIe8ZrCCI47NwB8O9itRSOUYnE7apWo3F9o091vL69E5YThwvjw\/FwrSCrm8pfgET2HTt2jBhnSoGO4sbgKSTgMwEKtEegTn3QbqvBqAdxylY5atUKQ+zcAH+ynek7UOgJZCK1hwIdiRC\/J4HYE6BAe2SMnADI7YC4Zz93VNFTK+oTgchzAJ8U3CD6pqkYKWPvM0R4YJms8lFjxLx69Wp5DmKuw5k5rwcF2uONwdNJwAcCFGiXEJEACdnlsK09XBXw737\/\/feOS8Ey60iJY5RrAnmAVU5aZFzDLi0qr7G+pQ+O1\/3Want4fK4nbLdrpHmykQLtuEt5IAnEjAAF2iVa5RtWqTTNiV6cFId8Gk5G2wiJwwjYnDgcbg\/ss6enC9Vjp5VAm1Nw2rUNM\/26D50C7aQneQwJxJYABdol33gKtGoacuBiMhC5O7CoxO88zlYIKNAubwweTgIxIECBdgkVPmD4e5XPGcuuVUy006JKly7tOJez0zL9Po4C7TdRlkcC7glQoN0zS4kzKNAp0c28yIAToEAHvIMS1TwKdKLIs14S+D8BCrTLuwGxx5iQ82KY9HOSjtRLHV7PpUB7JcjzScA7AQq0S4Z+ZHlzGsXhsmm+Hk6B9hUnCyOBqAhQoF1iw8pBhL95sYYNG8YlEsNLGynQXujxXBLwhwAF2h+O6a4UCnS661JeUBISoEAnYafFo8kU6HhQZh0kYE+AAu3yDkEi\/atXr4p69eqJfv36CfiTBw0a5KqUFStWcJLQFTEeTAKpSYAC7bLfE7GS0GUTfTmcI2hfMLIQEvBEgALtEh92Q7ly5YooWbKkqF69utzpAEnz3Rh2usiRI4ebU+J+LAU67shZIQmkIUCB5k1hSYACzRuDBBJPgAIdgz7AQhbsP5g7d26ZIjQZjQKdjL3GNqc3AhRon3r09OnT4q233pJbS3333XdGqdiOqkKFCqJDhw7SJYJ80MlgFOhk6CW2Mb0ToED70MMbN24U7du3j1gSBHrGjBmBX6SCC6FAR+xOHkACMSdAgfaIGK4MhN5hRxNYo0aN5G7Zd999t8zZcfLkSbFq1Sqxe\/du+X2DBg3EpEmTAj+SpkB7vDF4Ogn4QIAC7REiNmIdOnSoLGXp0qVyiykrQ\/THsGHD5FeI+vAjp4fHptueToGOJV2WTQLOCFCgnXEKe9TAgQPFkiVLRMuWLQ0BDncwRtf79u0L2ezVY\/UxO50CHTO0LJgEHBOgQDtGZX3g4MGDBfbzw2rCdu3a2ZbWpUsXub8gzmnbtq3HmmN7OgU6tnxZOgk4IUCBdkLJ5phFixaJIUOGCGzkOnXqVNvS1A7ba9asEdj2KshGgQ5y77BtqUKAAu2xp7Fzdu3ateUkIQQaQm027GGIEDz8y5MnjwD0jBkzeqw5tqdToGPLl6WTgBMCFGgnlLRjNmzYIJMl6bZt2zaxbNky+REiOGrWrCkKFCggLly4II4ePSq2b98ufc8wTBQ2b95cZM2a1WXN8T2cAh1f3qyNBKwIUKBd3BcYCRcrVszFGdaHckcVzwhZAAmkBAEKtItuhkBjT0Kvtnr1apE\/f36vxcT0fI6gY4qXhZOAIwIUaEeYUu8gCnTq9TmvOHgEKNBx7BMsUMGKQqQbLVy4sOOab9++Lc6dOyeyZcsmcubM6fi8cAf+8MMP4ubNmzKZUzijQHvGzAJIwDMBCrRnhD8XABE9deqUseTbqtg33nhDbNmyRUyePFku+Y5kKHPevHli4sSJRrklSpSQS8u7du0qMmfOHKmINN8j2qRMmTICSZz2799PgXZNkCeQQPwIUKB9YI1RcevWrW3FWa9m5syZMtojkkHQkVxJGUL0VKa8Zs2aidGjR7vO6YG6x4wZQ4GOBJ\/fk0AACFCgPXbC5cuXRdmyZR2X0qRJEymQkUa\/R44cEXXq1JHldu7cWXTr1k1kyZJF7oHYqlUr+fnYsWNF06ZNI9a9a9cucejQIXku0qHCOIKOiI0HkEDCCVCgPXbBypUrRZ8+faTg9ezZU1SuXFm0adNGjnSRIAmjXgjkuHHjZE1r164VRYoUiVjrqFGjxOzZs6X4ow59YYv6rmrVqnKZeSTD4pnDhw+HHEaBjkSN35NA4glQoD32gRJLuBwwMobBx4x\/cEFgUQps69atMqESfMjr1q2L6JqAywT+6v79+4uOHTuGtFKVhQ\/37Nkj7rzzTturWL9+veEa+fzzzwUy8FGgPXY8TyeBOBCgQHuE3L17dzkq1sVYjaqRPAlJlJTVr19fHDx4ULoZihYtaltztWrV5LZZy5cvFxUrVgw59vz588ZnblOXqs0FKNAeO56nk0AcCFCgPUKGAC9evFiMGDFChs\/BduzYIf8fO6jAzaFs+PDhYsGCBWL8+PECvuhwhkT\/pUqVkl9bCTBC5B5++GH5vV0Oaqvy3Qi0Oh8PIfyjkQAJxIeAegtXtR0\/fjw+FUeoJcNtxJYlkamoCPiKMdrFRB5GvhgBwxDKhtEqDJN7mKiDrxphcuHs2LFjMpQOhidovnz50hyqEv7PmTNH1KpVyzExNwINUYafu0qVKo7L54EkQALeCeB3D8NgD2JNgY6SKTaLrVGjhjz7nnvuEQMGDJAxztgkFq4MTNDB1aHin3FcpDhoxFMj4RIMiZZQrm7Xr18XxYsXlx9ZuUDsLsWNQOPNgOIc5Y3B00jABwJ0cfgAce7cudLFAVM7q2zevFlGc5gNUR0QbruJPbWYBOdigs+coAmrChEtAqMP2ocOZBEkEFACFGifOubTTz+VryPYLBb+ZfiJR44cKebPn2\/UUKhQITFt2jS5ki+SKReGVY7pvXv3isaNG8sidBdKpDLxPUfQTijxGBIIBgEKdIz74ezZswI+5Vy5comHHnpI+qidmIoOsdqpRa0wRGY9\/QHgpFwKtBNKPIYEgkGAAh2DfkAUBiYKkYwIwhyNbdq0ydjjUJ8IPHDggHjxxRflsvIJEyYIbEQLQypUTFhi5I4dXpSP2lw3BTqa3uA5JJAYAhRon7hjshBbWsG\/rPJloGhEcFSoUEFOGiLsLkOGDI5qhOD26NFDbjILg88ZYv\/RRx\/Jv+FGQbieMt1vbTcJSYF2hJ8HkUAgCFCgfegGJXqRioJAI\/lR9uzZIx0qv7927Zro1auXIdLqJLg9sHRcL0ePnXYi0GoJeriGMN2ooy7iQSQQUwIUaI944cpAzDJGsDC4HJCpDpOFEM2TJ0+KVatWyTzQMITgTZo0yfFIGudcunRJTgbeunVLriB0KvBeLo0C7YUezyUBfwhQoD1yRF6LoUOHylLsVvVhRSE2jIW5DY3z2MSoTqdAR4WNJ5GArwQo0B5xDhw4UCxZssSIf7YrDqNr7O6tT+55rD5mp1OgY4aWBZOAYwIUaMeorA8cPHiwTPmJnBxYMWhnXbp0kf5knNO2bVuPNcf2dAp0bPmydBJwQoAC7YSSzTGLFi0SQ4YMkUu6sajEzipVqiQjPNasWSNKly7tsebYnk6Bji1flk4CTghQoJ1QsjnmzJkzMu4Yk4RWq\/5wKkLmEIKHf4ieAHQ9Ab\/HJsTkdAp0TLCyUBJwRYAC7QqXEBs2bBBXr14NOWvbtm1i2bJl8jNEcCDRUYECBcSFCxfE0aNHZcIj+J5hmChEEv+sWbO6rDm+h1Og48ubtZGAFQEKtIv7AiNhc+IiF6cbhyLlaMGCBaM5NW7nUKDjhpoVkUBYAhRoFzcHBBr5L7za6tWrRf78+b0WE9PzKdAxxcvCScARAQq0I0ypdxAFOvX6nFccPAIU6Bj0CVb8IVoDOZ+D7msOd\/kU6BjcGCySBFwSoEC7BBbucCzrRp4NTCIePnzYOAy7oSD\/M3bmNm\/+6lPVMSmGAh0TrCyUBFwRoEC7wmV9MPI9Y\/eUr7\/+2rY05OxAwv7MmTP7UGtsi6BAx5YvSycBJwQo0E4o2RyDicOmTZsaYXTYnxAbyGLXbQi22mlFJVNq3769wPLwoBsFOug9xPalAgEKtMdextJtLOGGIWE+4qDNBp\/0lClT5D8Y0pMWKVLEY82xPZ0CHVu+LJ0EnBCgQDuhZHPMmDFjpDBjlxPsQWhnWKCya9cu8c4778jVh0E2CnSQe4dtSxUCFGiPPd2pUye5ywn2CXz++edtSxs1apSYPXu26Nmzp+jatavHmmN7OgU6tnxZOgk4IUCBdkLJ5hiVzc6J6Pbv318uCe\/cubPo3bu3x5pjezoFOrZ8WToJOCFAgXZCyeYY5ILGpF+hQoXEihUrRL58+SyPxp6FderUkUmVwvmqPTbF19Mp0L7iZGEkEBUBCnRU2P5\/kr7lVdGiReVGr5goVNtSXb9+Xe6gMnr0aBnVgU1kkVwJi1iCbBToIPcO25YqBCjQPvQ0kh+1atUqpCSkFc2SJYuAgOuWDKNntJcC7cONwSJIwCMBCrRHgOp0xDsjogNRGlZWokQJuZNKtWrVfKoxtsVQoGPLl6WTgBMCFGgnlFwcc+DAAfHVV1\/J3byRN\/q+++4T999\/vyhfvrzIlCmTi5ISeygFOrH8WTsJgAAF2uN9MHnyZLFp0ya5evC1117zWFpwTqdAB6cv2JLUJUCB9tj3r776qnj33XcFkiJh55T0YhTo9NKTvI5kJkCB9th7W7duFS1btpSlrFq1SpQrV85jicE4nQIdjH5gK1KbAAXah\/6fPn26GDdunNwQFisKsetKEDPW3b59W5w7d05ky5ZN5MyZ0\/bKKdA+3BgsggQ8EqBAewSIxEfYrXvv3r0hJUGswxkSLIVb0OKxOZanQ5jnzZsnJk6cKBfKwBBVgvSnWHJu9TChQMeiJ1gmCbgjQIF2xyvN0StXrhR9+vRxVUq8N43FqB6bCSjDwwM7vsCaNWsmF9FkyJAh5Boo0K66lAeTQEwIUKA9Yv3yyy\/Fjh07XJXSsGFDY6WhqxOjOPjIkSNyiTkMOUC6desmF9Doi2vGjh0rc1rrRoGOAjZPIQGfCVCgfQYatOJUBj2EAWK0nzFjRqOJ6ruqVauK9957L41A4\/MqVap4viTcZH6Z24ehH\/WCgxPzgxXqcVIf0ts6te7du9seilDReBvaZHed6Gc\/7xv0TSSuTu8tv9oQsY\/CAAANIklEQVTltD70zfHjx+PdRZb1ZbgNh2kSGRajwIK6OWzr1q3Fli1bBDLpYV9E3fQIlD179oTkB8EIOu8DZSP2xLnj+yIegwNKPP2S7XGHP\/qTrC\/vg+HrPHdsn0B9Tssq\/vTvwtb53fH9AnX+ptMbtu3aNqOf\/D4SC6ccIpWDupyWBQ55HigTtv2ff7RIlhWpThwTiQPKkhwc9E+kshRTJzeO076OVJZTpk5YOb0fnLbdCVMKdKQe1r5HAiT4dBFWd+LECfkNEiW98MILMuQuSGKNpeXIB7J8+fI0m9aeP3\/e+AwJnSDKyvD\/+KHZ3bCf\/22RgGhG+kH+ud8zEctSP1q7svAjw3EN3\/hLRFHFTV\/8qfAC7bQstB0\/NLuywAFiH6ldTjiQ6c9dS6Y\/c1D3KQXaoUDfvHlTtGjRImzODezcvXjx4kCE2WGn8VKlSskrMwswPsO1YO9E2NKlS0WlSpVCBNohEh5GAiQQYwIUaIeAIWQDBgyQR2P1YK1atWRcMXZVUbt69+3bV7zyyisOS4zdYdhtHKF0MPjNrEL71Kh5zpw58lqU+eVni93VsWQSSB0Cfs1veCUWeB+08ukiQT8m3fLmzSuv+fLly6Jx48YCoohRNFwKibZTp06JmjVrymZgGToeKLrBVVO8eHH5kZULJNHtZ\/0kQALBIhB4gYYbADHEvXr1MnbzVgjffPNNMW3aNJmUf9++fWlii+ONGotSypT5eRJp\/fr1olixYiFNwKrCypUry8+sXCDxbi\/rIwESCDaBwAu0cglY7cyNUepLL\/0crYD44yAs91btnTp1qqhbt25I72P1I0b9sP3798sHC40ESIAEwhFIGoHGRKDZLwRHPra7CpJAI9507dq1Upwh0rqpFYbIHTJ\/\/nzelSRAAiRgS4AC7fMNglzV7dq1k6XqE4HYWACLHeAGmTBhgmjUqJHPNbM4EiCB9EaAAu1zj964cUNuZIsETTD4nHPlyiWjTmBNmjQR48eP97lWFkcCJJAeCVCgY9Cr165dk5OaSqRVFXB7IE2q2oFcfQ5RxwTiXXfdFahFNzFAk66LdJNeNl2DSOKLO3PmjLhy5YooXLhwIOa0kkagsXLQnFMZ7gKE2cGQ+8LKkDVu1qxZRnhePO+dS5cuycnAW7duyVBAszBfvHhRIBIFO8QoQ9QKXCF0gcSzp\/ypCxsYN2\/eXPYd3Fi05CCA3+GwYcNkQjOVdRItr1Gjhnj99dflPqeJsqQRaC+A4p1u1ElbkVMEy9TVruRISYont8ofDeFWER9OyuMxiSWAVaJYLPXxxx9ToBPbFa5qR\/qFl19+WRw8eFCeZ\/4d4rPNmzfLEXUiLPAC3aVLF7koxYthNJM7d24vRfh+LrLZDR48WJY7c+ZM8eSTT8ql4AgnVKMvxkr7jt3XAuGa+uSTT8QXX3wh1q1bZ\/zIOYL2FXNMC8PvDel\/EfK6cOFCUaFCBQEXJRKeqWRnVhFZMW2UVnjgBTpeIOJdDzr98OHDolOnTqJfv58zuMHgDnn22Wflj71nz55yBxZaMAnoya\/0FlKgg9lfVq3q0KGDfOuBi0PtdaqOGzRokMzzAzt69GhI6uB4XSEFOl6ktXr0pElYvl6+fPmQVkyaNElMmTJFlCxZUnzwwQcJaCGrdEIAI+hly5YJlbH3r3\/9q0BKWQq0E3qJPwaDIWw6Dbei1e8Qb7BqFG1ODxyv1lOg40VaqwdJnrBYBYbX40yZMoW0Qt0YeO3CJCMtOQiohUgU6OToLwyU8FDFf2vXrp0mggp7imL\/U\/il1VxRvK+MAh1v4kLIURZep8IJsIoGQNOCsoQ9AZiSrkoKdNJ1WdgG66NnbF3Xu3fvhFwcBToB2JcsWSIGDhwoNx2A\/8tsWHUIPzQM+TvM4YUJaDKrdECAAu0AUsAP+f777+WkIVxXMLhA8HtN1KYgFOgE3DBqZ3KkUMVssdl27twpd4uBJWpyIgFYkr5KCnTydiHmExBZhYVkKtS1ffv2cuScKHEGTQp0Au4ptcN3OBfHhg0bZExtIn1fCcCS9FVSoJOzC0+fPi3TM+zevVteQPXq1eUmIY888kjCL4gCnYAuOHTokKhXr56s2SqxP1Y+jh49Wm6JhR1laMlBgAKdHP2kt\/Ls2bOiYcOGch9RDJgwgq5Tp05gLoQCnYCuwOvUo48+KpeVYinp734Xutlq\/fr1ZRw0nuKI06QlBwEKdHL0k97KPn36yBA7iPPGjRstt6lL5FVRoBNEX\/2YcWMg053aHgtbYamFK5hAxEQiLTkIUKCTo5\/0VqodmyZPniyeeeYZywtAPh9zKGy8rpQCHS\/SpnrwaoWJwBMnTshvsNkskivt2LFD\/o2Z5KZNmyaodaw2GgIU6GioJe4c\/PaQYsGJJSrclQLtpHdidMw333wjWrVqZWTkQzUYUWP2GDuz0JKLgBJo5vxOjn7DzkdOf2dIy3DHHXfE\/cIo0HFHnrZC5KDFxCESOpUuXToQeWgDgIVNIIGUJ0CBTvlbgABIgASCSoACHdSeYbtIgARSngAFOuVvAQIgARIIKgEKdFB7hu0iARJIeQIU6JS\/BQiABEggqAQo0EHtGbaLBEgg5QlQoFP+FiAAEiCBoBKgQAe1Z9guEiCBlCdAgU75WyA1APz0009R7Q6fK1cucfXqVXHlyhWRI0cOkT179tQAxqsMBAEKdCC6gY2INYHp06fLVJJuDTlRsIEv9pHs37+\/sYmo23J4PAlEQ4ACHQ01npN0BN5++20xfvx41+1GXu5p06ZRoF2T4wl+EKBA+0GRZQSeAPaaO3\/+fJp2IqMg8nJXrFhRjBkzJs33+fLlEx9++KHA+VWqVJHH0UggXgQo0PEizXoCSaBu3boCmcpq1KghFixYEMg2slGpS4ACnbp9zysXQjgRaGw7dvHiRblXndqnbtOmTXLH9QcffFA89dRTAvtMYkcObJ30xBNPyH\/YFBij9jVr1ohdu3bJUXj58uVlYvgyZcpY8t+\/f7\/YvHmz2Ldvn7h586aoUKGCHLkjsTwt9QhQoFOvz3nFGgEnAv3YY4+l8UEPHjxY7gIN0YZ4Q1DNhhH5sGHDjE0Z9O+xc47uLrl165aYMWNG2InM1q1bi4EDBzIVbYrdvRToFOtwXm4oAa8CrUpr0KCBePzxxwV23oDQ6oZdO\/AP382fP19+VblyZbFkyRLjsLlz54oRI0bIv\/FAeO6558T169flqBw+cFizZs0s\/eTs0\/RLgAKdfvuWV+aAgB8CjV059J05unbtKtatWydrb9mypRxFK8P\/L1y4UO6cg1E39ruD66NmzZrixx9\/lNugjRw5Un6ubNSoUWL27Nnyz507d4q8efM6uDIekh4IUKDTQy\/yGqIm4IdAf\/bZZyELWPSQPvimCxYsaLQPf2ObM9jWrVvFvffeKwVbiTj82jlz5gy5HuxfCT80DKPsFi1aRH29PDG5CFCgk6u\/2FqfCXgV6BIlShguCNU0uC7gL4YdPXpUZMyY0Wg1JgubN28u\/4b7okiRIlKc1agao2cr69Gjh\/y4TZs2YsiQIT5TYHFBJUCBDmrPsF1xIeBVoOFbnjVrVkhblUDDjYGoDN2sBBpuEIymnRj90E4opZ9jKNDppy95JVEQ8CrQTz\/9dJpJQbcCDZcHXB+wnj172l5F2bJlpb+alhoEKNCp0c+8yjAEgiDQw4cPNxbJYOIQSZnMBj\/0jRs3pH\/a6nt2cPokQIFOn\/3Kq3JIIAgCvWjRIsOvPHPmTLnwRbcTJ07IMD3Y1KlT5eIaWmoQoECnRj\/zKgM8gsZCFwgwcoKUK1dO+rRVKN23334rELYH3zV82jt27JD\/paUGAQp0avQzrzLAAo2mIW4aQgyDAGOJ97Vr1wRC+BAfDbMaXbNj0zcBCnT67l9eXQQC9evXFwcPHrRNloTRLdwMej5oFRpnNUn4\/vvvi759+4o8efLIka9uVlEc6vvt27fLBS8YSetWtGhR0adPH5nDg5ZaBCjQqdXfvNqAE8Co+dixY+LQoUMiS5YsMuES3B56LHXAL4HN85EABdpHmCyKBEiABPwkQIH2kybLIgESIAEfCVCgfYTJokiABEjATwIUaD9psiwSIAES8JEABdpHmCyKBEiABPwkQIH2kybLIgESIAEfCVCgfYTJokiABEjATwIUaD9psiwSIAES8JEABdpHmCyKBEiABPwkQIH2kybLIgESIAEfCVCgfYTJokiABEjATwIUaD9psiwSIAES8JEABdpHmCyKBEiABPwkQIH2kybLIgESIAEfCVCgfYTJokiABEjATwIUaD9psiwSIAES8JEABdpHmCyKBEiABPwkQIH2kybLIgESIAEfCVCgfYTJokiABEjATwIUaD9psiwSIAES8JEABdpHmCyKBEiABPwkQIH2kybLIgESIAEfCVCgfYTJokiABEjATwIUaD9psiwSIAES8JEABdpHmCyKBEiABPwkQIH2kybLIgESIAEfCfwP3S\/ODqCZr2IAAAAASUVORK5CYII=","height":70,"width":117}}
%---
%[output:36c09a93]
%   data: {"dataType":"text","outputData":{"text":"\n--- Theoretical Values ---\n","truncated":false}}
%---
%[output:8f9fd217]
%   data: {"dataType":"text","outputData":{"text":"L  = -1.1852\n","truncated":false}}
%---
%[output:15d60b95]
%   data: {"dataType":"text","outputData":{"text":"Lq = -7.5852\n","truncated":false}}
%---
%[output:65a56c73]
%   data: {"dataType":"text","outputData":{"text":"W  = -1.4815 hours (-88.89 minutes)\n","truncated":false}}
%---
%[output:59dfe1f9]
%   data: {"dataType":"text","outputData":{"text":"Wq = -9.4815 hours (-568.89 minutes)\n","truncated":false}}
%---
%[output:3af794fe]
%   data: {"dataType":"text","outputData":{"text":"\n--- Simulation Comparison ---\n","truncated":false}}
%---
%[output:6a3c659c]
%   data: {"dataType":"text","outputData":{"text":"Simulated mean number in system = 7.5846\n","truncated":false}}
%---
%[output:90d5630e]
%   data: {"dataType":"text","outputData":{"text":"Simulated mean time in system   = 9.3664 hours\n","truncated":false}}
%---
%[output:8ac810f8]
%   data: {"dataType":"text","outputData":{"text":"Percent discrepancy for L = -739.95%n","truncated":false}}
%---
%[output:72878adc]
%   data: {"dataType":"text","outputData":{"text":"Percent discrepancy for W = -732.23%n","truncated":false}}
%---
%[output:8811ab3f]
%   data: {"dataType":"text","outputData":{"text":"\n==============================\n","truncated":false}}
%---
%[output:5485326b]
%   data: {"dataType":"text","outputData":{"text":"        FINAL ANSWERS\n","truncated":false}}
%---
%[output:6521b782]
%   data: {"dataType":"text","outputData":{"text":"==============================\n","truncated":false}}
%---
%[output:9223c91e]
%   data: {"dataType":"text","outputData":{"text":"\n--- THEORETICAL (M\/M\/1) ---\n","truncated":false}}
%---
%[output:9b01d036]
%   data: {"dataType":"text","outputData":{"text":"L  (avg # in system): -1.1852\n","truncated":false}}
%---
%[output:41b01363]
%   data: {"dataType":"text","outputData":{"text":"Lq (avg # waiting)  : -7.5852\n","truncated":false}}
%---
%[output:25d27bb9]
%   data: {"dataType":"text","outputData":{"text":"W  (time in system) : -1.4815 hours (-88.89 min)\n","truncated":false}}
%---
%[output:85ef9ae9]
%   data: {"dataType":"text","outputData":{"text":"Wq (waiting time)   : -9.4815 hours (-568.89 min)\n","truncated":false}}
%---
%[output:76ec64d8]
%   data: {"dataType":"text","outputData":{"text":"\n--- SIMULATION ---\n","truncated":false}}
%---
%[output:736d781a]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 7.5846\n","truncated":false}}
%---
%[output:3a1d9ac8]
%   data: {"dataType":"text","outputData":{"text":"Mean time in system  : 9.3664 hours (561.99 min)\n","truncated":false}}
%---
%[output:1282cfe8]
%   data: {"dataType":"text","outputData":{"text":"\n--- DISCREPANCY ---\n","truncated":false}}
%---
%[output:691c3a0e]
%   data: {"dataType":"text","outputData":{"text":"L difference: -739.95%n","truncated":false}}
%---
%[output:2bb309dc]
%   data: {"dataType":"text","outputData":{"text":"W difference: -732.23%n","truncated":false}}
%---
%[output:13c79e5f]
%   data: {"dataType":"text","outputData":{"text":"==============================\n","truncated":false}}
%---
