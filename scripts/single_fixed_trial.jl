using Revise

using POMDPs
using POMCPOW
using Plots
using Statistics

using MineralExploration

N_INITIAL = 0
MAX_BORES = 20
GRID_SPACING = 1
MAX_MOVEMENT = 0

# mainbody = MultiVarNode()
mainbody = SingleFixedNode()

m = MineralExplorationPOMDP(max_bores=MAX_BORES, delta=GRID_SPACING+1, grid_spacing=GRID_SPACING,
                            mainbody_gen=mainbody, max_movement=MAX_MOVEMENT)
initialize_data!(m, N_INITIAL)

up = MEBeliefUpdater(m, 1000, 2.0)

next_action = NextActionSampler()
solver = POMCPOWSolver(tree_queries=10000,
                       check_repeat_obs=true,
                       check_repeat_act=true,
                       next_action=next_action,
                       k_action=2.0,
                       alpha_action=0.25,
                       k_observation=2.0,
                       alpha_observation=0.1,
                       criterion=POMCPOW.MaxUCB(100.0),
                       final_criterion=POMCPOW.MaxQ(),
                       # final_criterion=POMCPOW.MaxTries(),
                       estimate_value=0.0
                       # estimate_value=leaf_estimation
                       )
planner = POMDPs.solve(solver, m)

run_trial(m, up, planner, save_dir="./data/single_fixed_demo/")