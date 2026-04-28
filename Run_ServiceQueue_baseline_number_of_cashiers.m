%[text] # Run samples of the ServiceQueue simulation John McMann
%[text] Collect statistics and plot histograms along the way.
%%
%[text] ## Set up
%[text] We'll measure time in 5 minutes intervals
%[text] Arrival rate: 1 per 75 seconds, so 4 per 5 minutes
lambda = 4;
%[text] Departure (service) rate: 1 per 6.5 minutes, so 10/13 per 5 minutes
mu = 10/13;
%[text] Run 100 samples of the queue.
NumSamples = 100;
%[text] Each sample is run up to a maximum time of 4 hours.
MaxTime = 48;
%[text] Make a log entry every so often
LogInterval = 1;
%%
%[text] ## Numbers from theory for M/M/s queue
%[text] Compute `P(1+n)` = $P\_n$ = probability of finding the system in state $n$ in the long term.
sMax = 8;
rng("default");
for s = 1:sMax
    r = lambda / mu;
    rho = r / s;

    if rho >= 1
        continue;
    end

QSamples = cell([NumSamples, 1]);

for SampleNum = 1:NumSamples
    q = ServiceQueue( ...
        ArrivalRate=lambda, ...
        DepartureRate=mu, ...
        NumServers=s, ...
        LogInterval=LogInterval);
    q.schedule_event(Arrival(random(q.InterArrivalDist), Customer(1)));
    run_until(q, MaxTime);
    QSamples{SampleNum} = q;
end
NumInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end

NumWaitingSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumWaitingSamples{SampleNum} = q.Log.NumWaiting;
end

NumInSystem = vertcat(NumInSystemSamples{:});

NumWaitingSystem = vertcat(NumWaitingSamples{:});

TimeInSystemSamples = cellfun( ...
    @(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);

WaitingTimeSamples = cellfun( ...
    @(q) cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);

TimeInSystem = vertcat(TimeInSystemSamples{:});

WaitingTime = vertcat(WaitingTimeSamples{:});

NumWaitingMore5 = mean(WaitingTime > 1);

if NumWaitingMore5 > 0.10
    continue;
end

break
end
fprintf("Optimal number of Registers in system: %f\n", s); %[output:317147d0]
fprintf("Percent of customers waiting more than 5 minutes in system: %f\n", NumWaitingMore5*100); %[output:801c7d43]
s=s-1;
QSamples = cell([NumSamples, 1]);

for SampleNum = 1:NumSamples
    q = ServiceQueue( ...
        ArrivalRate=lambda, ...
        DepartureRate=mu, ...
        NumServers=s, ...
        LogInterval=LogInterval);
    q.schedule_event(Arrival(random(q.InterArrivalDist), Customer(1)));
    run_until(q, MaxTime);
    QSamples{SampleNum} = q;
end
NumInSystemSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumInSystemSamples{SampleNum} = q.Log.NumWaiting + q.Log.NumInService;
end

NumWaitingSamples = cell([NumSamples, 1]);
for SampleNum = 1:NumSamples
    q = QSamples{SampleNum};
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NumWaitingSamples{SampleNum} = q.Log.NumWaiting;
end

NumInSystem = vertcat(NumInSystemSamples{:});

NumWaitingSystem = vertcat(NumWaitingSamples{:});

TimeInSystemSamples = cellfun( ...
    @(q) cellfun(@(c) c.DepartureTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);

WaitingTimeSamples = cellfun( ...
    @(q) cellfun(@(c) c.BeginServiceTime - c.ArrivalTime, q.Served'), ...
    QSamples, ...
    UniformOutput=false);

TimeInSystem = vertcat(TimeInSystemSamples{:});

WaitingTime = vertcat(WaitingTimeSamples{:});

NumWaitingMore5 = mean(WaitingTime > 1);
fprintf("One less than optimal number of registers in system: %f\n", s); %[output:5c08b26c]

fprintf("Percent of customers waiting more than 5 minutes in system: %f\n", NumWaitingMore5*100); %[output:766c72f8]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:317147d0]
%   data: {"dataType":"text","outputData":{"text":"Optimal number of Registers in system: 7.000000\n","truncated":false}}
%---
%[output:801c7d43]
%   data: {"dataType":"text","outputData":{"text":"Percent of customers waiting more than 5 minutes in system: 7.903349\n","truncated":false}}
%---
%[output:5c08b26c]
%   data: {"dataType":"text","outputData":{"text":"One less than optimal number of registers in system: 6.000000\n","truncated":false}}
%---
%[output:766c72f8]
%   data: {"dataType":"text","outputData":{"text":"Percent of customers waiting more than 5 minutes in system: 24.674973\n","truncated":false}}
%---
