#ifndef PHYSICS_INCLUDED
#define PHYSICS_INCLUDED
#include <btBulletDynamicsCommon.h>

extern "C" {

void physics_init( void (*line_callback)(float*) );
void physics_debug_draw( void );
void physics_cleanup( void );

void physics_gravity( float x, float y, float z );

void physics_remove_body( btRigidBody* body );

btRigidBody* physics_create_static_bvh_tri_mesh(
		int     numTriangles,
		int   * triangleIndexBase,
		int  	  triangleIndexStride,
		int  	  numVertices,
		float *	vertexBase,
		int  	  vertexStride	 
);

btRigidBody* physics_create_sphere(
  float mass,
  float radius,
	float lin_drag, float ang_drag,
  float vx, float vy, float vz, // position
  float qx, float qy, float qz, float qw // orientation
);

btRigidBody* physics_create_plane(
  float mass,
  float constant,
  float nx, float ny, float nz, // normal
  float vx, float vy, float vz,
  float qx, float qy, float qz, float qw
);

void physics_body_transform(
  btRigidBody * b,
  float vec[3],
	float quat[4]
);

void physics_body_apply_torque(
	btRigidBody * b,
	float x, float y, float z
);

void physics_body_apply_relative_torque(
	btRigidBody * b,
	float x, float y, float z
);

void physics_body_apply_central_force(
	btRigidBody * b,
	float x, float y, float z
);

void physics_body_apply_relative_central_force(
	btRigidBody * b,
	float x, float y, float z
);

// step simulation world
// sub steps is calculated for you
// where steps = time / step
void physics_step( float step );

} 
#endif
