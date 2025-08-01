// RUN: mlir-opt --pass-pipeline="builtin.module(func.func(sharding-propagation,cse))" %s | FileCheck %s

mesh.mesh @mesh_2(shape = 2)
mesh.mesh @mesh_1d(shape = ?)
mesh.mesh @mesh_2d(shape = 2x4)
mesh.mesh @mesh_3d(shape = ?x?x?)

// CHECK-LABEL: func.func @element_wise_empty_sharding_info
func.func @element_wise_empty_sharding_info(%arg0: tensor<8x16xf32>) -> tensor<8x16xf32> {
  // CHECK-NEXT: tosa.sigmoid
  %0 = tosa.sigmoid %arg0 : (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT: return
  return %0 : tensor<8x16xf32>
}

// CHECK-LABEL: func.func @element_wise_on_def
// CHECK-SAME:    %[[ARG:.*]]: tensor<8x16xf32>
func.func @element_wise_on_def(%arg0: tensor<8x16xf32>) -> tensor<8x16xf32> {
  // CHECK-NEXT:  %[[S0:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}0], [1]] : !mesh.sharding
  // CHECK-NEXT:  %[[V0:.*]] = mesh.shard %[[ARG]] to %[[S0]] annotate_for_users  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V1:.*]] = tosa.sigmoid %[[V0]]
  %0 = tosa.sigmoid %arg0 : (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT:  %[[V2:.*]] = mesh.shard %[[V1]] to %[[S0]]  : tensor<8x16xf32>
  %s1 = mesh.sharding @mesh_2d split_axes = [[0], [1]] : !mesh.sharding
  %1 = mesh.shard %0 to %s1  : tensor<8x16xf32>
  // CHECK-NEXT:  return %[[V2]]
  return %1 : tensor<8x16xf32>
}

// CHECK-LABEL: func.func @element_wise_on_use
// CHECK-SAME:    %[[ARG:.*]]: tensor<8x16xf32>
func.func @element_wise_on_use(%arg0: tensor<8x16xf32>) -> tensor<8x16xf32> {
  // CHECK-NEXT:  %[[S0:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}0], [1]] : !mesh.sharding
  // CHECK-NEXT:  %[[V0:.*]] = mesh.shard %[[ARG]] to %[[S0]] annotate_for_users  : tensor<8x16xf32>
  %s0 = mesh.sharding @mesh_2d split_axes = [[0], [1]] : !mesh.sharding
  %0 = mesh.shard %arg0 to %s0 annotate_for_users  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V1:.*]] = tosa.sigmoid %[[V0]]
  %1 = tosa.sigmoid %0 : (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT:  %[[V2:.*]] = mesh.shard %[[V1]] to %[[S0]]  : tensor<8x16xf32>
  // CHECK-NEXT:  return %[[V2]]
  return %1 : tensor<8x16xf32>
}

// CHECK-LABEL: func.func @element_wise_on_graph_output
// CHECK-SAME:    %[[ARG:.*]]: tensor<8x16xf32>
func.func @element_wise_on_graph_output(%arg0: tensor<8x16xf32>) -> tensor<8x16xf32> {
  // CHECK-NEXT:  %[[S0:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}0], [1]] : !mesh.sharding
  // CHECK-NEXT:  %[[V0:.*]] = mesh.shard %[[ARG]] to %[[S0]] annotate_for_users  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V1:.*]] = tosa.sigmoid %[[V0]]
  %0 = tosa.sigmoid %arg0 : (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT:  %[[V2:.*]] = mesh.shard %[[V1]] to %[[S0]]  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V3:.*]] = mesh.shard %[[V2]] to %[[S0]] annotate_for_users  : tensor<8x16xf32>
  %s1 = mesh.sharding @mesh_2d split_axes = [[0], [1]] : !mesh.sharding
  %1 = mesh.shard %0 to %s1 annotate_for_users  : tensor<8x16xf32>
  // CHECK-NEXT:  return %[[V3]]
  return %1 : tensor<8x16xf32>
}

// CHECK-LABEL: func.func @element_wise_on_graph_input
// CHECK-SAME:    %[[ARG:.*]]: tensor<8x16xf32>
func.func @element_wise_on_graph_input(%arg0: tensor<8x16xf32>) -> tensor<8x16xf32> {
  // CHECK-NEXT:  %[[S0:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}0], [1]] : !mesh.sharding
  // CHECK-NEXT:  %[[V0:.*]] = mesh.shard %[[ARG]] to %[[S0]]  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V1:.*]] = mesh.shard %[[V0]] to %[[S0]] annotate_for_users  : tensor<8x16xf32>
  %s0 = mesh.sharding @mesh_2d split_axes = [[0], [1]] : !mesh.sharding
  %0 = mesh.shard %arg0 to %s0  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V2:.*]] = tosa.sigmoid %[[V1]]
  %1 = tosa.sigmoid %0 : (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT:  %[[V3:.*]] = mesh.shard %[[V2]] to %[[S0]]  : tensor<8x16xf32>
  // CHECK-NEXT:  return %[[V3]]
  return %1 : tensor<8x16xf32>
}

// CHECK-LABEL: func.func @arrow_structure
// CHECK-SAME:    %[[ARG:.*]]: tensor<8x16xf32>
func.func @arrow_structure(%arg0: tensor<8x16xf32>, %arg1: tensor<1xf32>, %arg2: tensor<1xf32>) -> (tensor<8x16xf32>, tensor<8x16xf32>) {
  // CHECK-NEXT:  %[[S1:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}0], [1]] : !mesh.sharding
  // CHECK-NEXT:  %[[V1:.*]] = mesh.shard %[[ARG]] to %[[S1]] annotate_for_users  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V2:.*]] = tosa.tanh %[[V1]]
  // CHECK-NEXT:  %[[V3:.*]] = mesh.shard %[[V2]] to %[[S1]]  : tensor<8x16xf32>
  %0 = tosa.tanh %arg0 : (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT:  %[[V4:.*]] = mesh.shard %[[V3]] to %[[S1]] annotate_for_users  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V5:.*]] = tosa.abs %[[V4]]
  // CHECK-NEXT:  %[[V6:.*]] = mesh.shard %[[V5]] to %[[S1]]  : tensor<8x16xf32>
  %1 = tosa.abs %0: (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT:  %[[S3:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}]] : !mesh.sharding
  // CHECK-NEXT:  %[[ZP1:.*]] = mesh.shard %arg1 to %[[S3]] annotate_for_users : tensor<1xf32>
  // CHECK-NEXT:  %[[ZP2:.*]] = mesh.shard %arg2 to %[[S3]] annotate_for_users : tensor<1xf32>
  // CHECK-NEXT:  %[[V7:.*]] = tosa.negate %[[V4]], %[[ZP1]], %[[ZP2]]
  // CHECK-NEXT:  %[[V8:.*]] = mesh.shard %[[V7]] to %[[S1]]  : tensor<8x16xf32>
  %2 = tosa.negate %0, %arg1, %arg2 : (tensor<8x16xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<8x16xf32>
  %s3 = mesh.sharding @mesh_2d split_axes = [[0], [1]] : !mesh.sharding
  %3 = mesh.shard %2 to %s3  : tensor<8x16xf32>
  // CHECK-NEXT: return %[[V6]], %[[V8]]
  return %1, %3 : tensor<8x16xf32>, tensor<8x16xf32>
}

// CHECK-LABEL: func.func @matmul_on_def_shard_batch_and_m
// CHECK-SAME:     %[[ARG0:.*]]: tensor<2x16x8xf32>, %[[ARG1:.*]]: tensor<2x8x32xf32>, %[[ARG2:.*]]: tensor<1xf32>
func.func @matmul_on_def_shard_batch_and_m(%arg0: tensor<2x16x8xf32>, %arg1: tensor<2x8x32xf32>, %arg2: tensor<1xf32>) -> tensor<2x16x32xf32> {
  // CHECK-NEXT:  %[[S0:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}0], [1]] : !mesh.sharding
  // CHECK-NEXT:  %[[V0:.*]] = mesh.shard %[[ARG0]] to %[[S0]] annotate_for_users  : tensor<2x16x8xf32>
  // CHECK-NEXT:  %[[S1:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}0]] : !mesh.sharding
  // CHECK-NEXT:  %[[V1:.*]] = mesh.shard %[[ARG1]] to %[[S1]] annotate_for_users  : tensor<2x8x32xf32>
  // CHECK-NEXT:  %[[S2:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}]] : !mesh.sharding
  // CHECK-NEXT:  %[[ZP:.*]] = mesh.shard %[[ARG2]] to %[[S2]] annotate_for_users  : tensor<1xf32>
  // CHECK-NEXT:  %[[V2:.*]] = tosa.matmul %[[V0]], %[[V1]], %[[ZP]], %[[ZP]]
  %0 = tosa.matmul %arg0, %arg1, %arg2, %arg2 : (tensor<2x16x8xf32>, tensor<2x8x32xf32>, tensor<1xf32>, tensor<1xf32>)  -> tensor<2x16x32xf32>
  // CHECK-NEXT:  %[[V3:.*]] = mesh.shard %[[V2]] to %[[S0]]  : tensor<2x16x32xf32>
  %s1 = mesh.sharding @mesh_2d split_axes = [[0], [1]] : !mesh.sharding
  %1 = mesh.shard %0 to %s1  : tensor<2x16x32xf32>
  // CHECK-NEXT:  return %[[V3]]
  return %1 : tensor<2x16x32xf32>
}

// CHECK-LABEL: func.func @matmul_on_def_shard_m_and_n
// CHECK-SAME:     [[varg0:%.*]]: tensor<2x16x8xf32>, [[varg1:%.*]]: tensor<2x8x32xf32>, [[varg2:%.*]]: tensor<1xf32>
func.func @matmul_on_def_shard_m_and_n(%arg0: tensor<2x16x8xf32>, %arg1: tensor<2x8x32xf32>, %arg2: tensor<1xf32>) -> tensor<2x16x32xf32> {
  // CHECK: [[vsharding:%.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [0]] : !mesh.sharding
  // CHECK: [[vsharded:%.*]] = mesh.shard [[varg0]] to [[vsharding]] annotate_for_users : tensor<2x16x8xf32>
  // CHECK: [[vsharding_0:%.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [], [1]] : !mesh.sharding
  // CHECK: [[vsharded_1:%.*]] = mesh.shard [[varg1]] to [[vsharding_0]] annotate_for_users : tensor<2x8x32xf32>
  // CHECK: [[vsharding_2:%.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}]] : !mesh.sharding
  // CHECK: [[vsharded_3:%.*]] = mesh.shard [[varg2]] to [[vsharding_2]] annotate_for_users : tensor<1xf32>
  // CHECK: [[v0:%.*]] = tosa.matmul
  %0 = tosa.matmul %arg0, %arg1, %arg2, %arg2 : (tensor<2x16x8xf32>, tensor<2x8x32xf32>, tensor<1xf32>, tensor<1xf32>)  -> tensor<2x16x32xf32>
  // CHECK: [[vsharding_4:%.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [0], [1]] : !mesh.sharding
  // CHECK: [[vsharded_5:%.*]] = mesh.shard [[v0]] to [[vsharding_4]] : tensor<2x16x32xf32>
  %s1 = mesh.sharding @mesh_2d split_axes = [[], [0], [1]] : !mesh.sharding
  %1 = mesh.shard %0 to %s1  : tensor<2x16x32xf32>
  // CHECK-NEXT:  return [[vsharded_5]]
  return %1 : tensor<2x16x32xf32>
}

// CHECK-LABEL: func.func @matmul_on_use_shard_m_and_k
// CHECK-SAME:     [[varg0:%.*]]: tensor<2x16x8xf32>, [[varg1:%.*]]: tensor<2x8x32xf32>, [[varg2:%.*]]: tensor<1xf32>
func.func @matmul_on_use_shard_m_and_k(%arg0: tensor<2x16x8xf32>, %arg1: tensor<2x8x32xf32>, %arg2: tensor<1xf32>) -> tensor<2x16x32xf32> {
  // CHECK: [[vsharding:%.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [0], [1]] : !mesh.sharding
  %s0 = mesh.sharding @mesh_2d split_axes = [[], [0], [1]] : !mesh.sharding
  // CHECK: [[vsharded:%.*]] = mesh.shard [[varg0]] to [[vsharding]] : tensor<2x16x8xf32>
  %arg0_s = mesh.shard %arg0 to %s0 : tensor<2x16x8xf32>
  // CHECK: [[vsharded_0:%.*]] = mesh.shard [[vsharded]] to [[vsharding]] annotate_for_users : tensor<2x16x8xf32>
  // CHECK: [[vsharding_1:%.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [1]] : !mesh.sharding
  // CHECK: [[vsharded_2:%.*]] = mesh.shard [[varg1]] to [[vsharding_1]] annotate_for_users : tensor<2x8x32xf32>
  // CHECK: [[vsharding_3:%.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}]] : !mesh.sharding
  // CHECK: [[vsharded_4:%.*]] = mesh.shard [[varg2]] to [[vsharding_3]] annotate_for_users : tensor<1xf32>
  // CHECK: [[v0:%.*]] = tosa.matmul
  // CHECK: [[vsharding_5:%.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [0]] : !mesh.sharding
  // CHECK: [[vsharded_6:%.*]] = mesh.shard [[v0]] to [[vsharding_5]] : tensor<2x16x32xf32>
  %0 = tosa.matmul %arg0_s, %arg1, %arg2, %arg2 : (tensor<2x16x8xf32>, tensor<2x8x32xf32>, tensor<1xf32>, tensor<1xf32>)  -> tensor<2x16x32xf32>
  // CHECK: return [[vsharded_6]]
  return %0 : tensor<2x16x32xf32>
}

// CHECK-LABEL: func.func @matmul_on_use_shard_m_and_duplicted_k
// CHECK-SAME:     %[[ARG0:.*]]: tensor<2x16x8xf32>, %[[ARG1:.*]]: tensor<2x8x32xf32>, %[[ARG2:.*]]: tensor<1xf32>
func.func @matmul_on_use_shard_m_and_duplicted_k(%arg0: tensor<2x16x8xf32>, %arg1: tensor<2x8x32xf32>, %arg2: tensor<1xf32>) -> tensor<2x16x32xf32> {
  // CHECK-NEXT:  %[[S0:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [1], [0]] : !mesh.sharding
  // CHECK-NEXT:  %[[V0:.*]] = mesh.shard %[[ARG0]] to %[[S0]] annotate_for_users  : tensor<2x16x8xf32>
  %s0 = mesh.sharding @mesh_2d split_axes = [[], [1], [0]] : !mesh.sharding
  %0 = mesh.shard %arg0 to %s0 annotate_for_users  : tensor<2x16x8xf32>
  // CHECK-NEXT:  %[[S1:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [0]] : !mesh.sharding
  // CHECK-NEXT:  %[[V1:.*]] = mesh.shard %[[ARG1]] to %[[S1]] annotate_for_users  : tensor<2x8x32xf32>
  %s1 = mesh.sharding @mesh_2d split_axes = [[], [0]] : !mesh.sharding
  %1 = mesh.shard %arg1 to %s1 annotate_for_users  : tensor<2x8x32xf32>
  // CHECK-NEXT:  %[[S2:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}]] : !mesh.sharding
  // CHECK-NEXT:  %[[ZP:.*]] = mesh.shard %[[ARG2]] to %[[S2]] annotate_for_users  : tensor<1xf32>
  // CHECK-NEXT:  %[[V2:.*]] = tosa.matmul %[[V0]], %[[V1]], %[[ZP]], %[[ZP]]
  %2 = tosa.matmul %0, %1, %arg2, %arg2 : (tensor<2x16x8xf32>, tensor<2x8x32xf32>, tensor<1xf32>, tensor<1xf32>)  -> tensor<2x16x32xf32>
  // CHECK-NEXT:  %[[S3:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}], [1]] : !mesh.sharding
  // CHECK-NEXT:  %[[V3:.*]] = mesh.shard %[[V2]] to %[[S3]]  : tensor<2x16x32xf32>
  // CHECK-NEXT:  return %[[V3]]
  return %2 : tensor<2x16x32xf32>
}

// CHECK-LABEL: func.func @resolve_conflicting_annotations
func.func @resolve_conflicting_annotations(
  // CHECK-SAME: %[[IN1:.*]]: tensor<2x3xf32>,
  %arg0: tensor<2x3xf32>,
  // CHECK-SAME: %[[IN2:.*]]: tensor<3x2xf32>,
  %arg1: tensor<3x2xf32>,
  // CHECK-SAME: %[[OUT_DPS:.*]]: tensor<2x2xf32>
  %out_dps: tensor<2x2xf32>
// CHECK-SAME: ) -> tensor<2x2xf32> {
) -> tensor<2x2xf32> {
  // CHECK: %[[SIN1_SHARDED1:.*]] = mesh.sharding @mesh_2 split_axes = {{\[\[}}0]] : !mesh.sharding
  // CHECK-NEXT:  %[[IN1_SHARDED1:.*]] = mesh.shard %[[IN1]] to %[[SIN1_SHARDED1]]  : tensor<2x3xf32>
  // CHECK: %[[SIN2_SHARDED:.*]] = mesh.sharding @mesh_2 split_axes = {{\[\[}}]] : !mesh.sharding
  // CHECK-NEXT:  %[[IN1_SHARDED2:.*]] = mesh.shard %[[IN1_SHARDED1]] to %[[SIN2_SHARDED]] annotate_for_users  : tensor<2x3xf32>
  // CHECK-NEXT:  %[[IN2_SHARDED:.*]] = mesh.shard %[[IN2]] to %[[SIN2_SHARDED]] annotate_for_users  : tensor<3x2xf32>
  // CHECK-NEXT:  %[[OUT_DPS_SHARDED:.*]] = mesh.shard %[[OUT_DPS]] to %[[SIN2_SHARDED]] annotate_for_users  : tensor<2x2xf32>
  %sarg0_sharded = mesh.sharding @mesh_2 split_axes = [[0]] : !mesh.sharding
  %arg0_sharded = mesh.shard %arg0 to %sarg0_sharded  : tensor<2x3xf32>
  // CHECK: %[[MATMUL:.*]] = linalg.matmul ins(%[[IN1_SHARDED2]], %[[IN2_SHARDED]] : tensor<2x3xf32>, tensor<3x2xf32>)
  // CHECK-SAME: outs(%[[OUT_DPS_SHARDED]] : tensor<2x2xf32>) -> tensor<2x2xf32>
  %res = linalg.matmul ins(%arg0_sharded, %arg1 : tensor<2x3xf32>, tensor<3x2xf32>)
    outs(%out_dps : tensor<2x2xf32>) -> tensor<2x2xf32>
  // CHECK-NEXT: %[[RES:.*]] = mesh.shard %[[MATMUL]] to %[[SIN2_SHARDED]] : tensor<2x2xf32>
  %sres_sharded = mesh.sharding @mesh_2 split_axes = [[]] : !mesh.sharding
  %res_sharded = mesh.shard %res to %sres_sharded  : tensor<2x2xf32>
  // CHECK: return %[[RES]] : tensor<2x2xf32>
  return %res_sharded : tensor<2x2xf32>
}

// https://arxiv.org/abs/2211.05102 Figure 2(a)
// The sharding propagation results in unnecessary reshards,
//   an optimization pass should be able to remove them.
// CHECK-LABEL: func.func @mlp_1d_weight_stationary
// CHECK-SAME:     [[varg0:%.*]]: tensor<2x4x8xf32>, [[varg1:%.*]]: tensor<2x8x32xf32>, [[varg2:%.*]]: tensor<2x32x8xf32>, [[varg3:%.*]]: tensor<1xf32>
func.func @mlp_1d_weight_stationary(%arg0: tensor<2x4x8xf32>, %arg1: tensor<2x8x32xf32>, %arg2: tensor<2x32x8xf32>, %arg3: tensor<1xf32>) -> tensor<2x4x8xf32> {
  %s0 = mesh.sharding @mesh_1d split_axes = [[], [], [0, 1, 2]] : !mesh.sharding
  %sharded0 = mesh.shard %arg0 to %s0 : tensor<2x4x8xf32>
  %sharded1 = mesh.shard %arg1 to %s0 : tensor<2x8x32xf32>
  // CHECK: [[vsharding:%.*]] = mesh.sharding @mesh_1d split_axes = {{\[\[}}], [], [0, 1, 2]] : !mesh.sharding
  // CHECK: [[vsharded:%.*]] = mesh.shard [[varg0]] to [[vsharding]] : tensor<2x4x8xf32>
  // CHECK: [[vsharded_0:%.*]] = mesh.shard [[varg1]] to [[vsharding]] : tensor<2x8x32xf32>
  // CHECK: [[vsharded_1:%.*]] = mesh.shard [[vsharded]] to [[vsharding]] annotate_for_users : tensor<2x4x8xf32>
  // CHECK: [[vsharding_2:%.*]] = mesh.sharding @mesh_1d split_axes = {{\[\[}}], [0, 1, 2]] : !mesh.sharding
  // CHECK: [[vsharded_3:%.*]] = mesh.shard [[vsharded_0]] to [[vsharding_2]] annotate_for_users : tensor<2x8x32xf32>
  // CHECK: [[vsharding_4:%.*]] = mesh.sharding @mesh_1d split_axes = {{\[\[}}]] : !mesh.sharding
  // CHECK: [[vsharded_5:%.*]] = mesh.shard [[varg3]] to [[vsharding_4]] annotate_for_users : tensor<1xf32>
  // CHECK: [[v0:%.*]] = tosa.matmul
  %1 = tosa.matmul %sharded0, %sharded1, %arg3, %arg3 : (tensor<2x4x8xf32>, tensor<2x8x32xf32>, tensor<1xf32>, tensor<1xf32>)  -> tensor<2x4x32xf32>
  // CHECK: [[vsharded_6:%.*]] = mesh.shard [[v0]] to [[vsharding_4]] : tensor<2x4x32xf32>
  // CHECK: [[vsharded_7:%.*]] = mesh.shard [[vsharded_6]] to [[vsharding_4]] annotate_for_users : tensor<2x4x32xf32>
  // CHECK: [[v1:%.*]] = tosa.sigmoid [[vsharded_7]] : (tensor<2x4x32xf32>) -> tensor<2x4x32xf32>
  // CHECK: [[vsharded_8:%.*]] = mesh.shard [[v1]] to [[vsharding_4]] : tensor<2x4x32xf32>
  %2 = tosa.sigmoid %1 : (tensor<2x4x32xf32>) -> tensor<2x4x32xf32>
  %sharding = mesh.sharding @mesh_1d split_axes = [[], [0, 1, 2]] : !mesh.sharding
  // CHECK: [[vsharded_9:%.*]] = mesh.shard [[varg2]] to [[vsharding_2]] : tensor<2x32x8xf32>
  %sharded2 = mesh.shard %arg2 to %sharding  : tensor<2x32x8xf32>
  // CHECK: [[vsharded_10:%.*]] = mesh.shard [[vsharded_8]] to [[vsharding_4]] annotate_for_users : tensor<2x4x32xf32>
  // CHECK: [[vsharded_11:%.*]] = mesh.shard [[vsharded_9]] to [[vsharding]] annotate_for_users : tensor<2x32x8xf32>
  // CHECK: [[v2:%.*]] = tosa.matmul
  %3 = tosa.matmul %2, %sharded2, %arg3, %arg3 : (tensor<2x4x32xf32>, tensor<2x32x8xf32>, tensor<1xf32>, tensor<1xf32>)  -> tensor<2x4x8xf32>
  // CHECK: [[vsharded_12:%.*]] = mesh.shard [[v2]] to [[vsharding]] : tensor<2x4x8xf32>
  %s4 = mesh.sharding @mesh_1d split_axes = [[], [], [0, 1, 2]] : !mesh.sharding
  %4 = mesh.shard %3 to %s4  : tensor<2x4x8xf32>
  // CHECK: return [[vsharded_12]]
  return %4 : tensor<2x4x8xf32>
}

// https://arxiv.org/abs/2211.05102 Figure 2(b)
// The sharding propagation results in unnecessary reshards,
//   an optimization pass should be able to remove them.
// CHECK-LABEL: func.func @mlp_2d_weight_stationary
// CHECK-SAME:     [[varg0:%.*]]: tensor<2x4x8xf32>, [[varg1:%.*]]: tensor<2x8x32xf32>, [[varg2:%.*]]: tensor<2x32x8xf32>, [[varg3:%.*]]: tensor<1xf32>
func.func @mlp_2d_weight_stationary(%arg0: tensor<2x4x8xf32>, %arg1: tensor<2x8x32xf32>, %arg2: tensor<2x32x8xf32>, %arg3: tensor<1xf32>) -> tensor<2x4x8xf32> {
    // CHECK: [[vsharding:%.*]] = mesh.sharding @mesh_3d split_axes = {{\[\[}}], [], [0, 1, 2]] : !mesh.sharding
  %s0 = mesh.sharding @mesh_3d split_axes = [[], [], [0, 1, 2]] : !mesh.sharding
    // CHECK: [[vsharded:%.*]] = mesh.shard [[varg0]] to [[vsharding]] : tensor<2x4x8xf32>
  %arg0_s = mesh.shard %arg0 to %s0  : tensor<2x4x8xf32>
    // CHECK: [[vsharding_0:%.*]] = mesh.sharding @mesh_3d split_axes = {{\[\[}}], [0], [1, 2]] : !mesh.sharding
  %s1 = mesh.sharding @mesh_3d split_axes = [[], [0], [1, 2]] : !mesh.sharding
    // CHECK: [[vsharded_1:%.*]] = mesh.shard [[varg1]] to [[vsharding_0]] : tensor<2x8x32xf32>
  %arg1_s = mesh.shard %arg1 to %s1  : tensor<2x8x32xf32>
    // CHECK: [[vsharding_2:%.*]] = mesh.sharding @mesh_3d split_axes = {{\[\[}}]] : !mesh.sharding
    // CHECK: [[vsharded_3:%.*]] = mesh.shard [[vsharded]] to [[vsharding_2]] annotate_for_users : tensor<2x4x8xf32>
    // CHECK: [[vsharded_4:%.*]] = mesh.shard [[vsharded_1]] to [[vsharding]] annotate_for_users : tensor<2x8x32xf32>
    // CHECK: [[vsharded_5:%.*]] = mesh.shard [[varg3]] to [[vsharding_2]] annotate_for_users : tensor<1xf32>
    // CHECK: [[v0:%.*]] = tosa.matmul
  %1 = tosa.matmul %arg0_s, %arg1_s, %arg3, %arg3 : (tensor<2x4x8xf32>, tensor<2x8x32xf32>, tensor<1xf32>, tensor<1xf32>)  -> tensor<2x4x32xf32>
    // CHECK: [[vsharded_6:%.*]] = mesh.shard [[v0]] to [[vsharding]] : tensor<2x4x32xf32>
  %2 = mesh.shard %1 to %s0  : tensor<2x4x32xf32>
    // CHECK: [[vsharded_7:%.*]] = mesh.shard [[vsharded_6]] to [[vsharding]] annotate_for_users : tensor<2x4x32xf32>
    // CHECK: [[v1:%.*]] = tosa.sigmoid 
    // CHECK: [[vsharded_8:%.*]] = mesh.shard [[v1]] to [[vsharding]] : tensor<2x4x32xf32>
  %3 = tosa.sigmoid %2 : (tensor<2x4x32xf32>) -> tensor<2x4x32xf32>
    // CHECK: [[vsharding_9:%.*]] = mesh.sharding @mesh_3d split_axes = {{\[\[}}], [1, 2], [0]] : !mesh.sharding
  %s2 = mesh.sharding @mesh_3d split_axes = [[], [1, 2], [0]] : !mesh.sharding
    // CHECK: [[vsharded_10:%.*]] = mesh.shard [[varg2]] to [[vsharding_9]] : tensor<2x32x8xf32>
  %arg2_s = mesh.shard %arg2 to %s2  : tensor<2x32x8xf32>
    // CHECK: [[vsharded_11:%.*]] = mesh.shard [[vsharded_8]] to [[vsharding_2]] annotate_for_users : tensor<2x4x32xf32>
    // CHECK: [[vsharded_12:%.*]] = mesh.shard [[vsharded_10]] to [[vsharding]] annotate_for_users : tensor<2x32x8xf32>
    // CHECK: [[v2:%.*]] = tosa.matmul
  %4 = tosa.matmul %3, %arg2_s, %arg3, %arg3 : (tensor<2x4x32xf32>, tensor<2x32x8xf32>, tensor<1xf32>, tensor<1xf32>)  -> tensor<2x4x8xf32>
    // CHECK: [[vsharded_13:%.*]] = mesh.shard [[v2]] to [[vsharding]] : tensor<2x4x8xf32>
  %5 = mesh.shard %4 to %s0  : tensor<2x4x8xf32>
    // CHECK: [[vsharded_14:%.*]] = mesh.shard [[vsharded_13]] to [[vsharding]] annotate_for_users : tensor<2x4x8xf32>
  %6 = mesh.shard %5 to %s0 annotate_for_users  : tensor<2x4x8xf32>
    // CHECK: return [[vsharded_14]]
  return %6 : tensor<2x4x8xf32>
}

// CHECK-LABEL: func.func @elementwise_duplicated_chain
// CHECK-SAME:    %[[ARG:.*]]: tensor<8x16xf32>
func.func @elementwise_duplicated_chain(%arg0: tensor<8x16xf32>) -> tensor<8x16xf32> {
  // CHECK-NEXT:  %[[S0:.*]] = mesh.sharding @mesh_2d split_axes = {{\[\[}}]] : !mesh.sharding
  // CHECK-NEXT:  %[[V0:.*]] = mesh.shard %[[ARG]] to %[[S0]] annotate_for_users  : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V1:.*]] = tosa.sigmoid %[[V0]]
  %0 = tosa.sigmoid %arg0 : (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT:  %[[V2:.*]] = mesh.shard %[[V1]] to %[[S0]] : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V3:.*]] = mesh.shard %[[V2]] to %[[S0]] annotate_for_users : tensor<8x16xf32>
  // CHECK-NEXT:  %[[V4:.*]] = tosa.sigmoid %[[V3]]
  %1 = tosa.sigmoid %0 : (tensor<8x16xf32>) -> tensor<8x16xf32>
  // CHECK-NEXT:  %[[V5:.*]] = mesh.shard %[[V4]] to %[[S0]]  : tensor<8x16xf32>
  %s0 = mesh.sharding @mesh_2d split_axes = [[]] : !mesh.sharding
  %2 = mesh.shard %1 to %s0 : tensor<8x16xf32>
  // CHECK-NEXT:  return %[[V5]]
  return %2 : tensor<8x16xf32>
}
