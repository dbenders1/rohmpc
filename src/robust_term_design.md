# Robust and terminal ingredients design
Contents:\
[High-level information](#high-level-information)\
[Reproduce computing robust and terminal ingredients](#reproduce-computing-robust-and-terminal-ingredients)



## High-level information
- Purpose: compute the robust ingredients:
  - Metric $P^\delta$
  - Robust feedback gain $K^\delta$
  - System constraint tightening constants $c_j^\mathrm{s}, j\in\mathbb{N}_{[1,n^\mathrm{s}]}$
  - Obstacle avoidance constraint tightening constants $c^\mathrm{o}$
  
  and terminal ingredients:
  - Terminal cost matrix $P$
- Inputs: model parameters and estimated disturbance and measurement noise bounds stored in [falcon_t.mat](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.mat).
- Outputs: robust and terminal ingredients stored in [offline_design.mat](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp/offline_design.mat).



## Reproduce computing robust and terminal ingredients
The result of the robust and terminal ingredients design is stored in [offline_design.mat](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp/offline_design.mat). To reproduce this file, run [main.m](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp/main.m) in MATLAB.

There are several hyperparameters that you can play around with that affect the design:
- [main.m](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp/main.m):
  - Contraction rate $\rho$ - indicates how fast the closed-loop system under feedback gain $K^\delta$ should stabilize.
- [FalconModelT.m](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp/FalconModelT.m):
  - Observer gain $L$ - used to implement the observer; choose this value several times larger than $\rho$.
  - TMPC tuning matrices $Q$ and $R$ - used to tune the TMPC cost function. These values only affect the design of $P$.
    > :bulb: By the ROHMPC design in this paper, there is no need to spend a lot of time on tuning $Q$ and $R$ for the scheme to work. Therefore, they are set to identity matrices.

:white_check_mark: Yes, yes, the next step is also done! You have successfully completed the robust and terminal ingredients design! Let's continue with the [tightening calibration](./tightening_calib.md)!
