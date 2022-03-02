function simulation=simulatePOMDP(results)

real_world     = results.pomdp;
internal_model = results.pomdp;

%% ------------------------------------------------------------------------
%   Loading the alpha vectors
%% ------------------------------------------------------------------------

fid = fopen([results.log.config_file(1:end-6) '-solution.alpha']);
% => see http://pomdp.org/code/alpha-file-spec.html

A = fscanf(fid,'%d%f%f') ;
A = reshape(A,3,numel(A)/3);

fclose(fid) ;

alpha_action = A(1,:);
alpha_vector = A(2:3,:);

%%

%initial state 
state = randi(2,1) ;
% random belief
belief = [.5 .5]' ; % p(s = tiger-left) p(s = tiger-right)

N = 30;
for t = 1:N
    
    % combute alpha value of all action given current belief
    utility =  alpha_vector' * belief;
    
    % select action associated with best alpha value
    action = alpha_action(utility==max(utility))+1;
    
    % update real world accordingly
    next_state_distrib = real_world.transition(:,state,action) ;
    next_state = find(cumsum(next_state_distrib) > rand,1) ;
    
    % find corresponding observation
    observation_distrib = real_world.observation(next_state,action,:) ;
    observation = find(cumsum(observation_distrib) > rand,1) ;
    
    % find corresponding reward
    reward = real_world.reward3(next_state,state,action) ;
        
    % update belief
    prior_next = internal_model.transition(:,:,action) * belief ;
    posterior_next = internal_model.observation(:,action,observation) .* prior_next;
    next_belief = posterior_next / sum(posterior_next);
   
    % store
    simulation.state(t)  = state;
    simulation.belief(:,t) = belief;
    simulation.action(t) = action;
    simulation.observation(t) = observation;
    simulation.reward(t) = reward;
    
    % update
    state = next_state ;
    belief = next_belief ;
    
    if action>1
        break;
    end
    
end


%%

figure

n=numel(simulation.state);
plot(simulation.belief(2,:))

hold on
plot(simulation.state-1,'k')

plot(simulation.observation(1:end-1)-1,'go')

xlabel('')
ylabel('belief')

set(gca, ...
    'XLim',[.9 n+.1], ...
    'YLim',[-.1 1.1], ...
    'XTick',1:n , ...
    'XTickLabel',mat2cell(results.pomdp.actions(simulation.action,:),ones(1,n),10), ...
    'XTickLabelRotation', 0, ...
    'YTick',0:1, ...
    'YTickLabel',mat2cell(results.pomdp.states,[1 1],11) ...
    );

pretty.plot('simulation',[8 8])

legend({'belief','state','observation'},'Location','East')


