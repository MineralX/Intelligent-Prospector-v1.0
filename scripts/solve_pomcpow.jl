using Revise

using POMDPs
using POMDPSimulators
using POMCPOW
using Plots
using ParticleFilters

# using ProfileView
using D3Trees

using MineralExploration

N_INITIAL = 0
MAX_BORES = 10

m = MineralExplorationPOMDP(max_bores=MAX_BORES, delta=1)
initialize_data!(m, N_INITIAL)

ds0 = POMDPs.initialstate_distribution(m)
s0 = rand(ds0)

up = MEBeliefUpdater(m, 1000)
println("Initializing belief...")
# b0 = POMDPs.initialize_belief(up, ds0)
println("Belief Initialized!")
next_action = NextActionSampler(b0, up)

solver = POMCPOWSolver(tree_queries=1000,
                       check_repeat_obs=true,
                       check_repeat_act=true,
                       next_action=next_action,
                       k_action=3,
                       alpha_action=0.25,
                       k_observation=2,
                       alpha_observation=0.25,
                       criterion=POMCPOW.MaxUCB(10.0),
                       # estimate_value=POMCPOW.RolloutEstimator(ExpertPolicy(m))
                       # estimate_value=POMCPOW.RolloutEstimator(MineralExploration.RandomSolver())
                       estimate_value=0.0
                       )
planner = POMDPs.solve(solver, m)

# @profview POMCPOW.action_info(planner, b0, tree_in_info=true)
# @profview POMCPOW.action_info(planner, b0, tree_in_info=true)
# volumes = [sum(b.ore_map[:,:,1] .>= m.massive_threshold) for b in b0.particles.particles]
# mean(volumes)
# MineralExploration.std(volumes)
println("Building test tree...")
a, info = POMCPOW.action_info(planner, b0, tree_in_info=true)
tree = info[:tree]
inbrowser(D3Tree(tree, init_expand=1), "firefox")

println("Plotting...")
fig = heatmap(s0.ore_map[:,:,1], title="True Ore Field", fill=true, clims=(0.0, 1.0))
# savefig(fig, "./data/example/ore_vals.png")
display(fig)

s_massive = s0.ore_map[:,:,1] .>= 0.7

fig = heatmap(s_massive, title="Massive Ore Deposits", fill=true, clims=(0.0, 1.0))
# savefig(fig, "./data/example/massive.png")
display(fig)

fig = plot(b0)
display(fig)

b_new = nothing
discounted_return = 0.0
println("Entering Simulation...")
for (sp, a, r, bp, t) in stepthrough(m, planner, up, b0, s0, "sp,a,r,bp,t", max_steps=50)
    global discounted_return
    global b_new
    b_new = bp
    @show t
    @show a
    @show r
    @show sp.stopped
    @show bp.stopped


    fig = plot(bp, t)
    str = "./data/example/belief_$t.png"
    # savefig(fig, str)
    display(fig)
    discounted_return += POMDPs.discount(m)^(t - 1)*r
end
println("Episode Return: $discounted_return")
