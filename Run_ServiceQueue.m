%[text] # Run samples of the ServiceQueue simulation William Greeley
%[text] Collect statistics and plot histograms along the way.
%%
%[text] ## Set up
%[text] We'll measure time in minutes
%[text] Arrival rate: 1 customer every 75 seconds 
% 1 / (1+(15/60))
lambda = 0.8;
%[text] Departure (service) rate: 1 customer every 6.5 minutes 
mu = 1/6.5;
%[text] Number of serving stations
s = 2; 
%s = 8; this is the maximum amount of servers 
%[text] Run 100 samples of the queue.
NumSamples = 100;
%[text] Each sample is run up to a maximum time.
MaxTime = 240;
%[text] Make a log entry every so often
LogInterval = 5;
%%
%[text] ## Numbers from theory for M/M/k queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term. Note that this calculation assumes $s=1$. \*\*Need to update P\_n so that it works for any number of serving stations 
nMax = 10;
%utilization factor rho 
rho = lambda / (s*mu);
ratio = lambda/mu;
Part_A = 0;
% to sum from n = 0 to k-1
for n = 0: (s-1)
    term = (1 / factorial(n)) * (ratio^n);
    Part_A = Part_A + term;
end 
Part_B = (1 / factorial(s)) * (ratio^s) * (1 / (1 - rho));
P0 = 1 / (Part_A + Part_B);

for n = 0 : nMax %[output:group:2e664a0b]
if n == 0
    Pn = P0;
elseif n <= s 
    Pn = (1 / factorial(n)) * (ratio^n) * P0;
else
    denominator = factorial(s) * (s^(n - s));
    Pn = (1 / denominator) * (ratio^n) * P0;
end 
fprintf('%d\t\t%.4f\n', n, Pn); %[output:2600c049]
end %[output:group:2e664a0b]
%%
%[text] ## Run simulation samples
%[text] This is the most time consuming calculation in the script, so let's put it in its own section.  That way, we can run it once, and more easily run the faster calculations multiple times as we add features to this script.
%[text] Reset the random number generator.  This causes MATLAB to use the same sequence of pseudo-random numbers each time you run the script, which means the results come out exactly the same.  This is a good idea for testing purposes.  Under other circumstances, you probably want the random numbers to be truly unpredictable and you wouldn't do this.
rng("default");
%[text] We'll store our queue simulation objects in this list.
QSamples = cell([NumSamples, 1]);
%[text] The statistics come out weird if the log interval is too short, because the log entries are not independent enough.  So the log interval should be long enough for several arrival and departure events happen.
for SampleNum = 1:NumSamples %[output:group:08a541c0]
    fprintf("Working on sample %d\n", SampleNum); %[output:4cd6552e]
    q = ServiceQueue( ...
        ArrivalRate=lambda, ...
        DepartureRate=mu, ...
        NumServers=s, ...
        LogInterval=LogInterval);
    q.schedule_event(Arrival(random(q.InterArrivalDist), Customer(1)));
    run_until(q, MaxTime);
    QSamples{SampleNum} = q;
end %[output:group:08a541c0]
%%
%[text] ## Collect measurements of how many customers are in the system
%[text] Count how many customers are in the system at each log entry for each sample run.  There are two ways to do this.  You only have to do one of them.
%[text] ### Option one: Use a for loop.
NumInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end
%[text] ### Option two: Map a function over the cell array of ServiceQueue objects.
%[text] The `@(q) ...` expression is shorthand for a function that takes a `ServiceQueue` as input, names it `q`, and computes the sum of two columns from its log.  The `cellfun` function applies that function to each item in `QSamples`. The option `UniformOutput=false` tells `cellfun` to produce a cell array rather than a numerical array.
NumInSystemSamples = cellfun( ...
    @(q) q.Log.NumWaiting + q.Log.NumInService, ...
    QSamples, ...
    UniformOutput=false);
%[text] ## Join numbers from all sample runs.
%[text] `vertcat` is short for "vertical concatenate", meaning it joins a bunch of arrays vertically, which in this case results in one tall column.
NumInSystem = vertcat(NumInSystemSamples{:});
%[text] MATLAB-ism: When you pull multiple items from a cell array, the result is a "comma-separated list" rather than some kind of array.  Thus, the above means
%[text] `NumInSystem = vertcat(NumInSystemSamples{1}, NumInSystemSamples{2}, ...)`
%[text] which concatenates all the columns of numbers in NumInSystemSamples into one long column.
%[text] This is roughly equivalent to "splatting" in Python, which looks like `f(*args)`.
%%
%[text] ## Pictures and stats for number of customers in system
%[text] Print out mean number of customers in the system.
meanNumInSystem = mean(NumInSystem);
fprintf("Mean number in system: %f\n", meanNumInSystem); %[output:888ec210]
%[text] Make a figure with one set of axes.
fig = figure(); %[output:44eba467]
t = tiledlayout(fig,1,1); %[output:44eba467]
ax = nexttile(t); %[output:44eba467]
%[text] MATLAB-ism: Once you've created a picture, you can use `hold` to cause further plotting functions to work with the same picture rather than create a new one.
hold(ax, "on"); %[output:44eba467]
%[text] Start with a histogram.  The result is an empirical PDF, that is, the area of the bar at horizontal index n is proportional to the fraction of samples for which there were n customers in the system.  The data for this histogram is counts of customers, which must all be whole numbers.  The option `BinMethod="integers"` means to use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so that the height of the first bar is proportional to the count of 0s in the data, the height of the second bar is proportional to the count of 1s, etc. MATLAB can choose bins automatically, but since we know the data consists of whole numbers, it makes sense to specify this option so we get consistent results.
h = histogram(ax, NumInSystem, Normalization="probability", BinMethod="integers"); %[output:44eba467]
%[text] Plot $(0, P\_0), (1, P\_1), \\dots$.  If all goes well, these dots should land close to the tops of the bars of the histogram.
plot(ax, 0:nMax, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r'); %[output:7340f42c]
%[text] Add titles and labels and such.
title(ax, "Number of customers in the system");
xlabel(ax, "Count");
ylabel(ax, "Probability");
legend(ax, "simulation", "theory");
%[text] Set ranges on the axes. MATLAB's plotting functions do this automatically, but when you need to compare two sets of data, it's a good idea to use the same ranges on the two pictures.  To start, you can let MATLAB choose the ranges automatically, and just know that it might choose very different ranges for different sets of data.  Once you're certain the picture content is correct, choose an x range and a y range that gives good results for all sets of data.  The final choice of ranges is a matter of some trial and error.  You generally have to do these commands *after* calling `plot` and `histogram`.
%[text] This sets the vertical axis to go from $0$ to $0.3$.
ylim(ax, [0, 0.3]);
%[text] This sets the horizontal axis to go from $-1$ to $21$.  The histogram will use bins $(-0.5, 0.5), (0.5, 1.5), \\dots$ so this leaves some visual breathing room on the left.
xlim(ax, [-1, 21]);
%[text] MATLAB-ism: You have to wait a couple of seconds for those settings to take effect or `exportgraphics` will screw up the margins.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Number in system histogram.pdf");
%%
%[text] ## Collect measurements of how long customers spend in the system
%[text] This is a rather different calculation because instead of looking at log entries for each sample `ServiceQueue`, we'll look at the list of served  customers in each sample `ServiceQueue`.
%[text] ### Option one: Use a for loop.
TimeInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % The next command has many parts.
    %
    % q.Served is a row vector of all customers served in this particular
    % sample.
    % The ' on q.Served' transposes it to a column.
    %
    % The @(c) ... expression below says given a customer c, compute its
    % departure time minus its arrival time, which is how long c spent in
    % the system.
    %
    % cellfun(@(c) ..., q.Served') means to compute the time each customer
    % in q.Served spent in the system, and build a column vector of the
    % results.
    %
    % The column vector is stored in TimeInSystemSamples{SampleNum}.
    TimeInSystemSamples{SampleNum} = ...
        cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served');
end

%[text] ### Option two: Use `cellfun` twice.
%[text] The outer call to `cellfun` means do something to each `ServiceQueue` object in `QSamples`.  The "something" it does is to look at each customer in the `ServiceQueue` object's list `q.Served` and compute the time it spent in the system.
TimeInSystemSamples = cellfun( ...
    @(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);
%[text] ### Join them all into one big column.
TimeInSystem = vertcat(TimeInSystemSamples{:});
%%
%[text] ## Pictures and stats for time customers spend in the system
%[text] Print out mean time spent in the system.
meanTimeInSystem = mean(TimeInSystem);
fprintf("Mean time in system: %f\n", meanTimeInSystem);
%[text] Make a figure with one set of axes.
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
%[text] This time, the data is a list of real numbers, not integers.  The option `BinWidth=...` means to use bins of a particular width, and choose the left-most and right-most edges automatically.  Instead, you could specify the left-most and right-most edges explicitly.  For instance, using `BinEdges=0:0.5:60` means to use bins $(0, 0.5), (0.5, 1.0), \\dots$
h = histogram(ax, TimeInSystem, Normalization="probability", BinWidth=5/60);
%[text] Add titles and labels and such.
title(ax, "Time in the system");
xlabel(ax, "Time");
ylabel(ax, "Probability");
%[text] Set ranges on the axes.
ylim(ax, [0, 0.2]);
xlim(ax, [0, 2.0]);
%[text] Wait for MATLAB to catch up.
pause(2);
%[text] Save the picture as a PDF file.
exportgraphics(fig, "Time in system histogram.pdf");
%[text] ## Part A 
% L = (lambda / (mu-lambda));
% LsubQ = (lambda / (mu-lambda)) - (lambda / mu);
% W = (1 / (mu - lambda));
% WsubQ = (lambda / (mu*(mu-lambda)));
% actualWaitTime= meanTimeInSystem - (1/mu);
%[text] Express Discrepency as Percentage of Theoretical Value
% discrepancyL = 100 - ((meanNumInSystem / L) * 100);
% discrepencyLsubQ = 100 - (((meanNumInSystem-1) / LsubQ) * 100);
% disceprencyW = 100 - ((meanTimeInSystem / W) * 100);
% discrepencyWsubQ = (abs(actualWaitTime - WsubQ) / WsubQ) * 100;
% disp(discrepancyL)
% disp(discrepencyLsubQ)
% disp(disceprencyW)
% disp(discrepencyWsubQ)
%[text] ## Part B (see addtional changes in setup section)
%[text] Arrival Rate ($\\lambda${"editStyle":"visual"}) = 40, Service Rate ($\\left.\\mu \\right)${"editStyle":"visual"}= 30, $\\rho =${"editStyle":"visual"}$\\frac{\\lambda }{s\\mu }=\\frac{40}{60}${"editStyle":"visual"}, s = 2
%[text] 3a.) To find $P\_{0,\\;}${"editStyle":"visual"} must use equation $\\sum\_{n=0}^{\\infty } P\_n =1${"editStyle":"visual"}, this yeilds $P\_{0\\;} =\\frac{1-\\frac{\\lambda }{\\mu\_2 }}{1+\\frac{\\lambda }{\\mu\_2 }}${"editStyle":"visual"}, where $\\mu\_2${"editStyle":"visual"}denotes $2\\mu${"editStyle":"visual"}.
%[text]  for each other probability, use equation  $P\_n =2{\\left(\\frac{\\lambda }{\\mu\_2 }\\right)}^n P\_0 \\;\\;\\;,\\;\\;\\;n\\ge 1${"editStyle":"visual"}
%[text] n = 0, $P\_{0\\;} =\\frac{1-\\frac{\\lambda }{\\mu\_2 }}{1+\\frac{\\lambda }{\\mu\_2 }}${"editStyle":"visual"} $=\\frac{1-\\frac{40}{60}}{1+\\frac{40}{60}}${"editStyle":"visual"} $=\\frac{\\frac{1}{3}}{\\frac{5}{3}}${"editStyle":"visual"} = 0.2
%[text] n = 1, $P\_1 =2{\\left(\\frac{40}{60}\\right)}^1 \\cdot 0\\ldotp 2${"editStyle":"visual"} = 0.2667
%[text] n = 2, $P\_2 =2{\\left(\\frac{40}{60}\\right)}^2 \\cdot 0\\ldotp 2${"editStyle":"visual"}  = 0.1778
%[text] n = 3, $P\_3 =2{\\left(\\frac{40}{60}\\right)}^3 \\cdot 0\\ldotp 2${"editStyle":"visual"} = 0.1185
%[text] n = 4,  $P\_4 =2{\\left(\\frac{40}{60}\\right)}^4 \\cdot 0\\ldotp 2${"editStyle":"visual"}  = 0.0790
%[text] n = 5,  $P\_5 =2{\\left(\\frac{40}{60}\\right)}^5 \\cdot 0\\ldotp 2${"editStyle":"visual"}  = 0.0527
%[text] 3b.)
%[text] L = $\\frac{\\frac{\\lambda }{\\mu }}{\\left(1-\\frac{\\lambda }{\\mu\_2 }\\right)\\left(1+\\frac{\\lambda }{\\mu\_2 }\\right)}${"editStyle":"visual"} = $\\frac{\\frac{4}{3}}{\\left(1-\\frac{4}{6}\\right)\\left(1+\\frac{4}{6}\\right)}${"editStyle":"visual"} = 12/5
%[text] 3c.)
%[text] $L\_{q\\;} =\\lambda W\_q${"editStyle":"visual"} = 40(0.02667) = 1.0667
%[text] 3d.)
%[text] W = $\\frac{1}{\\left(\\mu -\\frac{\\lambda }{2}\\right)\\left(1+\\frac{\\lambda }{\\mu\_2 }\\right)}${"editStyle":"visual"} = $\\frac{1}{\\left(30-\\frac{40}{2}\\right)\\left(1+\\frac{40}{60}\\right)}${"editStyle":"visual"} = 3/50 hrs.
%[text] 3e.)
%[text] $W=W\_q +\\frac{1}{\\mu }${"editStyle":"visual"} $\\Longrightarrow W\_q =W-\\frac{1}{\\mu }${"editStyle":"visual"} by using this fomula, $W\_q =\\frac{3}{50}-\\frac{1}{30}${"editStyle":"visual"} = 0.02667 hrs.
%[text] 4a.)
%[text] Generate Histogram for P(finding n customers in system)
% histogram for the probability of finding n customers in the system with 
fig_bank1 = figure();
ax_bank1 = axes(fig_bank1);
hold(ax_bank1, "on");
histogram(ax_bank1, NumInSystem, 'Normalization', 'probability', 'BinMethod', 'integers');
n_vals = 0:5;
ProbabilityOfnCustomers = [0.2, 0.2667, 0.1778, 0.1185, 0.079, 0.0527];
plot(ax_bank1, n_vals, ProbabilityOfnCustomers, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Theory');
title(ax_bank1, 'Probability of n Customers (Bank Simulation)');
xlabel(ax_bank1, 'Number of Customers (n)');
ylabel(ax_bank1, 'Probability');
legend(ax_bank1, 'Simulation', 'Theory');
xlim(ax_bank1, [-1, 10]);
hold(ax_bank1, "off");
%[text] 4b.)
%[text] Generate Histogram of Total Time Customers Spend in System
h3 = histogram(TimeInSystem, 'Normalization', 'probability');
title('Total Time Customers Spend in the System');
xlabel('Time in System');
ylabel('Probability');
xlim([0, max(TimeInSystem)]);
%[text] 5\.)
%[text] The simulation matches quite closely with the theoretical results. All error was under 3% roughly. 
L = mean(NumInSystem)
W = mean(TimeInSystem)
W_q = W - (1/mu)
L_q = lambda * W_q
%[text] For this round of simulation, my values were as follows:
%[text]  L = 2.4112 ,L\_q = 1.0882 , W = 0.0605 , W\_q = 0.0272
%[text] Discrepancy:
%[text] $L=\\;\\frac{\\mathrm{simulated}-\\mathrm{theoretical}}{\\mathrm{theoretical}}\\cdot 100${"editStyle":"visual"} = $\\frac{2\\ldotp 4112-2\\ldotp 4}{2\\ldotp 4}\\cdot 100${"editStyle":"visual"} = 0.46%
%[text] $L\_q =\\;${"editStyle":"visual"}$\\frac{\\mathrm{simulated}-\\mathrm{theoretical}}{\\mathrm{theoretical}}\\cdot 100${"editStyle":"visual"} = $\\frac{1\\ldotp 0882-1\\ldotp 0667}{1\\ldotp 0667}\\cdot 100${"editStyle":"visual"} = 2.02%
%[text] $W=\\;\\frac{\\mathrm{simulated}-\\mathrm{theoretical}}{\\mathrm{theoretical}}\\cdot 100${"editStyle":"visual"} = $\\frac{0\\ldotp 0605-0\\ldotp 06}{0\\ldotp 06}\\cdot 100${"editStyle":"visual"} = 0.83%
%[text] $W\_q =\\;\\frac{\\mathrm{simulated}-\\mathrm{theoretical}}{\\mathrm{theoretical}}\\cdot 100${"editStyle":"visual"} = $\\frac{0\\ldotp 0272-0\\ldotp 0267}{0\\ldotp 0267}\\cdot 100${"editStyle":"visual"} = 1.87%

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:2600c049]
%   data: {"dataType":"text","outputData":{"text":"0\t\t0.8246\n1\t\t0.1586\n2\t\t0.0152\n3\t\t0.0015\n4\t\t0.0001\n5\t\t0.0000\n6\t\t0.0000\n7\t\t0.0000\n8\t\t0.0000\n9\t\t0.0000\n10\t\t0.0000\n","truncated":false}}
%---
%[output:4cd6552e]
%   data: {"dataType":"text","outputData":{"text":"Working on sample 1\nWorking on sample 2\nWorking on sample 3\nWorking on sample 4\nWorking on sample 5\nWorking on sample 6\nWorking on sample 7\nWorking on sample 8\nWorking on sample 9\nWorking on sample 10\nWorking on sample 11\nWorking on sample 12\nWorking on sample 13\nWorking on sample 14\nWorking on sample 15\nWorking on sample 16\nWorking on sample 17\nWorking on sample 18\nWorking on sample 19\nWorking on sample 20\nWorking on sample 21\nWorking on sample 22\nWorking on sample 23\nWorking on sample 24\nWorking on sample 25\nWorking on sample 26\nWorking on sample 27\nWorking on sample 28\nWorking on sample 29\nWorking on sample 30\nWorking on sample 31\nWorking on sample 32\nWorking on sample 33\nWorking on sample 34\nWorking on sample 35\nWorking on sample 36\nWorking on sample 37\nWorking on sample 38\nWorking on sample 39\nWorking on sample 40\nWorking on sample 41\nWorking on sample 42\nWorking on sample 43\nWorking on sample 44\nWorking on sample 45\nWorking on sample 46\nWorking on sample 47\nWorking on sample 48\nWorking on sample 49\nWorking on sample 50\nWorking on sample 51\nWorking on sample 52\nWorking on sample 53\nWorking on sample 54\nWorking on sample 55\nWorking on sample 56\nWorking on sample 57\nWorking on sample 58\nWorking on sample 59\nWorking on sample 60\nWorking on sample 61\nWorking on sample 62\nWorking on sample 63\nWorking on sample 64\nWorking on sample 65\nWorking on sample 66\nWorking on sample 67\nWorking on sample 68\nWorking on sample 69\nWorking on sample 70\nWorking on sample 71\nWorking on sample 72\nWorking on sample 73\nWorking on sample 74\nWorking on sample 75\nWorking on sample 76\nWorking on sample 77\nWorking on sample 78\nWorking on sample 79\nWorking on sample 80\nWorking on sample 81\nWorking on sample 82\nWorking on sample 83\nWorking on sample 84\nWorking on sample 85\nWorking on sample 86\nWorking on sample 87\nWorking on sample 88\nWorking on sample 89\nWorking on sample 90\nWorking on sample 91\nWorking on sample 92\nWorking on sample 93\nWorking on sample 94\nWorking on sample 95\nWorking on sample 96\nWorking on sample 97\nWorking on sample 98\nWorking on sample 99\nWorking on sample 100\n","truncated":false}}
%---
%[output:888ec210]
%   data: {"dataType":"text","outputData":{"text":"Mean number in system: 0.194167\n","truncated":false}}
%---
%[output:44eba467]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAA0gAAAH6CAYAAAA9emyMAAAAAXNSR0IArs4c6QAAIABJREFUeF7t3Q+QVWeZJ\/6nx+loMglOTDNLhR42s0GtcbOL6DjqGtbS9FhlNAVSqagbghEZBpmwOECMPaWGxpGRhSFiXPKnMdMQg8JSgIl0ZlDGMYYZNGIS3CqG6BJ3DLRl4i9rgqESKtW\/eo9zkYam+1zSF87b93OrUpRy7rlPf54XuN\/7nPuelv7+\/v7wIECAAAECBAgQIECAAIFoEZCsAgIECBAgQIAAAQIECPxaQECyEggQIECAAAECBAgQIPBvAgKSpUCAAAECBAgQIECAAAEByRogQIAAAQIECBAgQIDAQAETJCuCAAECBAgQIECAAAECJkjWAAECBAgQIECAAAECBEyQrAECBAgQIECAAAECBAgMKuASOwuDAAECBAgQIECAAAEC\/yYgIFkKBAgQIECAAAECBAgQEJCsAQIECBAgQIAAAQIECAwUMEGyIggQIECAAAECBAgQIGCCZA0QIECAAAECBAgQIEDABMkaIECAAAECBAgQIECAwKACLrGzMAgQIECAAAECBAgQIPBvAgKSpUCAAAECBAgQIECAAAEByRogQIAAAQIECBAgQIDAQAETJCuCAAECBAgQIECAAAECJkjWAAECBAgQIECAAAECBEyQrAECBAgQIECAAAECBAgMKuASOwuDAAECBAgQIECAAAEC\/yYgIFkKBAgQIECAAAECBAgQEJCsAQIECBAgQIAAAQIECAwUMEGyIggQIECAAAECBAgQIGCCZA0QIECAAAECBAgQIEDABMkaIECAAAECBAgQIECAwKACLrGzMAgQIECAAAECBAgQIPBvAgKSpUCAAAECBAgQIECAAAEByRogQIAAAQIECBAgQIDAQAETpDpWRH9\/f+zatSuWLVsW+\/fvj9bW1ujo6IjOzs4YP358qTM9++yzsWrVqvhf\/+t\/xXPPPRcXX3xxfOQjH4lrr702zjnnnFLncBABAgQIECBAgAABAo0REJDqcO3t7Y2FCxfGxIkTY8aMGdHX1xc9PT0xduzY4tf29vYhz\/bEE0\/E9ddfH48\/\/nhceeWV8Y53vCMefPDBuO++++Lqq6+Orq4uIamOfjiUAAECBAgQIECAwEgLCEglRQ8ePBgzZ86Mtra26O7ujjFjxhTP3LNnT8yaNSumTp1aBJyWlpZBz5imT0uXLo3169fH4sWLY+7cucWx6f+\/\/fbb45ZbbolPfvKTxWt4ECBAgAABAgQIECBwdgQEpJLu27Zti0WLFsWKFSti+vTpx5519OjRWLBgQezduzc2bNgQEyZMGPSMTz75ZLz\/\/e+P3\/md34l169bFq171qmPHPfXUU3HdddfFK1\/5yli7dm2cf\/75JatyGAECBAgQIECAAAECIykgIJXUXLJkSWzZsqUIN5MnTx7wrDVr1sTq1auLcDNlypRBz\/joo48W06Errrii+A7S8Y80RfrYxz4W3\/\/+9+Oee+6JSy65pGRVDiNAgAABAgQIECBAYCQFBKQSmsdPiTZu3HjShgzbt2+P+fPnF5fQpe8mDfYoE5D+8R\/\/sbgEb9KkSSWqcggBAgQIECBAgAABAiMtICCVED18+HDMnj07Dh06FJs2bYpx48YNeNaOHTuK7xSl7xbNmzdv0DOm7zClS+zSRg4nXkb39NNPF99jOnDggIBUoh8OIUCAAAECBAgQINAoAQGphOxIBKQ0hUo74H3jG98oLrFLu9jVHvfee2\/ceOON8YpXvEJAKtEPhxAgQIAAAQIECBBolICAVEJ2JAJSepnaNt\/\/9\/\/+37jqqqvi8ssvL7b5ThOotLlDmjKVucTuP\/yH\/zBo1WkC5UGAAAECBAgQIECAwOkLCEgl7Mp+B2nlypUDdrgb7NQpBP31X\/91fPOb34wXX3wx3vCGNxTfXUoh6a677oq77747LrvssiGrSgFJGCrROIcQIECAAAECBAgQqFNAQCoJlnax27p166ATnjK72A31MrUAlm4gmwJSutfSUA8BqWTTHEaAAAECBAgQIECgTgEBqSTYS70P0q9+9aviO0g\/\/\/nPi0nRhRdeeOyV\/\/Vf\/zX+23\/7b\/GWt7yluM\/SqW42W3uCgFSyaQ4jQIAAAQIECBAgUKeAgFQSLF0al+5jlKY73d3dMWbMmOKZu3fvjjlz5sS0adOiq6tryHCTplBf\/epX44477oi3v\/3txfNfeOGF+NznPhebN2+OO++8swhJwz0EpOGE\/D4BAgQIECBAgACB0xMQkOpw6+3tLaZAKaCksNTX1xc9PT0xduzY4te0hXd61DZ12Ldv34BL8mqbNPy\/\/\/f\/ivslpY0Z0mQqhay\/+Iu\/KLYKH256lM4vINXRNIcSIECAAAECBAgQqENAQKoDq7+\/P3bu3BnLly8vNklobW2Njo6O6OzsHHDz2FMFpPRSP\/3pT4tNGb7zne9E+u5RCjspHL373e8uFY4EpDoa5lACBAgQIECAAAECdQoISHWCVeFwE6QqdEENBAgQIECAAAECo1FAQMqwqwJShk1TMgECBAgQIECAQBYCAlIWbRpYpICUYdOUTIAAAQIECBAgkIWAgJRFmwSkDNukZAIECBAgQIAAgQwFBKQMm2aClGHTlEyAAAECBAgQIJCFgICURZtMkDJsk5IJECBAgAABAgQyFBCQMmyaCVKGTVMyAQIECBAgQIBAFgICUhZtMkHKsE1KJkCAAAECBAgQyFBAQMqwaSZIGTZNyQQIECBAgAABAlkICEhZtMkEKcM2KZkAAQIECBAgQCBDAQEpw6aZIGXYNCUTIECAAAECBAhkISAgZdEmE6QM26RkAgQIECBAgACBDAUEpAybZoKUYdOUTIAAAQIECBAgkIWAgJRFm0yQMmyTkgkQIECAAAECBDIUEJAybJoJUoZNUzIBAgQIECBAgEAWAgJSFm0yQcqwTUomQIAAAQIECBDIUEBAyrBpJkgZNk3JBAgQIECAAAECWQgISFm0yQQpwzYpmQABAgQIECBAIEMBASnDppkgZdg0JRMgQIAAAQIECGQhICBl0SYTpAzbpGQCBAgQIECAAIEMBQSkDJtmgpRh05RMgAABAgQIECCQhYCAlEWbTJAybJOSCRAgQIAAAQIEMhQQkDJsmglShk1TMgECBAgQIECAQBYCAlIWbTJByrBNSiZAgAABAgQIEMhQQEDKsGkmSBk2TckECBAgQIAAAQJZCAhIWbTJBCnDNimZAAECBAgQIEAgQwEBKcOmmSBl2DQlEyBAgAABAgQIZCEgIGXRprM\/QUqhzIPASAocOHBgJE\/nXAQIECBAgACBEREQkEaE8cye5GxMkNJrTl1+\/5n9Qb3aqBX42k3vDgFp1LbXD0aAAAECBLIWEJAybJ+AlGHTlDxAQECyIAgQIECAAIGqCghIVe3MEHUJSBk2TckCkjVAgAABAgQIZCEgINXRpv7+\/ti1a1csW7Ys9u\/fH62trdHR0RGdnZ0xfvz4Umd69tlnY9WqVbF169Z45plnYsyYMfG+970vFi5cGBdccEGpcwhIpZgcVGEBE6QKN0dpBAgQIECgyQUEpDoWQG9vbxFkJk6cGDNmzIi+vr7o6emJsWPHFr+2t7cPebYUiObNmxff\/e5346qrrorLL788HnzwwbjvvvvizW9+c6xZs6YITMM9BKThhPx+1QUEpKp3SH0ECBAgQKB5BQSkkr0\/ePBgzJw5M9ra2qK7u\/tYkNmzZ0\/MmjUrpk6dGl1dXdHS0nLKM375y1+OT3\/60\/EXf\/EXccMNNxTHpqnUF7\/4xbjlllti6dKlRfAa7iEgDSfk96suICBVvUPqI0CAAAECzSsgIJXs\/bZt22LRokWxYsWKmD59+rFnHT16NBYsWBB79+6NDRs2xIQJE055xo9\/\/OPx93\/\/97F+\/fqYNGnSseMeffTRInxdccUVxeV3wz0EpOGE\/H7VBQSkqndIfQQIECBAoHkFBKSSvV+yZEls2bIl1q1bF5MnTx7wrHRp3OrVq2Pt2rUxZcqUU54xHfc3f\/M3cdttt8W73vWuY8f9wz\/8Q3z0ox8tJlE33XTTsBUJSMMSOaDiAgJSxRukPAIECBAg0MQCAlKJ5h8\/Jdq4ceNJGzJs37495s+fP+wlco899lh8+MMfjpe\/\/OXxhS98If7jf\/yP8S\/\/8i\/FBOrpp5+Ou+66K\/7Tf\/pPw1YkIA1L5ICKCwhIFW+Q8ggQIECAQBMLCEglmn\/48OGYPXt2HDp0KDZt2hTjxo0b8KwdO3bE3LlzY\/HixcUmDEM9fvKTnxTHpGBUe7z2ta8tJlCvec1rSlQTISCVYnJQhQUEpAo3R2kECBAgQKDJBQSkEgtgpALSE088EXPmzIl\/\/dd\/jauvvjre9KY3xUMPPRSbN28uvrt05513DrsTXio3BaTBHgcOHCjx05zeIek1py6\/\/\/Se7FkEThAQkCwJAgQIECBAoKoCAlKJzoxEQDpy5EhxGV7a1jttxHDllVcee+W07XcKTikw3XrrrXHuuecOWZUJUommOaTSAgJSpdujOAIECBAg0NQCAlKJ9pf9DtLKlSsH7HB3\/KnT94+uvfbauOyyy+L2228vvodUe9TO\/8\/\/\/M9x9913F8cM9RCQSjTNIZUWEJAq3R7FESBAgACBphYQkEq2P+1it3Xr1pO26E5PL7OL3XBbeadz3HHHHYOe\/8QSBaSSTXNYZQUEpMq2RmEECBAgQKDpBQSkkkvgpd4HKW3OkCZIEydOLCZIx19Gl24W+7GPfSweeOABE6SS\/XBY3gICUt79Uz0BAgQIEBjNAgJSye4ePHiwuJlrW1tbdHd3x5gxY4pn7t69u\/j+0LRp06KrqytaWloGPWO6jG7hwoXxjW9846TvID388MPFOdLNY30HqWRDHJa1gICUdfsUT4AAAQIERrWAgFRHe3t7e4uQky5xS2Gpr68venp6YuzYscWv7e3txdlqmzrs27dvwCVzaRe766+\/PtKvaZOG\/\/pf\/2s88sgjxS525513XrGL3etf\/\/phK3KJ3bBEDqi4gIBU8QYpjwABAgQINLGAgFRH89OlcDt37ozly5dH2lK7tbU1Ojo6orOzc8DNY08VkNJLpUlUmhL93d\/9XTzzzDNFMHrve99b7HA3fvz4UtUISKWYHFRhAQGpws1RGgECBAgQaHIBASnDBSAgZdg0JQ8QEJAsCAIECBAgQKCqAgJSVTszRF0CUoZNU7KAZA0QIECAAAECWQgISFm0aWCRAlKGTVOygGQNECBAgAABAlkICEhZtElAyrBNSh5CwCV2lgcBAgQIECBQVQEBqaqdGaIuE6QMm6ZkEyRrgAABAgQIEMhCQEDKok0mSBm2SckmSNYAAQIECBAgkKGAgJRh00yQMmyakk2QrAECBAgQIEAgCwEBKYs2mSBl2CYlmyBZAwQIECBAgECGAgJShk0zQcqwaUo2QbIGCBAgQIAAgSwEBKQs2mSClGGblGyCZA0QIECAAAECGQoISBk2zQQpw6Yp2QTJGiBAgAABAgSyEBCQsmiTCVKGbVKyCZI1QIAAAQIECGQoICBl2DQTpAybpmQTJGuAAAECBAgQyEJAQMqiTSZIGbZJySZI1gABAgQIECCQoYCAlGHTTJAybJqSTZCsAQIECBAgQCALAQEpizaZIGXYJiWbIFkDBAgQIECAQIYCAlKGTTNByrBpSjZBsgYIECBAgACBLAQEpCzaZIKUYZuUbIJkDRAgQIAAAQIZCghIGTbNBCnDpinZBMkaIECAAAECBLIQEJCyaJMJUoZtUrIJkjVAgAABAgQIZCggIGXYNBOkDJumZBMka4AAAQIECBDIQkBAyqJNJkgZtknJJkjWAAECBAgQIJChgICUYdNMkDJsmpJNkKwBAgQIECBAIAsBASmLNpkgZdgmJZsgWQMECBAgQIBAhgICUoZNM0HKsGlKNkGyBggQIECAAIEsBASkLNpkgpRhm5RsgmQNECBAgAABAhkKCEgZNs0EKcOmKdkEyRogQIAAAQIEshAQkLJokwlShm1SsgmSNUCAAAECBAhkKCAgZdg0E6QMm6ZkEyRrgAABAgQIEMhCQEDKok0mSBm2SckmSNYAAQIECBAgkKGAgJRh00yQMmyakk2QrAECBAgQIEAgCwEBqY429ff3x65du2LZsmWxf\/\/+aG1tjY6Ojujs7Izx48cPeaaf\/exncc0118QTTzxxyuMuuOCCWL9+fUyaNGnIcwlIdTTNoZUU+NpN744DBw5UsjZFESBAgAABAs0tICDV0f\/e3t5YuHBhTJw4MWbMmBF9fX3R09MTY8eOLX5tb28\/5dl++ctfxm233Rbp1xMfTz75ZDzwwAPxqle9Ku6+++549atfLSDV0ReH5icgIOXXMxUTIECAAIFmERCQSnb64MGDMXPmzGhra4vu7u4YM2ZM8cw9e\/bErFmzYurUqdHV1RUtLS0lz\/jrw1544YUidH3zm9+MVatWxZVXXjns802QhiVyQMUFBKSKN0h5BAgQIECgiQUEpJLN37ZtWyxatChWrFgR06dPP\/aso0ePxoIFC2Lv3r2xYcOGmDBhQskz\/vqwzZs3x0033RQf+MAHYsmSJcVle8M9BKThhPx+1QUEpKp3SH0ECBAgQKB5BQSkkr1P4WXLli2xbt26mDx58oBnrVmzJlavXh1r166NKVOmlDxjRLq07kMf+lA888wzxaV1f\/AHf1DquQJSKSYHVVhAQKpwc5RGgAABAgSaXEBAKrEAjp8Sbdy48aQNGbZv3x7z58+PpUuXFt9NKvtIwWrlypWxePHimDdvXtmnhYBUmsqBFRUQkCraGGURIECAAAECISCVWASHDx+O2bNnx6FDh2LTpk0xbty4Ac\/asWNHzJ07t66gk6ZH1157bbz44ovFznXD7YJ3\/AsKSCWa5pBKCwhIlW6P4ggQIECAQFMLCEgl2t+IgFT7TlOaHKXvNtXzSAFpsEcjt01Orzl1+f31lOlYAqcUEJAsDgIECBAgQKCqAgJSic6MdEB6\/vnni4nTD37wg1L3PTqxRBOkEk1zSKUFBKRKt0dxBAgQIECgqQUEpBLtL\/sdpPR9ouN3uDvVqR977LHi8rpLL7202Njh\/PPPL1HFbw4RkOricnAFBQSkCjZFSQQIECBAgEAhICCVXAhpF7utW7cOOvGpdxe72qYO9W7OUCtVQCrZNIdVVkBAqmxrFEaAAAECBJpeQEAquQRG8j5IKWx95StfqXtbcAGpZLMcVnkBAanyLVIgAQIECBBoWgEBqWTrDx48GDNnzoy2trbo7u6OMWPGFM\/cvXt3zJkzJ6ZNmxZdXV3R0tIy5Bl\/9atfxZ\/92Z\/F448\/Hvfcc09ccsklJSv4zWEmSHWTeULFBASkijVEOQQIECBAgMAxAQGpjsXQ29sbCxcuLO5DlMJSX19f9PT0xNixY4tf29vbi7PVNnXYt2\/fSZfkPfXUU3HdddfFK17xirjrrrviwgsvrKOCXx8qINVN5gkVExCQKtYQ5RAgQIAAAQIC0umsgf7+\/ti5c2csX7480pbara2t0dHREZ2dnQPuYzRUQPrZz34W11xzTVx88cWntUGDgHQ6nfOcqgkISFXriHoIECBAgACBmoAJUoZrwQQpw6YpeYCAgGRBECBAgAABAlUVEJCq2pkh6hKQMmyakgUka4AAAQIECBDIQkBAyqJNA4sUkDJsmpIFJGuAAAECBAgQyEJAQMqiTQJShm1S8hACLrGzPAgQIECAAIGqCghIVe3MEHWZIGXYNCWbIFkDBAgQIECAQBYCAlIWbTJByrBNSjZBsgYIECBAgACBDAUEpAybZoKUYdOUbIJkDRAgQIAAAQJZCAhIWbTJBCnDNinZBMkaIECAAAECBDIUEJAybJoJUoZNU7IJkjVAgAABAgQIZCEgIGXRJhOkDNukZBMka4AAAQIECBDIUEBAyrBpJkgZNk3JJkjWAAECBAgQIJCFgICURZtMkDJsk5JNkKwBAgQIECBAIEMBASnDppkgZdg0JZsgWQMECBAgQIBAFgICUhZtMkHKsE1KNkGyBggQIECAAIEMBQSkDJtmgpRh05RsgmQNECBAgAABAlkICEhZtMkEKcM2KdkEyRogQIAAAQIEMhQQkDJsmglShk1TsgmSNUCAAAECBAhkISAgZdEmE6QM26RkEyRrgAABAgQIEMhQQEDKsGkmSBk2TckmSNYAAQIECBAgkIWAgJRFm0yQMmyTkk2QrAECBAgQIEAgQwEBKcOmmSBl2DQlmyBZAwQIECBAgEAWAgJSFm0yQcqwTUo2QbIGCBAgQIAAgQwFBKQMm2aClGHTlGyCZA0QIECAAAECWQgISFm0yQQpwzYp2QTJGiBAgAABAgQyFBCQMmyaCVKGTVOyCZI1QIAAAQIECGQhICBl0SYTpAzbpGQTJGuAAAECBAgQyFBAQMqwaSZIGTZNySZI1gABAgQIECCQhYCAlEWbTJAybJOSTZCsAQIECBAgQCBDAQEpw6aZIGXYNCWbIFkDBAgQIECAQBYCAlIWbTJByrBNSjZBsgYIECBAgACBDAUEpAybZoKUYdOUbIJkDRAgQIAAAQJZCAhIdbSpv78\/du3aFcuWLYv9+\/dHa2trdHR0RGdnZ4wfP77UmV588cXo7e2NL3zhC3HgwIHiHG9961vjk5\/8ZFx66aWlziEglWJyUIUFvnbTu4v170GAAAECBAgQqJqAgFRHR1KwWbhwYUycODFmzJgRfX190dPTE2PHji1+bW9vH\/JsKWDdfvvtsXLlynjzm98cV199dfzoRz+Ku+++Oy688MLi10suuWTYigSkYYkcUHEBAaniDVIeAQIECBBoYgEBqWTzDx48GDNnzoy2trbo7u6OMWPGFM\/cs2dPzJo1K6ZOnRpdXV3R0tJyyjPu3r075syZE+95z3uKY88555zi2HvvvTduvPHGeP\/73z\/sOdLxAlLJpjmssgICUmVbozACBAgQIND0AgJSySWwbdu2WLRoUaxYsSKmT59+7FlHjx6NBQsWxN69e2PDhg0xYcKEQc+YpkcpBKWQdOJxTz\/9dBGyXvGKV8Sdd94ZF1xwwZBVCUglm+awygoISJVtjcIIECBAgEDTCwhIJZfAkiVLYsuWLbFu3bqYPHnygGetWbMmVq9eHWvXro0pU6YMesannnoqrrvuuviDP\/iD4tj03aPTfQhIpyvneVUREJCq0gl1ECBAgAABAicKCEgl1sTxU6KNGzeetCHD9u3bY\/78+bF06dLiu0mDPR577LG49tpri8v0\/viP\/zj+x\/\/4H8XU6WUve1ndGz0ISCWa5pBKCwhIlW6P4ggQIECAQFMLCEgl2n\/48OGYPXt2HDp0KDZt2hTjxo0b8KwdO3bE3LlzY\/HixTFv3rxBz\/joo48W4SjtdveTn\/wkrrjiiuK\/Rx55JDZv3lxs0pAur\/vDP\/zDYSsSkIYlckDFBQSkijdIeQQIECBAoIkFBKQSzR\/JgJTOlYJUClS1DR1qu+P9yZ\/8SaxatWrYy+9SQBrs0chtk9NrTl1+fwkthxAYXkBAGt7IEQQIECBAgMDZERCQSriPZED6d\/\/u38U999xTbA1eexw5cqQITD\/+8Y+L3xtuq28TpBJNc0ilBQSkSrdHcQQIECBAoKkFBKQS7S\/7HaR0f6Pjd7g7\/tS1S+zSJXRpM4fzzz9\/wCun+yvt3Lkz1q9fH5MmTRqyKgGpRNMcUmkBAanS7VEcAQIECBBoagEBqWT70y52W7duHTTAlNnFLt1HKd3nKN1MVkAqie6wUSsgII3a1vrBCBAgQIBA9gICUskWvtT7ID3\/\/PPFZXRpN7sTL6OrXcLX19cXX\/nKV+Liiy82QSrZF4flKSAg5dk3VRMgQIAAgWYQEJBKdjlNgNIudG1tbdHd3R1jxowpnplu\/DpnzpyYNm1adHV1Hdt4YbDTpt3qbrrpprjmmmuKY88555zisNomDR\/84Afj05\/+9JDnSMe7xK5k0xxWWQEBqbKtURgBAgQIEGh6AQGpjiVQCzIpoKSwlCY+PT09xYYL6dd0+Vx61CZC+\/btG3BJ3gsvvBA333xzsVX42972tiJUpXshpeCUtg4\/\/hxDlSUg1dE0h1ZSQECqZFsURYAAAQIECESEgFTHMujv7y82Uli+fHmkLbVbW1sHvcnrqQJSeqkUktIldl\/60peK+yqdd9558d73vjfSJg2\/93u\/V6oaAakUk4MqLCAgVbg5SiNAgAABAk0uICBluAAEpAybpuQBAgKSBUGAAAECBAhUVUBAqmpnhqhLQMqwaUoWkKwBAgQIECBAIAsBASmLNg0sUkDKsGlKFpCsAQIECBAgQCALAQEpizYJSBm2SclDCLjEzvIgQIAAAQIEqiogIFW1M0PUZYKUYdOUbIJkDRAgQIAAAQJZCAhIWbTJBCnDNinZBMkaIECAAAECBDIUEJAybJoJUoZNU7IJkjVAgAABAgQIZCEgIGXRJhOkDNukZBMka4AAAQIECBDIUEBAyrBpJkgZNk3JJkjWAAECBAgQIJCFgICURZtMkDJsk5JNkKwBAgQIECBAIEMBASnDppkgZdg0JZsgWQMECBAgQIBAFgICUhZtMkHKsE1KNkGyBggQIECAAIEMBQSkDJtmgpRh05RsgmQNECBAgAABAlkICEhZtMkEKcM2KdkEyRogQIAAAQIEMhQQkDJsmglShk1TsgmSNUCAAAECBAhkISAgZdEmE6QM26RkEyRrgAABAgQIEMhQQEDKsGkmSBk2TckmSNYAAQIECBAgkIWAgJRFm0yQMmyTkk2QrAECBAgQIEAgQwEBKcOmmSBl2DQlmyBZAwQIECBAgEAWAgJSFm0yQcqwTUo2QbIGCBAgQIAAgQwFBKQMm2aClGHTlGyCZA0QIECAAAECWQgISFm0yQQpwzYp2QTJGiBAgAABAgQyFBCQMmyaCVKGTVOyCZI1QIAAAQIECGQhICBl0SYTpAzbpGQTJGt1q+LsAAAgAElEQVSAAAECBAgQyFBAQMqwaSZIGTZNySZI1gABAgQIECCQhYCAlEWbTJAybJOSTZCsAQIECBAgQCBDAQEpw6aZIGXYNCWbIFkDBAgQIECAQBYCAlIWbTJByrBNSjZBsgYIECBAgACBDAUEpAybZoKUYdOUbIJkDRAgQIAAAQJZCAhIWbTJBCnDNinZBMkaIECAAAECBDIUEJAybJoJUoZNU7IJkjVAgAABAgQIZCEgINXRpv7+\/ti1a1csW7Ys9u\/fH62trdHR0RGdnZ0xfvz4Umdavnx53HHHHYMeO23atFi1atWw5xGQhiVyQMUFvnbTu+PAgQMVr1J5BAgQIECAQDMKCEh1dL23tzcWLlwYEydOjBkzZkRfX1\/09PTE2LFji1\/b29uHPNvRo0djwYIFRci64oor4uUvf\/mA4ydNmhQf+MAHhq1IQBqWyAEVFxCQKt4g5REgQIAAgSYWEJBKNv\/gwYMxc+bMaGtri+7u7hgzZkzxzD179sSsWbNi6tSp0dXVFS0tLac849NPP10c+7u\/+7tx++23nxSQSpYSAlJZKcdVVUBAqmpn1EWAAAECBAgISCXXwLZt22LRokWxYsWKmD59+rFn1aZCe\/fujQ0bNsSECRNOecbHHnssrr322njPe94TS5YsKfnKJx8mIJ02nSdWREBAqkgjlEGAAAECBAicJCAglVwUKdBs2bIl1q1bF5MnTx7wrDVr1sTq1atj7dq1MWXKlFOe8Tvf+U7Mnj07PvWpTxWX6J3uQ0A6XTnPq4qAgFSVTqiDAAECBAgQOFFAQCqxJo6fEm3cuPGkDRm2b98e8+fPj6VLlw4ZfL785S8Xx3zkIx+J733ve5GmTi972cvirW99a3zyk5+MSy+9tEQ14RK7UkoOqrKAgFTl7qiNAAECBAg0t4CAVKL\/hw8fLiY\/hw4dik2bNsW4ceMGPGvHjh0xd+7cWLx4ccybN++UZ\/z4xz8emzdvjvPOOy+uvvrqeP3rXx\/f\/e5347777otzzz037rzzzpOmU4OdzASpRNMcUmkBAanS7VEcAQIECBBoagEBqUT7RyIgHTlyJFJASoEobfN9\/GV6td3xXve61xW74dU2gDhVaSkgDfZo5LbJ6TWnLr+\/hJZDCAwvICANb+QIAgQIECBA4OwICEgl3EciIA31MrVL+B588MFBv+N04nNNkEo0zSGVFhCQKt0exREgQIAAgaYWEJBKtL\/sd5BWrlw5YIe7Eqc+dsitt94at9xyS7H997ve9a4hnyog1SPr2CoKCEhV7IqaCBAgQIAAgSQgIJVcB2kXu61bt8b69esj3dD1+EfZXexefPHF+NWvfjXoJXTLly8vvoOULr\/r6OgQkEr2xWF5CghIefZN1QQIECBAoBkEBKSSXX6p90Gq3QMp7VSXtgM\/\/\/zzj71y+n5S2uThxz\/+cdxzzz1xySWXCEgl++KwPAUEpDz7pmoCBAgQINAMAgJSyS4fPHgwZs6cGW1tbdHd3X1sCrR79+6YM2dOTJs2Lbq6uqKlpWXQM9ZCUNqkYdWqVXHllVceO+7ee++NG2+8MaZOnRqf\/exno7W1VUAq2ReH5SkgIOXZN1UTIECAAIFmEBCQ6uhybbe59B2gFJb6+vqKXefGjh1b\/Nre3l6crbapw759+wZckvfwww8XYSqFpdo23w888ECxzferX\/3q4hK72jmGKst3kOpomkMrKSAgVbItiiJAgAABAgR8B6m+NdDf3x87d+6M9H2htKV2mvSk7wt1dnYOuHnsqQJSerU0iUobMnz961+P5557Li666KJ43\/veV9xo9oILLihVkIBUislBFRYQkCrcHKURIECAAIEmFzBBynABCEgZNk3JAwQEJAuCAAECBAgQqKqAgFTVzgxRl4CUYdOULCBZAwQIECBAgEAWAgJSFm0aWKSAlGHTlCwgWQMECBAgQIBAFgICUhZtEpAybJOShxBwiZ3lQYAAAQIECFRVQECqameGqMsEKcOmKdkEyRogQIAAAQIEshAQkLJokwlShm1SsgmSNUCAAAECBAhkKCAgZdg0E6QMm6ZkEyRrgAABAgQIEMhCQEDKok0mSBm2SckmSNYAAQIECBAgkKGAgJRh00yQMmyakk2QrAECBAgQIEAgCwEBKYs2mSBl2CYlmyBZAwQIECBAgECGAgJShk0zQcqwaUo2QbIGCBAgQIAAgSwEBKQs2mSClGGblGyCZA0QIECAAAECGQoISBk2zQQpw6Yp2QTJGiBAgAABAgSyEBCQsmiTCVKGbVKyCZI1QIAAAQIECGQoICBl2DQTpAybpmQTJGuAAAECBAgQyEJAQMqiTSZIGbZJySZI1gABAgQIECCQoYCAlGHTTJAybJqSTZCsAQIECBAgQCALAQEpizaZIGXYJiWbIFkDBAgQIECAQIYCAlKGTTNByrBpSjZBsgYIECBAgACBLAQEpCzaZIKUYZuUbIJkDRAgQIAAAQIZCghIGTbNBCnDpinZBMkaIECAAAECBLIQEJCyaJMJUoZtUrIJkjVAgAABAgQIZCggIGXYNBOkDJumZBMka4AAAQIECBDIQkBAyqJNJkgZtknJJkjWAAECBAgQIJChgICUYdNMkDJsmpJNkKwBAgQIECBAIAsBASmLNpkgZdgmJZsgWQMECBAgQIBAhgICUoZNM0HKsGlKNkGyBggQIECAAIEsBASkLNpkgpRhm5RsgmQNECBAgAABAhkKCEgZNs0EKcOmKdkEyRogQIAAAQIEshAQkLJokwlShm1SsgmSNUCAAAECBAhkKCAg1dG0\/v7+2LVrVyxbtiz2798fra2t0dHREZ2dnTF+\/Pg6zvTrQ9P5vvjFL8batWtj\/fr1MWnSpFLnMEEqxeSgCgt87aZ3x4EDBypcodIIECBAgACBZhUQkOrofG9vbyxcuDAmTpwYM2bMiL6+vujp6YmxY8cWv7a3t9dxtog9e\/bErFmziucISHXROThzAQEp8wYqnwABAgQIjGIBAalkcw8ePBgzZ86Mtra26O7ujjFjxhTPrIWcqVOnRldXV7S0tJQ64zPPPBN\/+qd\/Gg899FBccMEFAlIpNQeNFgEBabR00s9BgAABAgRGn4CAVLKn27Zti0WLFsWKFSti+vTpx5519OjRWLBgQezduzc2bNgQEyZMGPaM6dK622+\/Pe68887isrqHH35YQBpWzQGjSUBAGk3d9LMQIECAAIHRJSAgleznkiVLYsuWLbFu3bqYPHnygGetWbMmVq9eXXyXaMqUKcOeMQWiOXPmFBOpNHFKEymX2A3L5oBRJCAgjaJm+lEIECBAgMAoExCQSjT0+CnRxo0bT9qQYfv27TF\/\/vxYunRp8d2koR6HDx+OefPmxbPPPht33XVXfOUrX4k77rhDQCrRB4eMHgEBafT00k9CgAABAgRGm4CAVKKjKdTMnj07Dh06FJs2bYpx48YNeNaOHTti7ty5sXjx4iL8DPVIl9WlnevSr295y1siTZ8EpBJNcMioEhCQRlU7\/TAECBAgQGBUCQhIJdo5UgFp37598aEPfSje8573xKc\/\/eni8joBqUQDHDLqBASkUddSPxABAgQIEBg1AgJSiVaOREA6cuRIcRlemkKl7zGlrcHT43QD0mBlN\/K+MuneS1OX319CyyEEhhcQkIY3cgQBAgQIECBwdgQEpBLuZb+DtHLlygE73B1\/6rQJw+c+97n4\/Oc\/H+9617uO\/dbpBqRGhqHBSASkEgvFIaUFBKTSVA4kQIAAAQIEzrCAgFQSPO1it3Xr1kE3UxhuF7vaBOp73\/vekK9W9n5IKawISCUb57BKCghIlWyLoggQIECAAIGIEJBKLoOXch+kNIFKN4R9+umnT3q1tMHDN77xjbjhhhsiBZ83v\/nNceGFFw5ZlYBUsmkOq6yAgFTZ1iiMAAECBAg0vYCAVHIJHDx4sLhvUVtbW3HfojFjxhTP3L17d3FPo2nTpkVXV1ex8UI9D5fY1aPl2NEiICCNlk76OQgQIECAwOgTEJDq6Glvb28sXLiwmPSksNTX1xc9PT3Fhgvp1\/b29uJstUvq0q51w90AVkCqowEOHTUCAtKoaaUfhAABAgQIjDoBAamOlvb398fOnTtj+fLlxXeAWltbo6OjIzo7OwfcPFZAqgPVoU0pICA1Zdv90AQIECBAIAsBASmLNg0s0neQMmyakgcICEgWBAECBAgQIFBVAQGpqp0Zoi4BKcOmKVlAsgYIECBAgACBLAQEpCzaZIKUYZuUPISACZLlQYAAAQIECFRVQECqamdMkDLsjJLLCghIZaUcR4AAAQIECJxpAQHpTIuPwOu5xG4EEJ3irAoISGeV34sTIECAAAECQwgISBkuDwEpw6YpeYCAgGRBECBAgAABAlUVEJCq2pkh6hKQMmyakgUka4AAAQIECBDIQkBAyqJNA4sUkDJsmpIFJGuAAAECBAgQyEJAQMqiTQJShm1S8hACLrGzPAgQIECAAIGqCghIVe3MEHWZIGXYNCWbIFkDBAgQIECAQBYCAlIWbTJByrBNSjZBsgYIECBAgACBDAUEpAybZoKUYdOUbIJkDRAgQIAAAQJZCAhIWbTJBCnDNinZBMkaIECAAAECBDIUEJAybJoJUoZNU7IJkjVAgAABAgQIZCEgIGXRJhOkDNukZBMka4AAAQIECBDIUEBAyrBpJkgZNk3JJkjWAAECBAgQIJCFgICURZtMkDJsk5JNkKwBAgQIECBAIEMBASnDppkgZdg0JZsgWQMECBAgQIBAFgICUhZtMkHKsE1KNkGyBggQIECAAIEMBQSkDJtmgpRh05RsgmQNECBAgAABAlkICEhZtMkEKcM2KdkEyRogQIAAAQIEMhQQkDJsmglShk1TsgmSNUCAAAECBAhkISAgZdEmE6QM26RkEyRrgAABAgQIEMhQQEDKsGkmSBk2TckmSNYAAQIECBAgkIWAgJRFm0yQMmyTkk2QrAECBAgQIEAgQwEBKcOmmSBl2DQlmyBZAwQIECBAgEAWAgJSFm0yQcqwTUo2QbIGCBAgQIAAgQwFBKQMm2aClGHTlGyCZA0QIECAAAECWQgISFm0yQQpwzYp2QTJGiBAgAABAgQyFBCQMmyaCVKGTVOyCZI1QIAAAQIECGQhICBl0SYTpAzbpGQTJGuAAAECBAgQyFBAQKqjaf39\/bFr165YtmxZ7N+\/P1pbW6OjoyM6Oztj\/Pjxpc508ODBuPXWW+PrX\/96PPfcc3HxxRfHrFmz4oMf\/GCce+65pc5hglSKyUEVFvjaTe+OAwcOVLhCpREgQIAAAQLNKiAg1dH53t7eWLhwYUycODFmzJgRfX190dPTE2PHji1+bW9vH\/JsTzzxRFx\/\/fXxs5\/9LK6++up4\/etfHzt37ox03muuuSa6urrinHPOGbYiAWlYIgdUXEBAqniDlEeAAAECBJpYQEAq2fw0+Zk5c2a0tbVFd3d3jBkzpnjmnj17ignQ1KlTi4DT0tIy6BnT9Onmm2+OTZs2xapVq+LKK68sjkv\/\/9KlS2PDhg1x2223xTvf+c5hKxKQhiVyQMUFBKSKN0h5BAgQIECgiQUEpJLN37ZtWyxatChWrFgR06dPP\/aso0ePxoIFC2Lv3r1FyJkwYcKgZ3z22WeL6dMvf\/nLuOOOO+LCCy88dtyOHTti7ty5sXjx4pg3b96wFQlIwxI5oOICAlLFG6Q8AgQIECDQxAICUsnmL1myJLZs2RLr1q2LyZMnD3jWmjVrYvXq1bF27dqYMmVKyTP+5rC\/\/du\/jc985jOxcuXKAeHrVCcSkOom9oSKCQhIFWuIcggQIECAAIFjAgJSicVw\/JRo48aNJ23IsH379pg\/f35xqVz6blLZx\/PPPx\/33ntv\/NVf\/VUxebrrrruK7zMN9xCQhhPy+1UXEJCq3iH1ESBAgACB5hUQkEr0\/vDhwzF79uw4dOhQ8R2icePGDXhWvZfIpScvX768uNQuPV7zmtfEl770pdI74QlIJZrmkEoLCEiVbo\/iCBAgQIBAUwsISCXa34iAlEJVmkw99NBDsXnz5jjvvPPizjvvLHa2G+4hIA0n5PerLiAgVb1D6iNAgAABAs0rICCV6H0jAtLxL\/vggw8WmzOk7cPTduG1HfJOVVoKSIM9GnlfmfSaU5ffX0LLIQSGFxCQhjdyBAECBAgQIHB2BASkEu5lv4NUdpOFE18yfRcp7WL3gx\/8INavXx+TJk0asioTpBJNc0ilBQSkSrdHcQQIECBAoKkFBKSS7U+72G3dunXQAPNSd7FLJaQtwNNNYwWkkg1xWNYCAlLW7VM8AQIECBAY1QICUsn2vtT7IO3fv7\/Y6S5tyHDLLbdEa2vrsVeuXcL305\/+NO6555645JJLTJBK9sVheQoISHn2TdUECBAgQKAZBASkkl0+ePBgzJw5M9ra2qK7u\/vY94R2794dc+bMiWnTpkVXV1e0tLQMesYjR44Ul9E98sgjxXbeb3zjG48dl7b6vvHGG2Pq1Knx2c9+dkB4GuxkLrEr2TSHVVZAQKpsaxRGgAABAgSaXkBAqmMJ9Pb2FpfCpYCSwlJfX1+xqUK6d1H6tb29vThbbSK0b9++AZfMPfzww0WYSmHp6quvLnase+CBB+K+++6LV7\/61cUudrVzDFWWgFRH0xxaSQEBqZJtURQBAgQIECAQEQJSHcugv7+\/+J5QuodR2jEuXSbX0dERnZ2dA+5hdKqAlF7q8ccfj7SZw7e\/\/e147rnn4qKLLor3ve99xeV3F1xwQalqBKRSTA6qsICAVOHmKI0AAQIECDS5gICU4QIQkDJsmpIHCAhIFgQBAgQIECBQVQEBqaqdGaIuASnDpilZQLIGCBAgQIAAgSwEBKQs2jSwSAEpw6YpWUCyBggQIECAAIEsBASkLNokIGXYJiUPIeASO8uDAAECBAgQqKqAgFTVzgxRlwlShk1TsgmSNUCAAAECBAhkISAgZdEmE6QM26RkEyRrgAABAgQIEMhQQEDKsGkmSBk2TckmSNYAAQIECBAgkIWAgJRFm0yQMmyTkk2QrAECBAgQIEAgQwEBKcOmmSBl2DQlmyBZAwQIECBAgEAWAgJSFm0yQcqwTUo2QbIGCBAgQIAAgQwFBKQMm2aClGHTlGyCZA0QIECAAAECWQgISFm0yQQpwzYp2QTJGiBAgAABAgQyFBCQMmyaCVKGTVOyCZI1QIAAAQIECGQhICBl0SYTpAzbpGQTJGuAAAECBAgQyFBAQMqwaSZIGTZNySZI1gABAgQIECCQhYCAlEWbTJAybJOSTZCsAQIECBAgQCBDAQEpw6aZIGXYNCWbIFkDBAgQIECAQBYCAlIWbTJByrBNSjZBsgYIECBAgACBDAUEpAybZoKUYdOUbIJkDRAgQIAAAQJZCAhIWbTJBCnDNinZBMkaIECAAAECBDIUEJAybJoJUoZNU7IJkjVAgAABAgQIZCEgIGXRJhOkDNukZBMka4AAAQIECBDIUEBAyrBpJkgZNk3JJkjWAAECBAgQIJCFgICURZtMkDJsk5JNkKwBAgQIECBAIEMBASnDppkgZdg0JZsgWQMECBAgQIBAFgICUhZtMkHKsE1KNkGyBggQIECAAIEMBQSkDJtmgpRh05RsgmQNECBAgAABAlkICEhZtMkEKcM2KdkEyRogQIAAAQIEMhQQkDJsmglShk1TsgmSNUCAAAECBAhkISAgZdEmE6QM26RkEyRrgAABAgQIEMhQQEDKsGkmSBk2TckmSNYAAQIECBAgkIWAgFRHm\/r7+2PXrl2xbNmy2L9\/f7S2tkZHR0d0dnbG+PHjS53p8ccfj5UrV8a3v\/3teO655+K8886Ld7zjHfGJT3yi9DkEpFLUDqqwwNduenccOHCgwhUqjQABAgQIEGhWAQGpjs739vbGwoULY+LEiTFjxozo6+uLnp6eGDt2bPFre3v7kGd7+OGHY86cOXHkyJG4+uqr401velM89NBDsXnz5iIo3XXXXXHZZZcNW5GANCyRAyouICBVvEHKI0CAAAECTSwgIJVs\/sGDB2PmzJnR1tYW3d3dMWbMmOKZe\/bsiVmzZsXUqVOjq6srWlpaBj3j888\/H\/Pnz4\/vfve7RRB64xvfeOy43bt3F8Hp7W9\/e6xataqYTA31EJBKNs1hlRUQkCrbGoURIECAAIGmFxCQSi6Bbdu2xaJFi2LFihUxffr0Y886evRoLFiwIPbu3RsbNmyICRMmDHrGJ598Mj784Q\/H+eefH2vXri1+rT0OHz4cs2fPjkOHDsWmTZti3LhxAlLJvjgsTwEBKc++qZoAAQIECDSDgIBUsstLliyJLVu2xLp162Ly5MkDnrVmzZpYvXp1EXymTJlS8oy\/OUxAqpvMEzIXEJAyb6DyCRAgQIDAKBYQkEo09\/gp0caNG0\/aTGH79u3F5XNLly4tvptU72Pfvn3F5XuXXnrpSdOlwc7lErt6hR1fNQEBqWodUQ8BAgQIECBQExCQSqyF4SY8O3bsiLlz58bixYtj3rx5Jc74m0NeeOGF+Mu\/\/MvYunVr3HzzzUVQGu4hIA0n5PerLiAgVb1D6iNAgAABAs0rICCV6H2jAtKLL74Y6fK8z3\/+88VW37feemuce+65w1YkIA1L5ICKCwhIFW+Q8ggQIECAQBMLCEglmt+IgJQmRykQpYD01re+tfi1tjPecCWlgDTYo5H3lUmvOXX5\/cOV5vcJlBIQkEoxOYgAAQIECBA4CwICUgn0st9BSjeAPX6Hu1OdOt0H6TOf+Uyk7zO97W1vKzZ4uPDCC0tU8utDTJBKUzmwogICUkUboywCBAgQIEAgBKSSiyDtYpe+J7R+\/fqYNGnSgGfVs4vdM888E52dnXH\/\/fcX905KQen4Lb\/LlCMglVFyTJUFBKQqd0dtBAgQIECguQUEpJL9f6n3QUovk8JR2u3uwQcfjPe\/\/\/3xqU99qtR3jk4sUUAq2TSHVVZAQKpsaxRGgAABAgSaXkBAKrkEDh48WOww19bWFt3d3ce+L7R79+6YM2dOTJs2Lbq6uqKlpWXQM\/b39xc3mb399tuLcJSOPeecc0q++sDDBKTTYvOkCgkISBVqhlIIECBAgACBAQICUh0Lore3NxYuXFh8ByiFpb6+vujp6YmxY8cWv7a3txdnq23qkO5vVLsk70c\/+lFcd9118fTTT8fb3\/72uOiii0565Ve+8pXx0Y9+NNKvQz0EpDqa5tBKCghIlWyLoggQIECAAIEI30GqZxWkKdDOnTtj+fLlkXaMa21tjY6OjuI7RePHjz92qsECUu1eSUO9XgpYmzZtinHjxglI9TTGsdkJCEjZtUzBBAgQIECgaQRMkDJstQlShk1T8gABAcmCIECAAAECBKoqICBVtTND1CUgZdg0JQtI1gABAgQIECCQhYCAlEWbBhYpIGXYNCULSNYAAQIECBAgkIWAgJRFmwSkDNuk5CEEXGJneRAgQIAAAQJVFRCQqtqZIeoyQcqwaUo2QbIGCBAgQIAAgSwEBKQs2mSClGGblGyCZA0QIECAAAECGQoISBk2zQQpw6Yp2QTJGiBAgAABAgSyEBCQsmiTCVKGbVKyCZI1QIAAAQIECGQoICBl2DQTpAybpmQTJGuAAAECBAgQyEJAQMqiTSZIGbZJySZI1gABAgQIECCQoYCAlGHTTJAybJqSTZCsAQIECBAgQCALAQEpizaZIGXYJiWbIFkDBAgQIECAQIYCAlKGTTNByrBpSjZBsgYIECBAgACBLAQEpCzaZIKUYZuUPMwECRCBkRQ4cODASJ7OuQgQIECgiQUEpAybb4KUYdOUfNIEaery+6kQGBGBr9307hCQRoTSSQgQIEAgIgSkDJeBgJRh05QsIFkDDRMQkBpG68QECBBoSgEBKcO2C0gZNk3JApI10DABAalhtE5MgACBphQQkDJsu4CUYdOULCBZAw0TEJAaRuvEBAgQaEoBASnDtgtIGTZNyQKSNdAwAQGpYbROTIAAgaYUEJAybLuAlGHTlCwgWQMNExCQGkbrxAQIEGhKAQEpw7YLSBk2TckCkjXQMAEBqWG0TkyAAIGmFBCQMmy7gJRh05QsIFkDDRMQkBpG68QECBBoSgEBKcO2C0gZNk3JApI10DABAalhtE5MgACBphQQkDJsu4CUYdOULCBZAw0TEJAaRuvEBAgQaEoBASnDtgtIGTZNyQKSNdAwAQGpYbROTIAAgaYUEJAybLuAlGHTlCwgWQMNExCQGkbrxAQIEGhKAQEpw7YLSBk2TckCkjXQMAEBqWG0TkyAAIGmFBCQMmy7gJRh05QsIFkDDRMQkBpG68QECBBoSgEBKcO2C0gZNk3JApI10DABAalhtE5MgACBphQQkDJsu4CUYdOULCBZAw0TEJAaRuvEBAgQaEoBASnDtgtIGTZNyQKSNdAwAQGpYbROTIAAgaYUEJDqaHt\/f3\/s2rUrli1bFvv374\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\/wiLrroopg1a1Zcf\/31ce6555aqRkAqxeSgCgukN7RTl99f4QqVlpNAWk8eBEZS4MCBAyN5OuciQCAzAQHpDDbshRdeiJtvvjk2b94cV111VVx++eXxrW99K3p7e+Oaa66Jrq6uOOecc4atSEAalsgBFRcQkCreoMzKs54ya1jFyzWRrHiDlEfgDAgISGcAufYS27dvj4ULF8YNN9xQ\/NfS0hL9\/f3xxS9+sfjvtttui3e+853DViQgDUt01g74yle+Eh\/84AfP2uvn8sLe0JbrlPVUzsl6KudkPZVzEpDKOZ2N9yLlKqvWUZyq1Y+y1QhIZaVe4nFHjx4twtEPfvCDuOeee+KSSy45dsaf\/OQnce2118Yb3vCGWLVqVbS2tg75amfjD1t6TZdEDb8IvAEZ3igd4Q1tOSfrqZyT9VTOyXoq5yQglXM6G+9FylVWraM4VasfZasRkMpKvcTjnnrqqbjuuutizJgx0d3dXfxaexw+fDhmz54dv\/zlL+Puu++OtrY2Aeklep+tp3sDUk7eG9pyTtZTOSfrqZyT9VTOSUAq5+SNP6dyAnkeJSCdob7VpkR\/9Ed\/FJ\/\/\/OeLy+tqj3SZ3cc+9rH4p3\/6p2K69JrXvEZAOkN9GemX8QaknKg3tOWcrKdyTtZTOSfrqZyTgFTOSUDiVE4gz6MEpDPUt0cffTRmzpwZV1xxRXEZ3YmPdPndzp07Y\/369TFp0iQB6Qz1ZaRfxhuQcqLe0JZzsp7KOVlP5Zysp3JOdkUs5+So8gJ2RSxvVZUjBaQz1ImRDkhnqOwBL3PkddPPxst6TQIECBAgQIBAlgKtP3s0fvv\/+z9ntHaB7KVzC0gv3bDUGUYyIJV6QQcRIECAAAECBAgQIFC3gIBUN9npPaHMd5C+\/\/3vn7TD3em9mmcRIECAAAECBAgQIHA6AgLS6aidxnNqu9i98pWvjLVr18b5559\/7Cz17mJ3Gi\/vKQQIECBAgAABAgQIlBAQkEogjcQhI3kfpJGoxzkIECBAgAABAgQIEDhZQEA6g6ti+\/btxc1ib7jhhuK\/tNV32uJ7xYoV8aUvfSluu+22eOc733kGK\/JSBAgQIECAAAECBAgcLyAgncH18MILL8TNN98cmzZtiiuvvDLe8Y53xLe+9a3o7e2Na665Jrq6uuKcc845gxV5KQIECBAgQIAAAQIEBKSzuAaOHDkSa9asia9+9avxi1\/8Ii666KKYNWtWXH\/99XHuueeexcq8NAECBAgQIECAAAECJkjWAAECBAgQIECAAAECBP5NQECyFAgQIECAAAECBAgQICAgWQMECBAgQIAAAQIECBAYKGCCZEUQIECAAAECBAgQIEDABMkaOFFg\/\/798elPfzp+8IMfFL\/1hje8IZYuXRqvfe1rS2EtX7487rjjjkGPnTZtWqxatarUeXI86KXa5fgzn1hz2oCkp6cn7rrrrtPagCTdK2zBggXxd3\/3d4NyLF68OObNmzcaqOr6GdavX1\/cBmDjxo0xbty4up47Gg5+8skn40Mf+lC8973vLd1\/a+nXnU87p27durXYGOiJJ54o\/r\/29vbiz9nUqVPjZS972WhYIsP+DI8\/\/nisXLkyvv3tb8dzzz0X5513XrGL7Cc+8YkYP378sM+3nn5N9OKLLxa77n7hC1+IAwcORGtra7z1rW8tHMu+TxgWO4MDDh48GLfeemt8\/etfL9bTxRdfXGy29cEPfrDUZlvWUwZNjggTpDz61PAqH3744ZgzZ07xhzvtqJce6U1Z+gf2zjvvjMmTJw9ZQ+0P\/K5du+KKK66Il7\/85QOOnzRpUnzgAx9o+M9xNl7gpdqdjZpH+jVrW9hv3rw5rrrqqrj88svr3sL+6aefLv6R+fnPfx7\/5b\/8l\/jt3\/7tAWWmddXR0THSpVf6fMevrXR7gGYLSLV1lcJhPQHZWvp1OEq3lUh2r3vd62LGjBnFWv\/yl78c+\/bti2uvvTY+9alPFW9yR\/Oj9mcofYBz9dVXx5ve9KZ46KGHIv1dlYJS+kDnsssuG5LAeorino233357ETT\/8A\/\/sFhPKRzU8z5hNKyz9EFDeo\/0s5\/9rFhPr3\/962Pnzp113a7FespjJQhIefSpoVUePnw4Zs+eXbwxXbduXfz+7\/9+8Xo\/\/elPi09u0\/9OfzEOtQ157Q\/87\/7u7xbHnhiQGvoDnMWTj4TdWSx\/xF76VDdB\/uIXvxjpvzI3Qf7JT35SvGn7kz\/5k1iyZMmI1ZbridIbu\/\/+3\/97pE8r06f+zRaQ0hvadBPt9HdSenNWT0CyliL+6Z\/+qfjAIU3eli1bduweeyk4pRuWP\/DAA8Wb2xQYRuvj+eefj\/nz58d3v\/vdIgi98Y1vPPaj7t69u\/hQ8O1vf3txdcNQQdF6iiJUz5w5s5gUpYnkmDFjCsv0\/6f3CSk0Dfc+Ifd1lv4eqt3LMq2ZdD\/L9Ej\/f7raZsOGDf6ty73Jx9UvII2iZp7uj5I+TfvIRz5SvDm96aabBpwmXTZ3zz33DPsP6WOPPVY8\/z3veU9TvbkdCbvT7VtVnpemh+kNV7o0M62VSy655FhptTcW6XLN4d6EfOc73ymCevpUu\/Zpd1V+xjNZR+1Sxf\/5P\/9nnH\/++cUk7bd+67eaKiClS1bTZTt79+4tPt3\/4Q9\/WFdAspaiCJZ\/\/dd\/XVwO9a53vWvAEt6xY0fMnTu3LtMz+WdgpF4rXZ754Q9\/uPhztHbt2uLX2qP24dahQ4eG\/bNlPUVx6XO6BD\/9uZw+ffppOY5UX8\/WeZ599tni37pf\/vKXxdcJLrzwwmOl1PNnyno6Wx2s73UFpPq8RuXR6ZKL9BdfuqY2BZzjH7U\/9OnTkaHetDbrH\/iRsMt9UT311FNx3XXXFZ8odnd3H\/tkMf1ctTch6R+Uu+++O9ra2k754ybLz3zmM8UbmSlTpuTOctr11\/7MpctS0yf\/XV1dUeZN3Gm\/YMWeWFszjzzySNx4443F9f1\/\/ud\/XtebeWtp6KbW82auYstjxMqpJyBZT6dmTyE0fTj6O7\/zO8WU7vjQMGLNyuBEf\/u3f1v8+5UuQTw+QA5WuvWUQUN9BymPJjW6ytqUKH3ieOJ3jdJlPml8nv7AD3XZU\/oDn0JUmkR973vfKz75TV8ATl\/g\/OQnPxmXXnppo3+Ms3L+kbA7K4WP4IvWpkR\/9Ed\/FJ\/\/\/OejpaXl2NnTpQcf+9jHist90nTpNa95zSlfOa2vr33ta8UXXb\/xjW8UXwJOl3WmS4TSp3a\/93u\/N4JVV\/dU6cOG\/\/2\/\/3dxnXv6UnSaqjVbQLrlllvimmuuKS7nOZ0389bSqdd37TKh9OcxXfp64nSpun8yRray2iVj6d+mE6dLJ76S9XSyfVpH6e\/+9CHOP\/7jPxbvD1JQarZHuozz3nvvjb\/6q7+KCRMmFCFx7NixQzJYT3msEhOkPPrU0CrTm8\/0JcO0W1b61Pr4x6OPPlpcd5y+ID\/ULnQf\/\/jHj33ptfbFxXTd93333Ve8yS2z0UNDf8gGnXwk7BpU2hk77XBrZCijWpG\/+tWv4s\/+7M+KIPWqV72qmFamf2zSukxvkP\/9v\/\/3xQ556bs4zfSo51Pu0epSb0CyloZeCXv27Cm+m5R2b0sfig33Zm40rqv0Pay\/\/Mu\/LHb4S98pSf\/GnephPZ0sU\/tQrK+vr7gEOE1605pqll0RayLH79ybPvxL3+kbbldE6ymfv1EEpHx61bBKX+qb\/PSdiRSQUiBK1+UeP4VKW4Km86ddlNIb3NoXOxv2w5zhE79UuzNcbkNebiQCUrpMLwWkdI13+gSuFoSO3zkpfSF2uO8xNeQHPIsnFZCi7gmStXTqBZu2u\/7TP\/3TYsvv9Hd12qCg2R5pKps2GUjT7rTVd7q0fKgNiKynk1dI2jgm\/XufgmZtV8S0S20Km+ecc07TLKn04U36Du7xuyKmD4PTznanelhP+SwPASmfXjWs0ka+ya9t\/\/3ggw8Wn1YOt114w37IBp24kXYNKnnETzsSAWmoomo7JKZr3dOWxcN9QjfiP+BZPKGAVH9AspYGF0gb6aSNGdLlmsfvwHUWl\/cZf+n0hj4FohSQ0uXfx+\/GdjrFNPPfTTWv9AHpokWL4u\/\/\/u\/jb\/7mbyLd87AZH+k9TrpP38SJE0\/7w2DrqVorR0CqVj8aVk36hyB9efD4xx\/\/8R8X116n3bLS9ehDfQdpsB3uyhab\/kFK3ylIW4COtuvdy3wH6aXYlTU+m8eV+Q7S97\/\/\/ZN2uCtbc+17TOk698EuAy17nhyPE5BGNiA161pKn3CnjS7SfWvSznbpe33Hf1cwxz8b9dac3sinL9GnD1ne9ra3xerVq1\/yhgLNup5OtK9t0pQ2eRrNN4Qfas2l7yKlDyDSbq6n+++U9VTvn+rGHi8gNda3MmcfKiBt27at2MVusABTdhe7dNlCurZ2sEvoUohIY+d0Scdou9FnbRe7l2JXmUVymoXUdrF75StfecqtdMvsYpc+3U0Tx7Qb0vGP2hTyn\/\/5n4ud8Ia7qeNp\/hiVfJqAdHoByVr6zXL+5je\/WXzCny59Sm9em3GHyGeeeSY6Ozvj\/vvvj6lTpxZB6fgtv4f7w289DS003FUEw\/mOlt8v833b9LNaT3l0XEDKo08NrfKl3sundg+kwXYDSp\/apU9VfvzjH5\/2BKGhP\/xLPPlLtXuJL1+Jp4\/EfZBqn0BeddVVxc1Bj\/90u5m3kRWQ6g9I1tJv\/lpIN3BO97Y777zziisFRvNNYU\/1l2EKR+lmsekSqPe\/\/\/3FfdaG+s7RqaYjzf53U9qtLn2Ymm78na4+Of6RPkj96Ec\/Wtx498R7KVbiH6kRKiLdny2tpbQhQ7oq5vibC9f+rv7pT3865Hsdfz+NUDPOwGkEpDOAXPWXqP3B\/vnPf15cZvf7v\/\/7RcnpC73p\/jYp+Ax1h+xaCEpf2jzx2va0\/WXa4SZ9avfZz352yLuVV91psPpeql2OP\/NgNac3YunTsxtuuKH4LwWcdLlACjtpZ5+0nfA73\/nOU\/64tRCUrsE+fsfDdI70D3L6x2jx4sXFNd7N9BCQ6g9I1tKv\/4TU\/v5Ol\/6M1l1Eh\/u7oPZ3UPr3K4WjdE+xejcRsJ5+rfwP\/\/APRQhKQTGFpZpjCqBp449\/+Zd\/Oe1Ly4brY1V+v\/ZeJ92jLW0m9MY3vvFYaWXf61hPVenm8HUISMMbNcUR6X5H6dOf9JdeupdReqQ3tmkUfOI\/rumNcPok6fjLymrPT3+B1Lb5fuCBB4ptvl\/96lcX5xitWzTXYzdaF1NaJ2kHo02bNkXabS7tDvWtb30r0i6G6X42x78xqb3pT\/chOf5a7dqOh+nSl9o232md7dq1Ky6\/\/PLiy9WjbRfE4daDgDR0QLKWTr2C0mVk6eaVaYv8t7zlLYMemG7fMNouez7+B\/3Rj35UfMiXPnhJO\/ZddNFFJzmkS4PTG\/\/0q\/V06vVU+zs+fYcr7Uqb\/o5O32lLu9Om7b7TB6EpKI3277bV817HehruX7hq\/76AVO3+nNHqfvjDHxY3e0s3eU2PN7zhDcXNX9PNGo9\/DBaQ0u+nrT\/Tm9ivf\/3rxV+c6R+j973vfcVI+oILLjijP8uZfrGydme6rjP5eikcp++6ffWrX41f\/OIXRf\/TvTHSDU+Pv6TlVP9opFrTJQyf+9znIn3fKP2DfPHFFxfnSDePreeymDP5czfytQSk0wtIzb6Wausm3bR7qMdon8rWvkM7lEH64C59sDNu3LhTBqRmX081v\/R3crp3VPp7Pm0V\/1u\/9Vvxn\/\/zfy7C0Zvf\/OZRH45qDmk6mza9+va3vz3kex3\/1jXyX8fGn1tAaryxVyBAgAABAgQIECBAIBMBASmTRimTAAECBAgQIECAAIHGCwhIjTf2CgQIECBAgAABAgQIZCIgIGXSKGUSIECAAAECBAgQINB4AQGp8cZegQABAgQIECBAgACBTAQEpEwapUwCBAgQIECAAAECBBovICA13tgrECBAgAABAgQIECCQiYCAlEmjlEmAAAECBAgQIECAQOMFBKTGG3sFAgQIECBAgAABAgQyERCQMmmUMgkQIECAAAECBAgQaLyAgNR4Y69AgAABAgQIECBAgEAmAgJSJo1SJgECBAgQIECAAAECjRcQkBpv7BUIECBAgAABAgQIEMhEQEDKpFHKJECAAAECBAgQIECg8QICUuONvQIBAgQIECBAgAABApkICEiZNEqZBAgQIECAAAECBAg0XkBAaryxVyBAgAABAgQIECBAIBMBASmTRimTAAECBAgQIECAAIHGCwhIjTf2CgQIECBAgAABAgQIZCIgIGXSKGUSIECAAAECBAgQINB4AQGp8cZegQABAgQIECBAgACBTAQEpEwapUwCBAgQIECAAAECBBovICA13tgrECBAgAABAgQIECCQiYCAlEmjlEmAAAECBAgQIECAQOMFBKTGG3sFAgQIECBAgAABAgQyERCQMmmUMgkQIECAAAECBAgQaLyAgNR4Y69AgAABAgQIECBAgEAmAgJSJo1SJgECBAgQIECAAAECjRcQkBpv7BUIECBAgAABAgQIEMhEQEDKpFHKJECAAAECBAgQIECg8QL\/PxW\/ZcUpS7ybAAAAAElFTkSuQmCC","height":337,"width":560}}
%---
%[output:7340f42c]
%   data: {"dataType":"error","outputData":{"errorType":"runtime","text":"Unrecognized function or variable 'P'."}}
%---
