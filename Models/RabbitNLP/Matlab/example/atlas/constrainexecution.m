% if you have the parallel toolbox, time constrain the execution

legsonly = false; % copy default FROST Atlas model
p = parpool(1);
try
    F = parfeval(p, @configureatlas, 1, legsonly);
    
    fprintf("F is %s\n", F.State);
    while(strcmp(F.State, 'queued')); end
    fprintf("F is now %s\n", F.State);
    
    cur = 0;
    nb = fprintf("\telapsed time: %f s\n", cur);
    limit = 24 * 3600;
    updates = limit / 24 / 360;
    start = tic();
    while cur < limit && strcmp(F.State, 'running')
        cur = toc(start);
        % should leave commented, but good one-time check to see if code is
        % running
        
        %fprintf("F: %s\n", F.Diary);
        
        if mod(floor(cur), updates) == 0
            fprintf(repmat('\b', 1, nb));
            nb = fprintf("\telapsed time: %f s\n", cur);
        end
    end
    
    if cur >= limit
        cancel(F)
        fprintf("F: %s\n", F.Error.message);
    end
    
    fprintf("F: %s\n", F.Diary);
    
    fprintf("duration of F: %f (%f)\n", fetchOutputs(F), cur);
catch
    fprintf("an error occurred in the try block.");
end

delete(p);